Implement/test GCD, LCM functions in different environments

For given a=1, b=100

Great Common Divisor
while b != 0:
    tmp = b
    b = a % b
    a = tmp
return a


Least Common Multiply
lcm = a / gcd(a, b) * b


Benchmark - no value output

Basic   - 300 sec
C       - 20 sec
ASM     - 20 sec

C/linux on 2015's PC - 4ms


