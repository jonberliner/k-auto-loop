"""The ONE file the agent may edit in this example. Make `solve` faster."""


def solve(n: int) -> int:
    # Deliberately slow: count primes below n with trial division.
    count = 0
    for k in range(2, n):
        is_prime = True
        for d in range(2, k):
            if k % d == 0:
                is_prime = False
                break
        if is_prime:
            count += 1
    return count
