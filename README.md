# TranslationKit

A small `async/await` façade over Apple's Translation framework for on-device text translation.

## Features

- **`Translator`** — attach once near the app root with `.translationHost(_:)`, then translate from anywhere with `async/await`.
- **`TranslationAvailability`** — check language support and download status.
- **`LanguageDetection`** — detect the language of a text.
- **`PlaceholderMasking`** — keeps format placeholders such as `%@` and `%1$d` intact through translation; if they cannot be restored, the source text is returned.

## Requirements

- iOS 18+
- Swift 6.2+ (Xcode 26+)

## Installation

```swift
.package(url: "https://github.com/anvyxhq/TranslationKit.git", branch: "main")
```

Add the product `AnvyxTranslationKit` to your target.

## Usage

```swift
import AnvyxTranslationKit

@State private var translator = Translator()

ContentView().translationHost(translator)

let vi = try await translator.translate("Hello", to: .init(identifier: "vi"))
```

## License

MIT
