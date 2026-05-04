# Prism Markdown Sample

A document that exercises every Markdown feature the **Prism** tokenizer recognizes.

## Headers

# H1 heading
## H2 heading
### H3 heading
#### H4 heading
##### H5 heading
###### H6 heading

## Emphasis

This sentence has *italic*, _also italic_, **bold**, __also bold__, and ***bold italic*** in it.

## Links and images

Visit [the Prism README](README.md) for details, or the [Apple QuickLook docs](https://developer.apple.com/documentation/quicklook).

![A placeholder image](images/preview.png "Optional title")

## Lists

Unordered:

- First item
- Second item
  - Nested item
  - Another nested item
* Mixed bullet style
+ Plus-prefixed item

Ordered:

1. Install Xcode.
2. Run `xcodegen generate`.
3. Press Cmd+R to launch the host app.

## Blockquotes

> The best way to predict the future is to invent it.
> — *Alan Kay*

## Inline and fenced code

Use `let answer = 42` for the canonical example. Inline code spans can include ``a backtick like ` `` if you double up the fence.

```swift
// Fenced code block — language hint preserved as part of the block.
struct Greeter {
    let name: String
    func greet() -> String { "Hello, \(name)!" }
}
```

```bash
# A shell snippet inside a Markdown sample.
xcodegen generate && open Prism.xcodeproj
```

```
Plain fenced block with no language hint.
Lines are still rendered as a code block.
```

## Horizontal rules

Three or more dashes:

---

Or asterisks:

***

## Mixed inline content

You can combine **bold containing `code`**, _italic with [a link](https://example.com)_, and even ~~strikethrough-ish content~~ on the same line.
