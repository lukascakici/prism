// Prism Kotlin sample.
//
// Exercises:
//   - package + imports
//   - val/var, data class, sealed class, object
//   - extension functions, infix functions, operator overloading
//   - higher-order functions, lambdas, scope functions (let/run/with/apply/also)
//   - coroutines (suspend)
//   - raw strings ("""..."""), string templates ($var, ${expr})
//   - annotations (@JvmStatic, @file:JvmName)

@file:JvmName("PrismKotlinSample")

package com.prism.examples

import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.delay
import kotlin.math.hypot

/* -----------------------------------------------------------------------------
 * Constants
 * ----------------------------------------------------------------------------- */

const val PI: Double         = 3.14159_26535
const val HEX_MASK: Long     = 0xDEAD_BEEFL
const val BINARY: Int        = 0b1010_1010
const val SCIENTIFIC: Double = 6.022e23
const val NEWLINE: Char      = '\n'

/* -----------------------------------------------------------------------------
 * Types
 * ----------------------------------------------------------------------------- */

data class Point(val x: Double, val y: Double) {
    operator fun plus(other: Point) = Point(x + other.x, y + other.y)
    infix fun distanceTo(other: Point): Double = hypot(x - other.x, y - other.y)
}

sealed class Shape {
    abstract val area: Double

    data class Circle(val radius: Double) : Shape() {
        override val area: Double get() = PI * radius * radius
    }

    data class Rect(val width: Double, val height: Double) : Shape() {
        override val area: Double get() = width * height
    }

    object EmptyShape : Shape() {
        override val area: Double = 0.0
    }
}

enum class Severity(val label: String) {
    DEBUG("debug"),
    INFO("info"),
    WARN("warn"),
    ERROR("error");

    companion object {
        @JvmStatic fun fromString(s: String): Severity? =
            values().firstOrNull { it.label.equals(s, ignoreCase = true) }
    }
}

/* -----------------------------------------------------------------------------
 * Extensions + scope functions
 * ----------------------------------------------------------------------------- */

fun List<Int>.sumOfSquares(): Int = sumOf { it * it }

fun describe(shape: Shape): String = when (shape) {
    is Shape.Circle    -> "circle r=${shape.radius}"
    is Shape.Rect      -> "rect ${shape.width}x${shape.height}"
    Shape.EmptyShape   -> "empty"
}

/* -----------------------------------------------------------------------------
 * Coroutine demo
 * ----------------------------------------------------------------------------- */

suspend fun fetchSquare(value: Int): Int {
    delay(1)
    return value * value
}

/* -----------------------------------------------------------------------------
 * main
 * ----------------------------------------------------------------------------- */

fun main(args: Array<String>) = runBlocking {
    val banner = """
        Prism Kotlin sample
        ===================
        version : 1.0
        mask    : 0x${HEX_MASK.toString(16).uppercase()}
        first arg: ${args.firstOrNull() ?: "<none>"}
    """.trimIndent()
    println(banner)

    val shapes: List<Shape> = listOf(
        Shape.Circle(2.0),
        Shape.Rect(3.0, 4.0),
        Shape.EmptyShape,
    )
    println(shapes.joinToString(separator = ", ") { describe(it) })

    val a = Point(1.0, 2.0)
    val b = Point(4.0, 6.0)
    println("distance(a, b) = ${a distanceTo b}")
    println("a + b = ${a + b}")

    val squares = (1..5).map { async ->
        fetchSquare(async)
    }
    println("squares = $squares (sum=${squares.sum()})")

    Severity.fromString("warn")?.also { println("severity = ${it.label}") }
}
