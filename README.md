## My Stocks

- Basic Swift iOS app to track stocks :zap:
- Data providers supported: `Finnhub`, `Tiingo`, `IEX Cloud` :pray:

<img src=Images/0.png>

## Requirements

- iOS 13

## Getting Started

1. Get a data provider [free API key](#credits)
2. Xcode: Set the API key in the provider file, for example `Finnhub.swift`

```swift
private extension Finnhub {

    static let apiKey = "<your API key>"

```

3. Xcode: Set the provider in `MyStocksViewController.swift`

```swift
class MyStocksViewController: UIViewController {

    // ...

    private let provider: Provider = .finnhub
```

4. Xcode: <kbd>CMD</kbd> <kbd>R</kbd>

## Credits

- https://finnhub.io/
- https://www.tiingo.com/
- https://iexcloud.io/

## Contact

- [github.com/dkhamsing](https://github.com/dkhamsing)
- [twitter.com/dkhamsing](https://twitter.com/dkhamsing)

## License

This project is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
