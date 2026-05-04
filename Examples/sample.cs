// Prism C# sample.
//
// Exercises:
//   - file-scoped namespaces (C# 10+)
//   - records, primary constructors, init-only setters
//   - pattern matching with switch expressions
//   - LINQ + lambdas
//   - async/await, Task<T>
//   - attributes ([Obsolete], custom), preprocessor (#region, #if)
//   - verbatim strings (@"..."), interpolated ($"..."), interpolated verbatim ($@"...")
//   - nullable reference types

#nullable enable

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Prism.Examples;

/// <summary>Lightweight greeter app demonstrating modern C# features.</summary>
public sealed class GreeterApp
{
    #region Constants

    public const double Pi         = 3.14159_26535;
    public const long   HexMask    = 0xDEAD_BEEFL;
    public const int    Octal      = 0b0_1111_0000_0000;
    public const int    Binary     = 0b1010_1010;
    public const float  Scientific = 6.022e23f;
    public const char   Newline    = '\n';

    #endregion

    /* ------------------------------------------------------------------
     * Records + sealed inheritance
     * ------------------------------------------------------------------ */

    public abstract record Shape
    {
        public abstract double Area { get; }
    }

    public sealed record Circle(double Radius) : Shape
    {
        public override double Area => Pi * Radius * Radius;
    }

    public sealed record Rect(double Width, double Height) : Shape
    {
        public override double Area => Width * Height;
    }

    /* ------------------------------------------------------------------
     * Custom attribute
     * ------------------------------------------------------------------ */

    [AttributeUsage(AttributeTargets.Method)]
    private sealed class ExperimentalAttribute : Attribute
    {
        public string Reason { get; }
        public ExperimentalAttribute(string reason) => Reason = reason;
    }

    [Experimental("API may change")]
    public static T? LargestBy<T>(IEnumerable<T> items, Func<T, double> selector)
        where T : class
    {
        return items.OrderByDescending(selector).FirstOrDefault();
    }

    /* ------------------------------------------------------------------
     * Pattern matching
     * ------------------------------------------------------------------ */

    public static string Describe(Shape s) => s switch
    {
        Circle { Radius: > 0 } c => $"circle r={c.Radius:F2}",
        Rect (var w, var h)      => $"rect {w}x{h}",
        _                        => "unknown shape",
    };

    /* ------------------------------------------------------------------
     * Async showcase
     * ------------------------------------------------------------------ */

    [Obsolete("use FetchSquaresAsync instead")]
    public static async Task<int> FetchSquareAsync(int value)
    {
        await Task.Yield();
        return value * value;
    }

    public static async Task Main(string[] args)
    {
        var banner = $@"
Prism C# sample
===============
version : 1.0
mask    : 0x{HexMask:X8}
arg     : {(args.Length > 0 ? args[0] : "<none>")}
";
        Console.Write(banner);

        Shape[] shapes =
        {
            new Circle(2.0),
            new Rect(3.0, 4.0),
        };

        foreach (var s in shapes)
        {
            Console.WriteLine(Describe(s));
        }

        var largest = LargestBy(shapes, s => s.Area);
        Console.WriteLine($"largest area: {largest?.Area ?? double.NaN}");

        // LINQ + interpolation
        var sumOfSquares = Enumerable.Range(1, 5).Select(x => x * x).Sum();
        Console.WriteLine($"sum of squares (1..5) = {sumOfSquares}");

        // verbatim string
        var path = @"C:\Users\Default\AppData\Local\Prism\config.json";
        Console.WriteLine($"verbatim path: {path}");

#if DEBUG
        Console.Error.WriteLine("(debug build)");
#endif
        await Task.CompletedTask;
    }
}
