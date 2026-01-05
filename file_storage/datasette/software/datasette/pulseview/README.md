# Datasette Protocol Decoder for PulseView

This is a protocol decoder for the Commodore 64 Datasette tape format, compatible with PulseView/sigrok.

## Features

- Decodes C64 Datasette pulse encoding (S/M/L pulses)
- Identifies byte markers (L/M sequence)
- Decodes data bits (S/M = 0, M/S = 1)
- Shows complete bytes with hex and ASCII representation
- Error detection and glitch filtering
- Configurable pulse thresholds

## Installation

### Linux

1. Copy the decoder files to the sigrok protocol decoder directory:

```bash
# Find your decoders directory (usually one of these):
# ~/.local/share/libsigrokdecode/decoders/
# /usr/share/libsigrokdecode/decoders/
# /usr/local/share/libsigrokdecode/decoders/

# Create the decoder directory
mkdir -p ~/.local/share/libsigrokdecode/decoders/datasette

# Copy the decoder files
cp __init__.py pd.py ~/.local/share/libsigrokdecode/decoders/datasette/
```
2. Restart PulseView

## Usage

1. Open your capture in PulseView
2. Add a protocol decoder: **Add protocol decoder** → **Datasette**
3. Configure the input channel to your datasette data line
4. Adjust options if needed:
   - Short pulse: default 390 µs
   - Medium pulse: default 540 µs
   - Long pulse: default 700 µs
   - Min/Max valid pulse: glitch filtering thresholds

## Decoder Outputs

The decoder provides multiple annotation rows:

- **Pulses**: Individual pulse classification (S/M/L) with duration
- **Markers**: Byte start markers and EOF markers
- **Bits**: Individual decoded bits (0/1)
- **Bytes**: Complete bytes in hex and ASCII format
- **Errors**: Invalid sequences and glitches

## Protocol Details

The C64 Datasette uses frequency-shift encoding with three pulse lengths:

- **Short (S)**: ~390 µs
- **Medium (M)**: ~540 µs  
- **Long (L)**: ~700 µs

### Encoding Rules

- **Byte marker**: L followed by M
- **Bit 0**: S followed by M
- **Bit 1**: M followed by S
- **EOF marker**: L followed by S
- **Bit order**: LSB first
- **Bits per byte**: 8 data bits

### Example Signal

```
L-M | S-M | M-S | S-M | M-S | S-M | S-M | M-S | S-M | L-M | ...
 ^    ^     ^     ^     ^     ^     ^     ^     ^     ^
 |    |     |     |     |     |     |     |     |     |
Mark  0     1     0     1     0     0     1     0    Mark
      \___________________________/
            Byte: 0x4A (01001010)
                  LSB first
```

## Implementation

The decoder implements the same logic as the Arduino datasette receiver in `datasette.ino`, specifically the `rx_process_pulse()` function. It uses a state machine with four states:

1. **RX_WAIT_MARK_FIRST**: Waiting for L pulse (start of marker)
2. **RX_WAIT_MARK_SECOND**: Waiting for M pulse (complete marker)
3. **RX_READ_BITS_PAIR_FIRST**: Reading first pulse of bit pair
4. **RX_READ_BITS_PAIR_SECOND**: Reading second pulse to decode bit

## Troubleshooting

**No output from decoder:**
- Check that the correct channel is selected
- Verify signal polarity (try inverting if needed)
- Adjust min/max pulse thresholds if dealing with noisy signals

**Many errors:**
- Adjust pulse length parameters to match your tape speed
- Check signal quality and sampling rate
- Try increasing min_us threshold to filter glitches

**Recommended sampling rate:** At least 1 MHz (preferably 4 MHz or higher)

## License

GPLv2+
