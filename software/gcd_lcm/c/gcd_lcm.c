// Implementation of GCD, LCM 
// Copyright (c) 2025 Arvid Juskaitis

#ifdef __LINUX__
#define __fastcall__ /**/
#endif
#include "extlib.h"

#define NUM_MIN 1
#define NUM_MAX 100
#define PRINT_VALUES 0
#define PRINT_VALUES_HEX 1

// Function to compute GCD using Euclidean Algorithm (Iterative)
int gcd(int a, int b) {
    while (b != 0) {
        int temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

int main() {
    int a, b, _gcd, _lcm, count = 0;

    for (a = NUM_MIN; a <= NUM_MAX; a++) {
        for (b = a + 1; b <= NUM_MAX; b++) {  // Avoid duplicate pairs (b > a)
            _gcd = gcd(a, b);
            if (_gcd > 1) {  // Check if they have a common divisor
                count ++;
                _lcm = a / _gcd * b;
#if PRINT_VALUES
                print_int(a);
                print_str(", ");
                print_int(b);
                print_str(" - gcd: ");
                print_int(_gcd);
                print_str(", lcm: ");
                print_int(_lcm);
                print_char('\n');
#endif
#if PRINT_VALUES_HEX
                print_hex(a);
                print_hex(b);
                print_char('>');
                print_hex(_gcd);
                print_char(',');
                print_hex((_lcm >> 8) & 0xff);
                print_hex(_lcm & 0xff);
                print_char(' ');
#endif
            }
        }
    }
    print_char('$');
    print_hex((count >> 8) & 0xff);
    print_hex(count & 0xff);
    print_char(',');
    print_int(count);
    print_char('\n');

    return 0;
}
