// Prism Rust sample.
//
// Exercises:
//   - line, /// doc, /** ... */, and nested /* /* */ */ block comments
//   - raw strings r"..." / r#"..."#  and byte strings b"..."
//   - char vs lifetime: 'x' (char) vs 'a (lifetime)
//   - macros (println!, vec!, format!) and #[attr] / #![attr]
//   - traits, impl blocks, generics with bounds
//   - pattern matching, Option/Result, ? operator
//   - async (without runtime — just syntactic showcase)

#![allow(dead_code, unused_variables)]
#![cfg_attr(test, allow(unused_imports))]

use std::collections::HashMap;
use std::fmt::{self, Display, Formatter};

/// Crate-level constants — every numeric form.
const PI: f64        = 3.14159_26535_f64;
const HEX_MASK: u32  = 0xDEAD_BEEF;
const OCTAL: u32     = 0o755;
const BINARY: u8     = 0b1010_1010;
const SCIENTIFIC: f64 = 6.022e23;
const NEWLINE: char  = '\n';
const UNICODE: char  = 'é';

/* -----------------------------------------------------------------------------
 * Trait + generic data type
 * -- nested /* like /* this */ */ -- block comment showcase
 * ----------------------------------------------------------------------------- */

trait Shape {
    fn area(&self) -> f64;
    fn kind(&self) -> &'static str;
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct Circle { radius: f64 }

impl Shape for Circle {
    fn area(&self) -> f64 { PI * self.radius * self.radius }
    fn kind(&self) -> &'static str { "circle" }
}

#[derive(Debug, Clone, Copy, PartialEq)]
struct Rect { width: f64, height: f64 }

impl Shape for Rect {
    fn area(&self) -> f64 { self.width * self.height }
    fn kind(&self) -> &'static str { "rect" }
}

/// Demonstrates lifetimes and trait bounds.
fn largest<'a, T: Shape>(items: &'a [T]) -> Option<&'a T> {
    items.iter().reduce(|a, b| if a.area() >= b.area() { a } else { b })
}

/* -----------------------------------------------------------------------------
 * Enum + pattern matching
 * ----------------------------------------------------------------------------- */

enum Severity {
    Debug,
    Info,
    Warn,
    Error(String),
}

impl Display for Severity {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Severity::Debug      => write!(f, "DEBUG"),
            Severity::Info       => write!(f, "INFO"),
            Severity::Warn       => write!(f, "WARN"),
            Severity::Error(msg) => write!(f, "ERROR: {msg}"),
        }
    }
}

/* -----------------------------------------------------------------------------
 * Strings: regular, raw, byte
 * ----------------------------------------------------------------------------- */

fn strings_showcase() -> String {
    let plain   = "hello, world";
    let escaped = "tab\there, newline\n";
    let raw     = r"contains a literal backslash: \d+ and \n stays literal";
    let raw_h   = r#"a "raw" string with embedded quotes"#;
    let bytes   = b"raw\xDEbytes";
    format!("{plain} :: {escaped} :: {raw} :: {raw_h} :: bytes={:?}", bytes)
}

/* -----------------------------------------------------------------------------
 * Async + Result
 * ----------------------------------------------------------------------------- */

async fn fetch_square(value: i32) -> Result<i32, &'static str> {
    if value < 0 { Err("negative") } else { Ok(value * value) }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Prism Rust sample — mask={HEX_MASK:#X}");

    let shapes: Vec<Box<dyn Shape>> = vec![
        Box::new(Circle { radius: 2.0 }),
        Box::new(Rect   { width: 3.0, height: 4.0 }),
    ];
    for s in &shapes {
        println!("{}: area={:.3}", s.kind(), s.area());
    }

    let circles = [Circle { radius: 1.0 }, Circle { radius: 5.0 }];
    if let Some(c) = largest(&circles) {
        println!("largest circle: {c:?}");
    }

    let mut levels: HashMap<&str, Severity> = HashMap::new();
    levels.insert("default", Severity::Info);
    levels.insert("io", Severity::Error("disk full".into()));

    for (component, level) in &levels {
        println!("[{component}] {level}");
    }

    println!("{}", strings_showcase());

    let squares: Vec<i32> = (1..=5)
        .map(|n| futures::executor::block_on(fetch_square(n)).unwrap())
        .collect();
    println!("squares = {squares:?}");

    Ok(())
}
