// Prism Java sample.
//
// Exercises:
//   - package + imports
//   - annotations (@Override, @Deprecated, custom)
//   - records, sealed types, switch expressions
//   - generics, bounded type parameters
//   - text blocks ("""...""")
//   - lambdas + streams

package com.prism.examples;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

public final class GreeterApp {

    /* ---------------------------------------------------------------------
     * Constants — every numeric form Java supports.
     * --------------------------------------------------------------------- */

    public static final double  PI         = 3.14159_26535;
    public static final long    HEX_MASK   = 0xDEAD_BEEFL;
    public static final int     OCTAL      = 0755;
    public static final int     BINARY     = 0b1010_1010;
    public static final float   SCIENTIFIC = 6.022e23f;
    public static final char    NEWLINE    = '\n';
    public static final char    UNICODE    = 'é';

    /* ---------------------------------------------------------------------
     * Sealed type hierarchy + records
     * --------------------------------------------------------------------- */

    public sealed interface Shape permits Circle, Rectangle, Triangle {
        double area();
    }

    public record Circle(double radius) implements Shape {
        @Override public double area() { return PI * radius * radius; }
    }

    public record Rectangle(double width, double height) implements Shape {
        @Override public double area() { return width * height; }
    }

    public record Triangle(double base, double height) implements Shape {
        @Override public double area() { return 0.5 * base * height; }
    }

    /* ---------------------------------------------------------------------
     * Custom annotation
     * --------------------------------------------------------------------- */

    @Deprecated(since = "1.0", forRemoval = false)
    public @interface Experimental {
        String reason() default "";
    }

    @Experimental(reason = "API not finalized")
    public static <T extends Shape> Optional<T> largest(List<T> shapes) {
        return shapes.stream().max((a, b) -> Double.compare(a.area(), b.area()));
    }

    /* ---------------------------------------------------------------------
     * Greeter using switch expression on the sealed hierarchy
     * --------------------------------------------------------------------- */

    public static String describe(Shape s) {
        return switch (s) {
            case Circle c           -> "circle (r=%.2f)".formatted(c.radius());
            case Rectangle r        -> "rect %dx%d".formatted((int) r.width(), (int) r.height());
            case Triangle t         -> "triangle (b=" + t.base() + ", h=" + t.height() + ")";
        };
    }

    /* ---------------------------------------------------------------------
     * main
     * --------------------------------------------------------------------- */

    public static void main(String[] args) throws Exception {
        var banner = """
                Prism Java sample
                =================
                version : 1.0
                mask    : 0x%08X
                """.formatted(HEX_MASK);
        System.out.print(banner);

        List<Shape> shapes = List.of(
            new Circle(2.0),
            new Rectangle(3.0, 4.0),
            new Triangle(5.0, 6.0)
        );

        var summary = shapes.stream()
            .map(GreeterApp::describe)
            .collect(Collectors.joining(", "));
        System.out.println(summary);

        largest(shapes).ifPresent(s -> System.out.println("largest area: " + s.area()));

        CompletableFuture
            .supplyAsync(() -> "hello from a future")
            .thenAccept(System.out::println)
            .join();
    }
}
