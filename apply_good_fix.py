#!/usr/bin/env python
"""Writes a GOOD fix for is_palindrome into the target calculator.py."""
import sys

GOOD_CODE = '''def add(a, b):
    return a + b

def is_palindrome(s):
    cleaned = ''.join(ch.lower() for ch in s if ch.isalnum())
    return cleaned == cleaned[::-1]

def factorial(n):
    if n == 0:
        return 1
    return n * factorial(n - 1)
'''

target = sys.argv[1]
with open(target, "w") as f:
    f.write(GOOD_CODE)
print(f"[apply_good_fix] Wrote good fix to {target}")
