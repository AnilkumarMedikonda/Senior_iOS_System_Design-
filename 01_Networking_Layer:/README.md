# Network Layer Demo — SwiftUI & UIKit

A simple networking layer with MVVM, using closure-based completion handlers and no third-party libraries. It fetches products from [DummyJSON](https://dummyjson.com/products) and shows them in a list.

The network layer is UI-independent: the same Endpoint → APIClient → Repository works for both SwiftUI and UIKit. Only the ViewModel binding and the View change.

---

## Architecture

```
View  →  ViewModel  →  Repository  →  APIClient  →  HTTPClient (URLSession)
                                                          │
View  ←  state      ←  [Product]   ←  Result<T, Error> ←──┘
```

| Layer | Job |
|-------|-----|
| View | Shows loading / list / error |
| ViewModel | Calls repository, maps result to UI state |
| Repository | Picks the endpoint, returns models |
| APIClient | Build request → send → validate status → decode |
| HTTPClient | Protocol over URLSession, mockable in tests |

---

## Folder Structure

```
NetworkLayerSwiftUIDemo/
├── App/
│   └── NetworkLayerSwiftUIDemoApp.swift
├── Network/
│   ├── Endpoint.swift
│   ├── NetworkError.swift
│   ├── HTTPClient.swift
│   └── APIClient.swift
├── Models/
│   └── Product.swift
├── Repository/
│   └── ProductRepository.swift
├── ViewModel/
│   └── ProductListViewModel.swift
└── View/
    └── ProductListView.swift
```

For UIKit, `App/` holds `AppDelegate.swift` + `SceneDelegate.swift`, and `View/` holds `ProductListViewController.swift`. `Network/`, `Models/` and `Repository/` stay exactly the same.

---

## SwiftUI Version

The ViewModel uses `@Observable`, so the View re-renders automatically when `state` changes.

```swift
@Observable
final class ProductListViewModel {
    private(set) var state: ProductsState = .loading
    ...
}

struct ProductListView: View {
    @State private var viewModel = ProductListViewModel()

    var body: some View {
        content
            .onAppear { viewModel.loadProducts() }
    }
}
```

---

## UIKit Version

The ViewModel exposes a closure, and the ViewController listens and reloads the table.

```swift
final class ProductListViewModel {
    var onStateChange: ((ProductsState) -> Void)?
    private(set) var state: ProductsState = .loading {
        didSet { onStateChange?(state) }
    }
    ...
}

final class ProductListViewController: UIViewController, UITableViewDataSource {
    private let viewModel = ProductListViewModel()
    private let tableView = UITableView()
    private var products: [Product] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.loadProducts()
    }

    private func render(_ state: ProductsState) {
        switch state {
        case .loading:
            break
        case .loaded(let items):
            products = items
            tableView.reloadData()
        case .failed(let message):
            print(message)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.text = products[indexPath.row].title
        cell.detailTextLabel?.text = "$\(products[indexPath.row].price)"
        return cell
    }
}
```

---

## SwiftUI vs UIKit

| | SwiftUI | UIKit |
|---|---------|-------|
| Binding | `@Observable` (automatic) | `onStateChange` closure (manual) |
| Load trigger | `.onAppear` | `viewDidLoad` |
| UI update | View re-renders | `tableView.reloadData()` |
| Entry point | `@main App` | `AppDelegate` + `SceneDelegate` |
| Network layer | Same | Same |

---

## Key Points

- Completion is called on a background thread, so the ViewModel switches to the main thread with `DispatchQueue.main.async`
- `[weak self]` prevents retaining the ViewModel or ViewController after the screen closes
- Cancelled requests are ignored silently
- New API = new `Endpoint` + repository method; `APIClient` never changes (OCP)
- `HTTPClient` protocol → inject a mock in tests (DIP)

---

## Run

1. Open the project in Xcode
2. Build and run on a simulator (internet needed)
3. Products list loads from DummyJSON
