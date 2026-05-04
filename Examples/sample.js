// Prism JavaScript sample.
//
// Exercises:
// - line and /* block */ comments
// - single, double, and template-literal strings (with ${} interpolation)
// - numeric literals: int, float, hex, oct, bin, BigInt (123n), exponential
// - arrow functions, classes, async/await, generators
// - decorators (@experimental)
// - destructuring + spread/rest

import { readFile } from 'node:fs/promises';
import process     from 'node:process';

/* -------------------------------------------------------------------------
 * Constants — all numeric literal forms.
 * ------------------------------------------------------------------------- */

const PI         = 3.14159265358979;
const HEX_MASK   = 0xDEAD_BEEF;
const OCTAL_PERMS = 0o755;
const BINARY     = 0b1010_1010;
const BIG_INT    = 9007199254740993n;
const SCIENTIFIC = 6.022e23;
const NEGATIVE   = -273.15;

/* -------------------------------------------------------------------------
 * Functions
 * ------------------------------------------------------------------------- */

function* fizzbuzz(n) {
    for (let i = 1; i <= n; i++) {
        if (i % 15 === 0) yield "FizzBuzz";
        else if (i % 3 === 0) yield 'Fizz';
        else if (i % 5 === 0) yield 'Buzz';
        else yield String(i);
    }
}

const square = (x) => x * x;
const sumOfSquares = (...values) => values.reduce((acc, v) => acc + square(v), 0);

async function fetchUsers(url) {
    const res = await fetch(url, { headers: { 'Accept': 'application/json' } });
    if (!res.ok) throw new Error(`request failed: ${res.status}`);
    return res.json();
}

/* -------------------------------------------------------------------------
 * Classes
 * ------------------------------------------------------------------------- */

class Greeter {
    static DEFAULT = 'world';
    #greeting;

    constructor(greeting = Greeter.DEFAULT) {
        this.#greeting = greeting;
    }

    greet(name) {
        return `Hello, ${name ?? Greeter.DEFAULT}! (mask=${HEX_MASK.toString(16)})`;
    }
}

class Counter extends EventTarget {
    #value = 0;

    increment() {
        this.#value++;
        this.dispatchEvent(new CustomEvent('change', { detail: this.#value }));
    }

    get value() { return this.#value; }
}

/* -------------------------------------------------------------------------
 * Decorators (Stage-3 proposal)
 * ------------------------------------------------------------------------- */

function logged(originalMethod, _context) {
    return function (...args) {
        console.log(`calling with`, args);
        return originalMethod.apply(this, args);
    };
}

class Calculator {
    @logged
    add(a, b) { return a + b; }
}

/* -------------------------------------------------------------------------
 * Main
 * ------------------------------------------------------------------------- */

const main = async () => {
    const greeter = new Greeter('Prism');
    console.log(greeter.greet('World'));
    console.log([...fizzbuzz(15)].join(', '));
    console.log('sum of squares:', sumOfSquares(1, 2, 3, 4, 5));

    const { argv: [, , flag = '--default'] } = process;
    if (flag === '--verbose') console.debug({ PI, HEX_MASK, BIG_INT });
};

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
