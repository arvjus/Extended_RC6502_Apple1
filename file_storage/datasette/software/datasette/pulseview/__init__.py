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

'''
C64 Datasette decoder.

Decodes the Commodore 64 Datasette tape format which uses three pulse
lengths (S/M/L) to encode data. The protocol uses:
- L/M marker to indicate start of byte
- S/M pair = 0 bit
- M/S pair = 1 bit
- LSB first bit order
- 8 data bits per byte
- L/S marker indicates end of data

Details:
- Short pulse (S): ~390 µs
- Medium pulse (M): ~540 µs
- Long pulse (L): ~700 µs
'''

from .pd import Decoder
