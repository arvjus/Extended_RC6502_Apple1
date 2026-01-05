// C64 Datasette decoder: 3 pulse lengths (S/M/L), L/M marker,
// bits: S/M = 0, M/S = 1, then inverted odd parity.
// Arduino Nano / ATmega328P @16 MHz, uses Timer1 Input Capture on D8.

#include <Arduino.h>

// ============================================================================
// DEFINES AND TYPES
// ============================================================================

// --- Pin Definitions ---
#define ICP_PIN 8
#define OUT_PIN 9
#define LED_PIN 13

// --- Pulse Types ---
enum PulseType { P_S = 0, P_M = 1, P_L = 2, P_BAD = 3 };

// --- Command State ---
enum CommandState : uint8_t {
  CMD_IDLE,
  CMD_READ,
  CMD_WRITE,
  CMD_GET_HEX_LENGTH
};

// --- RX State Machine ---
enum State : uint8_t {
  RX_WAIT_MARK_FIRST,
  RX_WAIT_MARK_SECOND,
  RX_WAIT_MARK_THIRD,
  RX_READ_BITS_PAIR_FIRST,   // expecting first of pair (S or M)
  RX_READ_BITS_PAIR_SECOND   // expecting second of pair (S or M) -> yields bit
};

// --- Ring Buffer for Pulse Queue ---
#define PULSE_BUFFER_SIZE 512
#define XON  0x11
#define XOFF 0x13
#define XOFF_THRESHOLD (PULSE_BUFFER_SIZE - 150)
#define XON_THRESHOLD  50
#define PULSE_END 0xff  // fake pulse to reset the state

struct PulseBuffer {
  uint16_t data[PULSE_BUFFER_SIZE];
  volatile uint16_t head;
  volatile uint16_t tail;
  volatile bool xoff_sent;
};

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

// --- Command State ---
CommandState cmd_state = CMD_IDLE;
uint16_t hex_length = 0;
uint16_t hex_digits_read = 0;
bool timer_in_tx_mode = false;
bool fill_the_gaps = false;

// --- Pulse Buffer ---
PulseBuffer pulse_buffer = {0};

// --- Pulse Timing Constants ---
const uint16_t S_US = 390;
const uint16_t M_US = 540;
const uint16_t L_US = 700;
const uint16_t SM_BOUND = (S_US + M_US) / 2;  // ~432 µs
const uint16_t ML_BOUND = (M_US + L_US) / 2;  // ~592 µs

// --- RX Variables ---
volatile uint16_t rx_last_icr = 0;
volatile uint16_t rx_last_ticks = 0;
volatile bool rx_have_pulse = false;
State rx_state = RX_WAIT_MARK_FIRST;
uint8_t rx_bit_index = 0;
uint8_t rx_data_byte = 0;
PulseType rx_first_of_pair = P_BAD;

// --- TX Variables ---
uint16_t write_remaining = 0;
volatile bool tx_pulse_in_progress = false;
volatile bool tx_pulse_high_phase = false;
volatile uint16_t tx_pulse_duration = 0;

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

static inline PulseType classify_us(uint16_t us) {
  if (us < SM_BOUND) return P_S;
  if (us < ML_BOUND) return P_M;
  return P_L;
}

static inline uint16_t ticks_to_us(uint16_t t) {
  return (t + 8) >> 4;  // 16 MHz: 16 ticks ≈ 1 µs
}

static inline void led(bool on) { 
  digitalWrite(LED_PIN, on ? HIGH : LOW); 
}

// --- Ring Buffer Functions ---
static inline void pulse_buffer_init() {
  pulse_buffer.head = 0;
  pulse_buffer.tail = 0;
  pulse_buffer.xoff_sent = false;
}

static inline uint16_t pulse_buffer_count() {
  return (pulse_buffer.head - pulse_buffer.tail) & (PULSE_BUFFER_SIZE - 1);
}

static inline uint16_t pulse_buffer_free() {
  return PULSE_BUFFER_SIZE - 1 - pulse_buffer_count();
}

