"""
Prism Python sample.

Exercises:
- single, double, triple-quoted strings
- raw / byte / f-string prefixes
- numeric literals: int, float, hex, oct, bin, complex
- decorators
- class / def colorization
- async / await keywords
"""

from __future__ import annotations

import asyncio
import math
from dataclasses import dataclass
from typing import Iterable, Optional


# Numeric showcase
PI: float = 3.14159265358979
HEX_MASK: int = 0xDEAD_BEEF
OCTAL_PERMS: int = 0o755
BINARY_FLAG: int = 0b1010_1010
COMPLEX_NUMBER: complex = 3 + 4j


def fizzbuzz(n: int) -> Iterable[str]:
    r"""Classic fizzbuzz with a raw-string regex tribute: r"\d+"."""
    for i in range(1, n + 1):
        if i % 15 == 0:
            yield "FizzBuzz"
        elif i % 3 == 0:
            yield "Fizz"
        elif i % 5 == 0:
            yield "Buzz"
        else:
            yield str(i)


@dataclass(frozen=True)
class Point:
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        return math.hypot(self.x - other.x, self.y - other.y)


class Greeter:
    """A trivial class to demonstrate `class` highlighting."""

    DEFAULT_GREETING: str = "Merhaba"

    def __init__(self, name: str, greeting: Optional[str] = None) -> None:
        self.name = name
        self.greeting = greeting or self.DEFAULT_GREETING

    def __call__(self) -> str:
        # f-string interpolation: keep the prefix highlighted.
        return f"{self.greeting}, {self.name}!"


async def fetch_squares(values: list[int]) -> list[int]:
    """Pretend to fetch squares asynchronously."""
    await asyncio.sleep(0)
    return [v ** 2 for v in values]


def main() -> None:
    bytes_literal = b"raw\xdebytes"
    rb_string = rb"verbatim\nbytes"  # noqa: F841
    print(f"hex={HEX_MASK:#x}, oct={OCTAL_PERMS:#o}, bin={BINARY_FLAG:#b}")
    print(", ".join(fizzbuzz(15)))

    g = Greeter("World")
    print(g())

    squares = asyncio.run(fetch_squares([1, 2, 3, 4]))
    assert squares == [1, 4, 9, 16], "math is broken"


if __name__ == "__main__":
    main()
