import UIKit
import BottomShelfer

/// Main menu: each button presents the slide-up sheet with a different
/// configuration so you can feel the customization options on the simulator.
final class RootViewController: UIViewController {

    private let stack = UIStackView()
    private let titleLabel = UILabel()

    private let demos: [(title: String, subtitle: String, action: (RootViewController) -> Void)] = [
        ("Default sheet", "Single large detent, package-default layout", { $0.presentDefaultSheet() }),
        ("Multi-detent sheet", "Small / medium / large snap points + buttons", { $0.presentFiltersSheet() }),
        ("Custom layout", "Wider sheet, big grabber, 0.6 max-height fraction", { $0.presentCustomLayoutSheet() }),
        ("Scrollable sheet", "Embedded scroll view, drag-to-dismiss", { $0.presentScrollableSheet() }),
        ("Keyboard-aware", "Sheet lifts above the keyboard when editing", { $0.presentKeyboardSheet() }),
        ("No dimming scrim", "Transparent backdrop, content behind stays visible", { $0.presentTransparentSheet() }),
        ("Non-draggable", "Dragging disabled — only dismissible via button", { $0.presentFixedSheet() }),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "BottomShelfer"
        buildUI()
    }

    private func buildUI() {
        titleLabel.text = "BottomShelfer demos"
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true

        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill

        let container = UIStackView(arrangedSubviews: [titleLabel, stack])
        container.axis = .vertical
        container.spacing = 24
        container.alignment = .fill
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        for demo in demos {
            let button = DemoButton(title: demo.title, subtitle: demo.subtitle)
            button.addTarget(self, action: #selector(demoTapped(_:)), for: .touchUpInside)
            button.tag = demos.firstIndex { $0.title == demo.title } ?? 0
            stack.addArrangedSubview(button)
        }
    }

    @objc private func demoTapped(_ sender: DemoButton) {
        demos[sender.tag].action(self)
    }
}

// MARK: - Demo presentations

private extension RootViewController {

    func presentDefaultSheet() {
        let sheet = SimpleSheetViewController()
        sheet.bottomShelferPresentationManager.detents = [.medium()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentFiltersSheet() {
        let sheet = FiltersSheetViewController()
        sheet.bottomShelferPresentationManager.detents = BottomShelferDetent.detents(forContentHeight: 420)
        sheet.bottomShelferPresentationManager.selectedDetentIndex = 1
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentCustomLayoutSheet() {
        let sheet = SimpleSheetViewController()
        var layout = BottomShelferLayoutConfiguration()
        layout.maxSheetWidth = 500
        layout.grabberPillSize = CGSize(width: 60, height: 8)
        layout.grabberPillBottomOffset = 14
        layout.maxHeightFraction = 0.6
        sheet.bottomShelferPresentationManager.layoutConfiguration = layout
        sheet.bottomShelferPresentationManager.detents = [.large()]
        sheet.bottomShelferPresentationManager.dimmingColor = .black.withAlphaComponent(0.4)
        sheet.bottomShelferPresentationManager.cornerRadius = 28
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentScrollableSheet() {
        let sheet = ScrollableSheetViewController()
        sheet.bottomShelferPresentationManager.detents = [.medium(), .large()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentKeyboardSheet() {
        let sheet = KeyboardSheetViewController()
        sheet.bottomShelferPresentationManager.detents = [.custom(height: 200)]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentTransparentSheet() {
        let sheet = TransparentSheetViewController()
        sheet.bottomShelferPresentationManager.isDimmingViewEnabled = false
        sheet.bottomShelferPresentationManager.detents = [.medium()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentFixedSheet() {
        let sheet = FixedSheetViewController()
        sheet.bottomShelferPresentationManager.isDraggingEnabled = false
        sheet.bottomShelferPresentationManager.detents = [.small()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }
}

// MARK: - Demo button

private final class DemoButton: UIButton {
    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 16
        backgroundColor = .secondarySystemBackground

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 2
        container.alignment = .leading
        container.isUserInteractionEnabled = false
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .tertiarySystemBackground : .secondarySystemBackground }
    }
}
