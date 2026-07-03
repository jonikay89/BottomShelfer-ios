# BottomShelfer — Code Recipes

Copy each example into your project and adapt as needed.

---

## Basic presentation

```swift
import UIKit
import BottomShelfer

final class MySheet: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}

// Present
let sheet = MySheet()
sheet.bottomShelferPresentationManager.detents = [.medium()]
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## Multi-detent with snap buttons

```swift
final class MySheet: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Snap to small
        let smallBtn = UIButton(type: .system)
        smallBtn.setTitle("Snap small", for: .normal)
        smallBtn.addTarget(self, action: #selector(snapSmall), for: .touchUpInside)
        view.addSubview(smallBtn)
    }

    @objc private func snapSmall() {
        let target = bottomShelferPresentationManager.detents.first?.height ?? 200
        (presentationController as? BottomShelferPresentationController)?
            .snapToHeight(target)
    }
}

// Present with 3 detents, starting at medium
let sheet = MySheet()
sheet.bottomShelferPresentationManager.detents = BottomShelferDetent
    .detents(forContentHeight: 420)
sheet.bottomShelferPresentationManager.selectedDetentIndex = 1
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## Custom layout

```swift
var layout = BottomShelferLayoutConfiguration()
layout.maxSheetWidth = 500
layout.grabberPillSize = CGSize(width: 60, height: 8)
layout.grabberPillBottomOffset = 14
layout.maxHeightFraction = 0.6

let sheet = MySheet()
sheet.bottomShelferPresentationManager.layoutConfiguration = layout
sheet.bottomShelferPresentationManager.cornerRadius = 28
sheet.bottomShelferPresentationManager.dimmingColor = .black.withAlphaComponent(0.4)
sheet.bottomShelferPresentationManager.detents = [.large()]
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## No dimming scrim

```swift
let sheet = MySheet()
sheet.bottomShelferPresentationManager.isDimmingViewEnabled = false
sheet.bottomShelferPresentationManager.detents = [.medium()]
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## Non-draggable (button dismiss only)

```swift
let sheet = MySheet()
sheet.bottomShelferPresentationManager.isDraggingEnabled = false
sheet.bottomShelferPresentationManager.detents = [.small()]
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## Hidden grabber pill (drag still works)

```swift
var layout = BottomShelferLayoutConfiguration()
layout.grabberPillSize = .zero
layout.grabberPillBottomOffset = 0

let sheet = MySheet()
sheet.bottomShelferPresentationManager.layoutConfiguration = layout
sheet.bottomShelferPresentationManager.detents = [.medium()]
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## Keyboard avoidance

```swift
import Combine

final class MySheet: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let textField = UITextField()
        textField.placeholder = "Type here..."
        textField.borderStyle = .roundedRect
        view.addSubview(textField)

        startObservingKeyboardForBottomShelfer(cancellables: &cancellables)
    }
}
```

---

## Callbacks — drag, dismiss, detent change

```swift
let manager = sheet.bottomShelferPresentationManager

manager.onDismiss = {
    print("Sheet dismissed")
}

manager.onGrabberDragBegan = {
    print("Grabber drag started")
}

manager.onGrabberDragEnded = {
    print("Grabber drag ended")
}

manager.onContentDragBegan = {
    print("Content drag started")
}

manager.onContentDragEnded = {
    print("Content drag ended")
}

manager.onDetentChanged = { index, height in
    print("Snapped to detent \(index) at \(Int(height))pt")
}
```

---

## Scrollable content

```swift
final class MySheet: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension MySheet: UITableViewDataSource {
    func tableView(_ tv: UITableView, numberOfRowsInSection _: Int) -> Int { 50 }
    func tableView(_ tv: UITableView, cellForRowAt i: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: i)
        cell.textLabel?.text = "Row \(i.row + 1)"
        return cell
    }
}
```

---

## SwiftUI inside a bottom sheet

```swift
import SwiftUI

final class MySheet: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let hosting = UIHostingController(rootView: MySwiftUIForm())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

struct MySwiftUIForm: View {
    @State private var name = ""
    var body: some View {
        VStack(spacing: 16) {
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            Toggle("Enabled", isOn: .constant(true))
        }
    }
}
```

---

## Custom grabber (replace default pill)

Hide the built-in pill and layer your own view at the top of the sheet,
using callbacks to animate it during drag.

```swift
final class MySheet: UIViewController, BottomShelferPresentable {
    lazy var bottomShelferPresentationManager = {
        let m = BottomShelferPresentationManager()
        m.onGrabberDragBegan = { [weak self] in self?.animatePill(active: true) }
        m.onGrabberDragEnded = { [weak self] in self?.animatePill(active: false) }
        return m
    }()

    private let myPill = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        myPill.backgroundColor = .systemIndigo
        myPill.layer.cornerRadius = 4
        myPill.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(myPill)

        NSLayoutConstraint.activate([
            myPill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            myPill.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            myPill.widthAnchor.constraint(equalToConstant: 48),
            myPill.heightAnchor.constraint(equalToConstant: 6),
        ])
    }

    private func animatePill(active: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.myPill.transform = active
                ? CGAffineTransform(scaleX: 1.4, y: 1.0)
                : .identity
            self.myPill.alpha = active ? 0.5 : 1
        }
    }
}

// Present with hidden default pill
var layout = BottomShelferLayoutConfiguration()
layout.grabberPillSize = .zero
let sheet = MySheet()
sheet.bottomShelferPresentationManager.layoutConfiguration = layout
sheet.bottomShelferPresentationManager.detents = [.medium()]
sheet.presentAsBottomShelfer(from: self, animated: true)
```

---

## All layout configuration options

```swift
var layout = BottomShelferLayoutConfiguration(
    maxSheetWidth: 430,            // clamp width on iPad
    maxHeightFraction: 0.9,        // % of container height
    grabberHitAreaHeight: 44,      // draggable band height
    grabberPillSize: CGSize(width: 36, height: 5),
    grabberPillBottomOffset: 12,   // distance from sheet edge
    grabberPillCornerRadius: 2.5
)

let sheet = MySheet()
sheet.bottomShelferPresentationManager.layoutConfiguration = layout
```

---

## Dismiss behavior control

```swift
final class MySheet: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    // true: first tap on scrim = immediate dismiss
    // false: first tap on scrim = close keyboard; second tap = dismiss
    var dismissOnHide: Bool { true }
}
```