static inline bool pulse_buffer_is_empty() {
  return pulse_buffer.head == pulse_buffer.tail;
}

static inline bool pulse_buffer_push(uint16_t us) {
  uint16_t next_head = (pulse_buffer.head + 1) & (PULSE_BUFFER_SIZE - 1);
  if (next_head == pulse_buffer.tail) {
    return false;
  }
  pulse_buffer.data[pulse_buffer.head] = us;
  pulse_buffer.head = next_head;
  return true;
}

static inline bool pulse_buffer_pop(uint16_t* us) {
  if (pulse_buffer_is_empty()) {
    return false;
  }
  *us = pulse_buffer.data[pulse_buffer.tail];
  pulse_buffer.tail = (pulse_buffer.tail + 1) & (PULSE_BUFFER_SIZE - 1);
  return true;
}

static inline void check_flow_control() {
  uint16_t count = pulse_buffer_count();
  
  if (!pulse_buffer.xoff_sent && count >= XOFF_THRESHOLD) {
    Serial.write(XOFF);
    Serial.flush();
    pulse_buffer.xoff_sent = true;
  } else if (pulse_buffer.xoff_sent && count <= XON_THRESHOLD) {
    Serial.write(XON);
    pulse_buffer.xoff_sent = false;
  }
}

// ============================================================================
// RECEIVING (RX)
// ============================================================================

// --- RX ISR ---
ISR(TIMER1_CAPT_vect) {
  uint16_t now = ICR1;
  uint16_t diff = now - rx_last_icr;
  rx_last_icr = now;
  rx_last_ticks = diff;
  rx_have_pulse = true;
}

// --- RX Functions ---
static inline void rx_setup_timer() {
  TCCR1A = 0; // Normal mode
  TCCR1B = 0; // Stop timer while reconfiguring
  // Capture on FALLING edge, no prescaler, noise canceller ON
  TCCR1B = _BV(ICNC1) | _BV(CS10);      // ICES1=0 => falling edge
  TIMSK1 = _BV(ICIE1);  // Enable input capture interrupt, disable compare match
  TIFR1 = _BV(ICF1);  // Clear pending flags
  timer_in_tx_mode = false;
}

static inline void rx_reset_to_marker() {
  rx_state = RX_WAIT_MARK_FIRST;
  rx_bit_index = 0;
  rx_data_byte = 0;
  rx_first_of_pair = P_BAD;
}

void rx_process_pulse(PulseType p) {
  if (cmd_state != CMD_READ) return;

  switch (rx_state) {
  case RX_WAIT_MARK_FIRST:
    if (p == P_L) rx_state = RX_WAIT_MARK_SECOND;
    break;

  case RX_WAIT_MARK_SECOND:
    if (p == P_M) {
      rx_bit_index = 0;
      rx_data_byte = 0;
      rx_state = RX_READ_BITS_PAIR_FIRST;
    } else if (p == P_L) {
      rx_state = RX_WAIT_MARK_THIRD;
    } else {
      rx_reset_to_marker();
    }
    break;

  case RX_WAIT_MARK_THIRD:
    if (p == P_L) {         // end of file
      led(false);
      cmd_state = CMD_IDLE;
    }
    rx_reset_to_marker();    
    break;

  case RX_READ_BITS_PAIR_FIRST:
    if (p == P_S || p == P_M) {
      rx_first_of_pair = p;
      rx_state = RX_READ_BITS_PAIR_SECOND;
    } else {
      rx_reset_to_marker();
    }   
    break;

  case RX_READ_BITS_PAIR_SECOND: {
    uint8_t bit;
    if ((rx_first_of_pair == P_S && p == P_M) || (rx_first_of_pair == P_M && p == P_S)) {
      bit = (rx_first_of_pair == P_M) ? 1 : 0;
    } else {
      bit = 0;  // default to 0 on invalid pair
    }
    if (bit) rx_data_byte |= (1u << rx_bit_index);
    rx_bit_index++;

    if (rx_bit_index < 8) {
      rx_state = RX_READ_BITS_PAIR_FIRST;
    } else {
      Serial.write(rx_data_byte);
      Serial.flush();
      rx_reset_to_marker();
    }
  } break;
  }
}

