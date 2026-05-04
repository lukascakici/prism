// Prism TypeScript sample.
//
// Exercises:
// - interface / type / enum / namespace
// - generics, conditional types, mapped types
// - union and intersection types
// - decorators
// - readonly, public/private/protected modifiers
// - async/await, optional chaining, nullish coalescing
// - template literals with ${} interpolation

import { EventEmitter } from 'node:events';

/* -------------------------------------------------------------------------
 * Type-system showcase
 * ------------------------------------------------------------------------- */

export type ID = string | number;

export interface User {
    readonly id: ID;
    name: string;
    email?: string;
    roles: ReadonlyArray<'admin' | 'editor' | 'viewer'>;
}

export type Result<T, E = Error> =
    | { ok: true;  value: T }
    | { ok: false; error: E };

export enum HttpStatus {
    OK         = 200,
    Created    = 201,
    BadRequest = 400,
    NotFound   = 404,
    ServerErr  = 500,
}

namespace Geometry {
    export interface Point<T extends number = number> {
        readonly x: T;
        readonly y: T;
    }

    export const origin: Point = { x: 0, y: 0 };

    export function distance<T extends number>(a: Point<T>, b: Point<T>): number {
        const dx = (a.x as number) - (b.x as number);
        const dy = (a.y as number) - (b.y as number);
        return Math.hypot(dx, dy);
    }
}

/* -------------------------------------------------------------------------
 * Decorators + classes
 * ------------------------------------------------------------------------- */

function deprecated(reason: string) {
    return function <T extends abstract new (...args: any[]) => any>(target: T, _context: ClassDecoratorContext) {
        console.warn(`${target.name} is deprecated: ${reason}`);
        return target;
    };
}

@deprecated('use UserRepository instead')
abstract class LegacyStore<T> {
    protected readonly cache = new Map<ID, T>();

    abstract load(id: ID): Promise<T>;

    public async getOrLoad(id: ID): Promise<T> {
        return this.cache.get(id) ?? await this.load(id);
    }
}

class UserRepository extends LegacyStore<User> {
    private readonly emitter = new EventEmitter();

    override async load(id: ID): Promise<User> {
        const url = `https://api.example.com/users/${id}` as const;
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const user = (await res.json()) as User;
        this.cache.set(id, user);
        this.emitter.emit('loaded', user);
        return user;
    }

    on(event: 'loaded', listener: (u: User) => void): this {
        this.emitter.on(event, listener);
        return this;
    }
}

/* -------------------------------------------------------------------------
 * Conditional + mapped types
 * ------------------------------------------------------------------------- */

type NonNullableProperties<T> = { [K in keyof T]-?: NonNullable<T[K]> };
type FirstParameter<F> = F extends (first: infer P, ...rest: any[]) => any ? P : never;

const repo = new UserRepository();
repo.on('loaded', (u: User) => console.log(`loaded user ${u.name} (${u.id})`));

(async () => {
    const u = await repo.getOrLoad(42);
    console.log(`hello, ${u.name} — status=${HttpStatus.OK}`);
    const d = Geometry.distance({ x: 1, y: 1 }, Geometry.origin);
    console.log(`distance from origin = ${d.toFixed(3)}`);
})();
