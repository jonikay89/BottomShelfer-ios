import UIKit
import BottomShelfer
import Combine

/// A simple sheet showing how to snap programmatically.
final class FiltersSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { false }

    private let snapSmallButton = UIButton(type: .system)
    private let snapLargeButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Drag the grabber, or use the buttons below."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)

        snapSmallButton.setTitle("Snap to small", for: .normal)
        snapSmallButton.addTarget(self, action: #selector(snapSmall), for: .touchUpInside)
        snapLargeButton.setTitle("Snap to large", for: .normal)
        snapLargeButton.addTarget(self, action: #selector(snapLarge), for: .touchUpInside)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, snapSmallButton, snapLargeButton, dismissButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func snapSmall() {
        let target = bottomShelferPresentationManager.detents.first?.height ?? 200
        (presentationController as? BottomShelferPresentationController)?.snapToHeight(target)
    }

    @objc private func snapLarge() {
        let target = bottomShelferPresentationManager.detents.last?.height ?? .zero
        (presentationController as? BottomShelferPresentationController)?.snapToHeight(target)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

/// Plain informational sheet used by the "default" and "custom layout" demos.
final class SimpleSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { true }

    private let dismissButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Tap the scrim or the button to dismiss.\nTry dragging the grabber too."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)

        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, dismissButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

/// Demonstrates an embedded scroll view: the sheet follows the scroll-to-top
/// gesture so you can drag it closed from anywhere over the list.
final class ScrollableSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension ScrollableSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 60 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row + 1)"
        return cell
    }
}

// MARK: - Keyboard-aware sheet

/// Shows how the sheet lifts out of the way when the keyboard appears.
/// Uses `startObservingKeyboardForBottomShelfer` and a text field.
final class KeyboardSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { false }

    private var cancellables = Set<AnyCancellable>()
    private let textField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let header = UILabel()
        header.text = "Tap the field — the sheet lifts for the keyboard."
        header.numberOfLines = 0
        header.textAlignment = .center
        header.font = .preferredFont(forTextStyle: .body)

        textField.placeholder = "Type something..."
        textField.borderStyle = .roundedRect

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [header, textField, dismissButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        startObservingKeyboardForBottomShelfer(cancellables: &cancellables)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - Transparent / no-dim sheet

/// Demonstrates a sheet without a dimming scrim. The background content remains
/// visible and tappable through the scrim area.
final class TransparentSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground

        let label = UILabel()
        label.text = "No dimming scrim behind this sheet.\nTap the button to dismiss."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, dismissButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - Fixed (non-draggable) sheet

/// A sheet the user cannot drag — only the dismissal button closes it.
final class FixedSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "This sheet cannot be dragged.\nUse the button to dismiss."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, dismissButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
