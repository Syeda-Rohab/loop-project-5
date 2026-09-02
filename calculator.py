def add(a, b):
    return a + b

def is_palindrome(s):
    # BUG: doesn't ignore spaces, case, or punctuation
    return s == s[::-1]

def factorial(n):
    if n == 0:
        return 1
    return n * factorial(n - 1)
