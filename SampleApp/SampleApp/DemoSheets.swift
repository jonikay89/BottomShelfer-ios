import UIKit
import BottomShelfer
import Combine
import SwiftUI

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

// MARK: - Grabber pill customization

/// Shows how to customize the grabber pill — size, color, corner radius.
final class GrabberPillSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Custom grabber: wider, thicker,\nbright pill with rounded ends."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .body)

        let samplePill = UIView()
        samplePill.backgroundColor = .systemIndigo
        samplePill.layer.cornerRadius = 4
        samplePill.translatesAutoresizingMaskIntoConstraints = false

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, samplePill, dismissButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            samplePill.widthAnchor.constraint(equalToConstant: 100),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - Custom grabber view demo

/// Replaces the built-in grabber pill with a custom rainbow-gradient view
/// that has its own drag animation, positioned at the top of the sheet.
final class CustomGrabberViewController: UIViewController, BottomShelferPresentable {
    lazy var bottomShelferPresentationManager: BottomShelferPresentationManager = {
        let manager = BottomShelferPresentationManager()
        manager.onGrabberDragBegan = { [weak self] in self?.animateGrabber(active: true) }
        manager.onGrabberDragEnded = { [weak self] in self?.animateGrabber(active: false) }
        return manager
    }()

    var dismissOnHide: Bool { true }

    private let customGrabber = CustomGrabberView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        customGrabber.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customGrabber)

        let label = UILabel()
        label.text = "Custom rainbow grabber,\ndrag it to move the sheet."
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
            customGrabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            customGrabber.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            customGrabber.widthAnchor.constraint(equalToConstant: 48),
            customGrabber.heightAnchor.constraint(equalToConstant: 6),

            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func animateGrabber(active: Bool) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            self.customGrabber.transform = active
                ? CGAffineTransform(scaleX: 1.5, y: 1.8).rotated(by: .pi / 180 * 3)
                : .identity
            self.customGrabber.alpha = active ? 0.7 : 1
        }
    }
}

private final class CustomGrabberView: UIView {

    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 3
        clipsToBounds = true

        gradient.colors = [
            UIColor.systemRed.cgColor,
            UIColor.systemOrange.cgColor,
            UIColor.systemYellow.cgColor,
            UIColor.systemGreen.cgColor,
            UIColor.systemBlue.cgColor,
            UIColor.systemPurple.cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}

// MARK: - Events demo

/// Demonstrates drag, dismiss, and detent-change callbacks with on-screen log.
final class EventsSheetViewController: UIViewController, BottomShelferPresentable {
    lazy var bottomShelferPresentationManager: BottomShelferPresentationManager = {
        let manager = BottomShelferPresentationManager()
        manager.onDismiss = { [weak self] in self?.handleEvent("onDismiss") }
        manager.onGrabberDragBegan = { [weak self] in self?.handleEvent("onGrabberDragBegan") }
        manager.onGrabberDragEnded = { [weak self] in self?.handleEvent("onGrabberDragEnded") }
        manager.onContentDragBegan = { [weak self] in self?.handleEvent("onContentDragBegan") }
        manager.onContentDragEnded = { [weak self] in self?.handleEvent("onContentDragEnded") }
        manager.onDetentChanged = { [weak self] idx, h in
            self?.handleEvent("onDetentChanged idx=\(idx) h=\(Int(h))pt")
        }
        return manager
    }()

    var dismissOnHide: Bool { false }

    private let eventLog = UILabel()
    private var logCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let header = UILabel()
        header.text = "Drag & dismiss events"
        header.font = .preferredFont(forTextStyle: .headline)
        header.textAlignment = .center

        eventLog.text = "Drag the grabber or tap the scrim…"
        eventLog.numberOfLines = 0
        eventLog.textAlignment = .center
        eventLog.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        eventLog.backgroundColor = .tertiarySystemBackground
        eventLog.layer.cornerRadius = 8
        eventLog.clipsToBounds = true

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [header, eventLog, dismissButton])
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
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func handleEvent(_ event: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: Date())
        logCount += 1
        let message = "#\(logCount)  [\(time)]  \(event)"
        eventLog.text = message
        print("[BottomShelfer] \(message)")
    }
}

/// Embeds a SwiftUI form inside a UIKit bottom-sheet, demonstrating
/// interoperability between the two frameworks.
final class SwiftUISheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let header = UILabel()
        header.text = "SwiftUI pickers inside BottomShelfer"
        header.font = .preferredFont(forTextStyle: .headline)
        header.textAlignment = .center

        let hosting = UIHostingController(rootView: SwiftUIDemoContent())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)

        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [header, hosting.view, dismissButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
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

private struct SwiftUIDemoContent: View {
    @State private var selectedColor = "Blue"
    @State private var fontSize: CGFloat = 16
    @State private var isEnabled = true

    private let colors = ["Blue", "Green", "Orange", "Purple", "Red"]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Color")
                Spacer()
                Picker("Color", selection: $selectedColor) {
                    ForEach(colors, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Font size: \(Int(fontSize))pt")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $fontSize, in: 12...28, step: 1)
                    .tint(swiftColor)
            }

            Toggle("Enabled", isOn: $isEnabled)
                .tint(swiftColor)
        }
        .padding(.vertical, 8)
    }

    private var swiftColor: Color {
        switch selectedColor {
        case "Green": return .green
        case "Orange": return .orange
        case "Purple": return .purple
        case "Red": return .red
        default: return .blue
        }
    }
}