// ============================================================================
// TRANSMITTING (TX)
// ============================================================================

// Timer1 Compare Match A ISR - handles pulse generation
ISR(TIMER1_COMPA_vect)
{
  if (tx_pulse_high_phase) {
    // HIGH phase ends → go LOW
    PORTB &= ~_BV(PORTB1);
    OCR1A = OCR1A + (tx_pulse_duration >> 1);
    tx_pulse_high_phase = false;
  } else {
    // LOW phase just ended → pulse is finished.
    // Immediately start next pulse if one exists.
    uint16_t us;

    if (pulse_buffer_pop(&us)) {
      if (us == PULSE_END) {
        fill_the_gaps = false;
        timer_in_tx_mode = false;
        led(false);
        TCCR1B = 0;                    // stop timer
        return;
      }

      // Start next pulse
      tx_pulse_duration = (us << 4);
      tx_pulse_high_phase = true;
      PORTB |= _BV(PORTB1);
      OCR1A = OCR1A + (tx_pulse_duration >> 1);
      tx_pulse_in_progress = true;
      return;
    }

    // No queued pulse
    if (fill_the_gaps) {
      // Emit a "gap filler" short pulse
      us = S_US;
      tx_pulse_duration = (us << 4);
      tx_pulse_high_phase = true;
      PORTB |= _BV(PORTB1);
      OCR1A = OCR1A + (tx_pulse_duration >> 1);
      tx_pulse_in_progress = true;
      return;
    }

    // Nothing more to send
    tx_pulse_in_progress = false;
  }
}

static inline void tx_setup_timer() {
  if (timer_in_tx_mode) return;
  
  TCCR1A = 0;
  TCCR1B = _BV(CS10);  // normal mode, no prescaler
  TIMSK1 = _BV(OCIE1A);  // enable compare match A interrupt
  PORTB &= ~_BV(PORTB1);
  tx_pulse_in_progress = false;
  
  timer_in_tx_mode = true;
  fill_the_gaps = false;

  // Kick off first gap-filler pulse so ISR takes over
  send_pulse_us(S_US);
}

static inline void send_pulse_us(uint16_t us) {
  // This is now only called for gap-filler case.
  // Normally COMPA ISR will start pulses.
  tx_pulse_duration = (us << 4);
  tx_pulse_high_phase = true;
  tx_pulse_in_progress = true;
  PORTB |= _BV(PORTB1);
  OCR1A = TCNT1 + (tx_pulse_duration >> 1);
}

static inline bool queue_pulse(uint16_t us) {
  bool result = pulse_buffer_push(us);
  check_flow_control();
  return result;
}

// Queue a byte: L/M start marker, 8 bits (LSB first), requires 18 pulses
static inline void queue_byte(uint8_t b) {
  queue_pulse(L_US);      // start marker
  queue_pulse(M_US);
  for (uint8_t i = 0; i < 8; i++) {
    if ((b >> i) & 1) {
      queue_pulse(M_US);  // 1
      queue_pulse(S_US);
    } else {
      queue_pulse(S_US);  // 0
      queue_pulse(M_US);
    }
  }
}

#define SERIAL_FIFO_SIZE 64
uint8_t serial_fifo[SERIAL_FIFO_SIZE];
volatile uint8_t serial_fifo_head = 0;
volatile uint8_t serial_fifo_tail = 0;

bool serial_fifo_push(uint8_t b) {
  uint8_t next = (serial_fifo_head + 1) & (SERIAL_FIFO_SIZE - 1);
  if (next == serial_fifo_tail) return false;             // full
  serial_fifo[serial_fifo_head] = b;
  serial_fifo_head = next;
  return true;
}

bool serial_fifo_pop(uint8_t* b) {
  if (serial_fifo_head == serial_fifo_tail) return false; // empty
  *b = serial_fifo[serial_fifo_tail];
  serial_fifo_tail = (serial_fifo_tail + 1) & (SERIAL_FIFO_SIZE - 1);
  return true;
}

