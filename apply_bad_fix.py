#!/usr/bin/env python
"""Writes a deliberately BAD (incomplete) fix into the target calculator.py."""
import sys

BAD_CODE = '''def add(a, b):
    return a + b

def is_palindrome(s):
    # BAD FIX: only lowercases, forgets to strip spaces/punctuation
    s = s.lower()
    return s == s[::-1]

def factorial(n):
    if n == 0:
        return 1
    return n * factorial(n - 1)
'''

target = sys.argv[1]
with open(target, "w") as f:
    f.write(BAD_CODE)
print(f"[apply_bad_fix] Wrote deliberately incomplete fix to {target}")
