##
## This file is part of the libsigrokdecode project.
##
## Copyright (C) 2025
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

import sigrokdecode as srd

# Pulse type constants
P_S = 0  # Short pulse
P_M = 1  # Medium pulse
P_L = 2  # Long pulse
P_BAD = 3  # Invalid pulse

# Decoder state constants
RX_WAIT_MARK_FIRST = 0
RX_WAIT_MARK_SECOND = 1
RX_WAIT_MARK_THIRD = 2
RX_READ_BITS_PAIR_FIRST = 3
RX_READ_BITS_PAIR_SECOND = 4


class Decoder(srd.Decoder):
    api_version = 3
    id = 'datasette'
    name = 'Datasette'
    longname = 'Commodore 64 Datasette'
    desc = 'Commodore 64 Datasette tape format decoder'
    license = 'gplv2+'
    inputs = ['logic']
    outputs = []
    tags = ['Retro computing']
    channels = (
        {'id': 'data', 'name': 'Data', 'desc': 'Datasette data line'},
    )
    options = (
        {'id': 's_us', 'desc': 'Short pulse (µs)', 'default': 390},
        {'id': 'm_us', 'desc': 'Medium pulse (µs)', 'default': 540},
        {'id': 'l_us', 'desc': 'Long pulse (µs)', 'default': 700},
        {'id': 'min_us', 'desc': 'Min valid pulse (µs)', 'default': 150},
        {'id': 'max_us', 'desc': 'Max valid pulse (µs)', 'default': 1200},
        {'id': 'polarity', 'desc': 'Signal polarity', 'default': 'read', 'values': ('read', 'write')},
    )
    annotations = (
        ('pulse-s', 'Short pulse'),
        ('pulse-m', 'Medium pulse'),
        ('pulse-l', 'Long pulse'),
        ('marker', 'Byte marker'),
        ('bit', 'Data bit'),
        ('byte', 'Data byte'),
        ('ascii', 'ASCII'),
        ('error', 'Error'),
    )
    annotation_rows = (
        ('pulses', 'Pulses', (0, 1, 2)),
        ('markers', 'Markers', (3,)),
        ('bits', 'Bits', (4,)),
        ('bytes', 'Bytes', (5,)),
        ('ascii', 'ASCII', (6,)),
        ('errors', 'Errors', (7,)),
    )

    def __init__(self):
        self.reset()

    def reset(self):
        self.samplerate = None
        self.last_edge = None
        
        # Decoder state
        self.state = RX_WAIT_MARK_FIRST
        self.bit_index = 0
        self.data_byte = 0
        self.first_of_pair = P_BAD
        
        # Tracking positions for annotations
        self.byte_start = None
        self.bit_start = None
        self.pulse_start = None

    def metadata(self, key, value):
        if key == srd.SRD_CONF_SAMPLERATE:
            self.samplerate = value

    def start(self):
        self.out_ann = self.register(srd.OUTPUT_ANN)
        
        # Calculate thresholds
        s_us = self.options['s_us']
        m_us = self.options['m_us']
        l_us = self.options['l_us']
        
        self.sm_bound = (s_us + m_us) / 2
        self.ml_bound = (m_us + l_us) / 2
        self.min_us = self.options['min_us']
        self.max_us = self.options['max_us']

    def classify_pulse(self, us):
        """Classify pulse width into S/M/L types"""
        if us < self.sm_bound:
            return P_S
        elif us < self.ml_bound:
            return P_M
        else:
            return P_L

    def reset_to_marker(self):
        """Reset decoder state to wait for marker"""
        self.state = RX_WAIT_MARK_FIRST
        self.bit_index = 0
        self.data_byte = 0
        self.first_of_pair = P_BAD
        self.byte_start = None
        self.bit_start = None

    def process_pulse(self, pulse_type, start, end):
        """Process a single pulse - same logic as rx_process_pulse"""
        
        if self.state == RX_WAIT_MARK_FIRST:
            if pulse_type == P_L:
                self.state = RX_WAIT_MARK_SECOND
                self.byte_start = start
            # else stay here
            
        elif self.state == RX_WAIT_MARK_SECOND:
            if pulse_type == P_M:
                # Marker L/M confirmed: start new byte
                self.put(self.byte_start, end, self.out_ann, [3, ['MARK', 'M']])
                self.bit_index = 0
                self.data_byte = 0
                self.byte_start = end
                self.state = RX_READ_BITS_PAIR_FIRST
            elif pulse_type == P_L:
                # Multiple L in a row, keep waiting for L
                self.state = RX_WAIT_MARK_THIRD
            else:
                # Not M next, restart
                self.put(self.byte_start, end, self.out_ann, [7, ['Bad marker', 'ERR']])
                self.reset_to_marker()

        elif self.state == RX_WAIT_MARK_THIRD:
            if pulse_type == P_L:
                # End of data marker (L/L/L)
                self.put(self.byte_start, end, self.out_ann, [3, ['EOF', 'E']])
                self.reset_to_marker()
            else:
                # Not L next, restart
                self.put(self.byte_start, end, self.out_ann, [7, ['Bad marker', 'ERR']])
                self.reset_to_marker()
                
        elif self.state == RX_READ_BITS_PAIR_FIRST:
            # Only S or M are valid for first of data-bit pair
            if pulse_type == P_S or pulse_type == P_M:
                self.first_of_pair = pulse_type
                self.bit_start = start
                self.state = RX_READ_BITS_PAIR_SECOND
            else:
                # Unexpected (L), resync
                self.put(start, end, self.out_ann, [7, ['Bad bit start', 'ERR']])
                self.reset_to_marker()
                
        elif self.state == RX_READ_BITS_PAIR_SECOND:
            # Expect complement: S/M=0 or M/S=1
            if ((self.first_of_pair == P_S and pulse_type == P_M) or
                (self.first_of_pair == P_M and pulse_type == P_S)):
                
                bit = 1 if self.first_of_pair == P_M else 0
                self.put(self.bit_start, end, self.out_ann, [4, [str(bit)]])
                
                if bit:
                    self.data_byte |= (1 << self.bit_index)  # LSB-first
                self.bit_index += 1
                
                if self.bit_index < 8:
                    self.state = RX_READ_BITS_PAIR_FIRST
                else:
                    # Complete byte
                    byte_str = '0x{:02X} ({:d})'.format(self.data_byte, self.data_byte)
                    self.put(self.byte_start, end, self.out_ann, [5, [byte_str, '{:02X}'.format(self.data_byte)]])
                    
                    # ASCII representation
                    if 32 <= self.data_byte <= 126:
                        ascii_char = chr(self.data_byte)
                    else:
                        ascii_char = '.'
                    self.put(self.byte_start, end, self.out_ann, [6, [ascii_char]])
                    
                    # After a byte, expect another L/M marker
                    self.reset_to_marker()
                    self.state = RX_WAIT_MARK_FIRST
            else:
                # Invalid pair, resync
                self.put(self.bit_start, end, self.out_ann, [7, ['Bad bit pair', 'ERR']])
                self.reset_to_marker()

    def decode(self):
        if not self.samplerate:
            raise SamplerateError('Cannot decode without samplerate.')
        
        # Determine edge polarity: 'write' = positive pulses (rising edge), 'read' = active low (falling edge)
        is_write = self.options['polarity'] == 'write'
        start_edge = 'r' if is_write else 'f'  # Rising edge for write, falling for read
        end_edge = 'f' if is_write else 'r'    # Falling edge for write, rising for read
        
        # Wait for first edge to start pulse measurement
        self.wait({0: start_edge})
        pulse_start = self.samplenum
        
        while True:
            # Wait for opposite edge (end of active period)
            self.wait({0: end_edge})
            
            # Wait for next start edge (end of inactive period = end of pulse)
            self.wait({0: start_edge})
            pulse_end = self.samplenum
            
            # Calculate full pulse width (high + low period) in microseconds
            pulse_samples = pulse_end - pulse_start
            pulse_us = (pulse_samples / self.samplerate) * 1e6
            
            # Validate pulse width
            if pulse_us < self.min_us or pulse_us > self.max_us:
                # Glitch - ignore and reset
                if pulse_us >= self.min_us:  # Only show error for long pulses
                    self.put(pulse_start, pulse_end, self.out_ann, 
                            [7, ['Glitch {:.0f}µs'.format(pulse_us), 'GLITCH']])
                self.reset_to_marker()
                pulse_start = pulse_end
                continue
            
            # Classify pulse
            pulse_type = self.classify_pulse(pulse_us)
            
            # Annotate pulse type
            pulse_labels = ['S', 'M', 'L', 'BAD']
            pulse_label = pulse_labels[pulse_type]
            self.put(pulse_start, pulse_end, self.out_ann,
                    [pulse_type, [pulse_label]])
            
            # Process the pulse
            self.process_pulse(pulse_type, pulse_start, pulse_end)
            
            pulse_start = pulse_end