uint8_t serial_fifo_count() {
  return (serial_fifo_head - serial_fifo_tail) & (SERIAL_FIFO_SIZE - 1);
}

void serial_poll() {
  while (Serial.available()) {
    serial_fifo_push(Serial.read());
  }
}

// ============================================================================
// COMMAND PROCESSING
// ============================================================================

void process_command(char c) {
  if (c == 'x') {
    cmd_state = CMD_IDLE;
    fill_the_gaps = false;
    led(false);
    return;
  } 

  // CMD_GET_HEX_LENGTH
  if (cmd_state == CMD_GET_HEX_LENGTH) {
    if (c >= '0' && c <= '9') {
      hex_length = (hex_length << 4) | (c - '0');
    } else if (c >= 'A' && c <= 'F') {
      hex_length = (hex_length << 4) | (c - 'A' + 10);
    } else if (c >= 'a' && c <= 'f') {
      hex_length = (hex_length << 4) | (c - 'a' + 10);
    } else {
      // invalid char, abort
      cmd_state = CMD_IDLE;
      return;
    }
    hex_digits_read++;
    if (hex_digits_read >= 4) {
      write_remaining = hex_length;
      cmd_state = CMD_WRITE;
    }
    return;
  }  
  
  // Commands start in idle
  if (cmd_state != CMD_IDLE) {
    return;
  }

  switch (c) {
  case 'r':  // read file
    led(true);
    rx_setup_timer();
    rx_reset_to_marker();
    cmd_state = CMD_READ;
    break;

  case 's':  // sync sequence
    led(true);
    tx_setup_timer();
    for (uint16_t i = 0; i < 5; i++) queue_pulse(S_US); // 5 short pulses
    fill_the_gaps = true;
    break;

  case 'w':  // write with hex length
    led(true);
    tx_setup_timer();
    hex_length = 0;
    hex_digits_read = 0;
    cmd_state = CMD_GET_HEX_LENGTH;
    break;

  case 'e':  // end file
    tx_setup_timer();
    queue_pulse(L_US);    // L/L/L end marker, requires 3 pulses
    queue_pulse(L_US);
    queue_pulse(L_US);
    queue_pulse(S_US);    // final short pulse to rise edge
    queue_pulse(PULSE_END);
    fill_the_gaps = false;
    break;
  }
}

// ============================================================================
// SETUP AND MAIN LOOP
// ============================================================================

void setup() {
  Serial.begin(28800);

  pinMode(ICP_PIN, INPUT);
  pinMode(OUT_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(OUT_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  pulse_buffer_init();
}

void loop() {
  uint8_t b;

  serial_poll();  // fetch all available bytes to FIFO

  // Handle incoming serial commands, s requires at least 5 free pulses in buffer, while e requires 3
  while (cmd_state != CMD_WRITE && pulse_buffer_free() >= 5) {
    if (!serial_fifo_pop(&b)) break;  // stop if no bytes in FIFO
    process_command(b);
    check_flow_control();
  }
  
  if (cmd_state == CMD_WRITE) {
    while (write_remaining > 0 && pulse_buffer_free() >= 18) {
    if (!serial_fifo_pop(&b)) break;  // stop if no bytes in FIFO
      write_remaining--;
      queue_byte(b);
      check_flow_control();
    }

    if (write_remaining == 0) {
      cmd_state = CMD_IDLE;
      fill_the_gaps = true;
    }
  }

  // CMD_READ
  if (cmd_state == CMD_READ && rx_have_pulse) {
    uint16_t ticks;
    cli();
    ticks = rx_last_ticks;
    rx_have_pulse = false;
    sei();

    uint16_t us = ticks_to_us(ticks);

    // Quick plausibility: ignore very short/very long glitches
    if (us < 130 || us > 1200) {
      // glitch -> drop and try to recover by waiting for next L/M
      rx_reset_to_marker();
      return;
    }

    PulseType p = classify_us(us);
    rx_process_pulse(p);
  }
}
