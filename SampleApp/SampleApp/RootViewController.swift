import UIKit
import BottomShelfer

/// Main menu: each row presents a different bottom-sheet configuration.
final class RootViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let demos: [(title: String, subtitle: String, action: (RootViewController) -> Void)] = [
        ("Default sheet", "Single large detent, package-default layout", { $0.presentDefaultSheet() }),
        ("Multi-detent sheet", "Small / medium / large snap points + buttons", { $0.presentFiltersSheet() }),
        ("Custom layout", "Wider sheet, big grabber, 0.6 max-height fraction", { $0.presentCustomLayoutSheet() }),
        ("Scrollable sheet", "Embedded scroll view, drag-to-dismiss", { $0.presentScrollableSheet() }),
        ("Keyboard-aware", "Sheet lifts above the keyboard when editing", { $0.presentKeyboardSheet() }),
        ("No dimming scrim", "Transparent backdrop, content behind stays visible", { $0.presentTransparentSheet() }),
        ("Non-draggable", "Dragging disabled — only dismissible via button", { $0.presentFixedSheet() }),
        ("Custom grabber", "Wider, thicker, indigo grabber pill", { $0.presentGrabberPillSheet() }),
        ("SwiftUI content", "SwiftUI form embedded in a bottom sheet", { $0.presentSwiftUISheet() }),
        ("Hidden grabber pill", "Drag works, but the pill is invisible", { $0.presentHiddenGrabberSheet() }),
        ("Custom grabber view", "Rainbow gradient grabber with custom animation", { $0.presentCustomGrabberSheet() }),
        ("Drag & dismiss events", "Callback log for grabber, content, dismiss", { $0.presentEventsSheet() }),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "BottomShelfer"

        tableView.register(DemoCell.self, forCellReuseIdentifier: DemoCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension RootViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DemoCell.reuseID, for: indexPath)
        let demo = demos[indexPath.row]
        cell.textLabel?.text = demo.title
        cell.detailTextLabel?.text = demo.subtitle
        return cell
    }
}

// MARK: - UITableViewDelegate

extension RootViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        demos[indexPath.row].action(self)
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

    func presentGrabberPillSheet() {
        let sheet = GrabberPillSheetViewController()
        var layout = BottomShelferLayoutConfiguration()
        layout.grabberPillSize = CGSize(width: 56, height: 6)
        layout.grabberPillCornerRadius = 3
        layout.grabberPillBottomOffset = 16
        sheet.bottomShelferPresentationManager.layoutConfiguration = layout
        sheet.bottomShelferPresentationManager.detents = [.medium()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentSwiftUISheet() {
        let sheet = SwiftUISheetViewController()
        sheet.bottomShelferPresentationManager.detents = [.medium(), .large()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentHiddenGrabberSheet() {
        let sheet = SimpleSheetViewController()
        var layout = BottomShelferLayoutConfiguration()
        layout.grabberPillSize = .zero
        layout.grabberPillBottomOffset = 0
        sheet.bottomShelferPresentationManager.layoutConfiguration = layout
        sheet.bottomShelferPresentationManager.detents = [.medium()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentCustomGrabberSheet() {
        let sheet = CustomGrabberViewController()
        var layout = BottomShelferLayoutConfiguration()
        layout.grabberPillSize = .zero
        layout.grabberPillBottomOffset = 0
        sheet.bottomShelferPresentationManager.layoutConfiguration = layout
        sheet.bottomShelferPresentationManager.detents = [.medium()]
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }

    func presentEventsSheet() {
        let sheet = EventsSheetViewController()
        sheet.bottomShelferPresentationManager.detents = BottomShelferDetent.detents(forContentHeight: 420)
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }
}

// MARK: - Demo cell

private final class DemoCell: UITableViewCell {
    static let reuseID = "DemoCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.textColor = .secondaryLabel
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
