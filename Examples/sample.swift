// Prism Swift sample.
//
// Exercises:
// - line + block comments (block /* nested /* like this */ */ )
// - regular, multi-line, and raw strings (#"..."#, ##"..."##)
// - numeric literals: int, double, hex, octal, binary
// - attributes (@available, @MainActor, @propertyWrapper)
// - struct / class / enum / protocol / extension / actor
// - async / await / throws / try

import Foundation

// MARK: - Constants

let pi: Double = 3.14159_26535
let mask: UInt32 = 0xDEAD_BEEF
let perms: Int = 0o755
let flag: UInt8 = 0b1010_1010
let scientific: Double = 6.022e23

// Strings — every flavor.
let plain = "hello, world"
let interpolated = "pi ≈ \(pi)"
let multiline = """
    This is a
    multi-line string
    with \(interpolated) interpolation.
    """
let rawSingle = #"a regex with literal backslash: \d+"#
let rawTriple = ##"contains a "# without closing"##

// MARK: - Protocols

protocol Greetable {
    var name: String { get }
    func greet() -> String
}

// MARK: - Types

struct Point: Equatable {
    let x: Double
    let y: Double

    func distance(to other: Point) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

enum Direction: String, CaseIterable {
    case north, south, east, west

    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east:  return .west
        case .west:  return .east
        }
    }
}

actor Counter {
    private var value: Int = 0

    func increment() { value += 1 }
    func read() -> Int { value }
}

@MainActor
final class Greeter: Greetable {
    let name: String

    init(name: String) {
        self.name = name
    }

    func greet() -> String {
        "Merhaba, \(name)!"
    }
}

// MARK: - Property wrapper

@propertyWrapper
struct Clamped<Value: Comparable> {
    private var storage: Value
    private let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.storage = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }

    var wrappedValue: Value {
        get { storage }
        set { storage = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}

// MARK: - Async showcase

@available(macOS 12.0, *)
func fetchSquares(_ values: [Int]) async throws -> [Int] {
    try await Task.sleep(nanoseconds: 1)
    return values.map { $0 * $0 }
}

// MARK: - Extension

extension Array where Element == Int {
    /// Sum of squares — generic-constrained extension.
    var sumOfSquares: Int { reduce(0) { $0 + $1 * $1 } }
}

#if DEBUG
let label = "debug build"
#else
let label = "release build"
#endif

print(label)
