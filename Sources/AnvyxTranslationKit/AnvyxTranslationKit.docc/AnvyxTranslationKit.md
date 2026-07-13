# ``AnvyxTranslationKit``

A small `async/await` façade over Apple's Translation framework for on-device
text translation.

## Overview

The system only vends a `TranslationSession` through SwiftUI, so attach a
``Translator`` once near the app root with `.translationHost(_:)`, then translate
from anywhere with plain `async/await`.

```swift
@State private var translator = Translator()
ContentView().translationHost(translator)

let vi = try await translator.translate("Hello", to: .init(identifier: "vi"))
```

## Topics

- ``Translator``
- ``TranslationAvailability``
