import UIKit

// MARK: - A minimal view controller presented as a slide-up sheet.

final class FiltersViewController: UIViewController, BottomShelferPresentable {

    // 1. Own the manager. It doubles as transitioningDelegate.
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    // Optional: dismiss on first tap of the dimming view instead of
    // closing the keyboard first. Default is false.
    // var dismissOnHide: Bool { true }

    private let contentLabel = UILabel()
    private let snapSmallButton = UIButton(type: .system)
    private let snapLargeButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        configureManager()
        buildUI()
    }

    // MARK: Configuration

    private func configureManager() {
        // Three snap heights, opening at the middle one.
        bottomShelferPresentationManager.detents = BottomShelferDetent.detents(forContentHeight: 420)
        bottomShelferPresentationManager.selectedDetentIndex = 1   // 0 = small, 1 = medium, 2 = large
        bottomShelferPresentationManager.cornerRadius = 20
        bottomShelferPresentationManager.isDimmingViewEnabled = true
        bottomShelferPresentationManager.isDraggingEnabled = true
        bottomShelferPresentationManager.allowGrabbingNonScrollViews = false
        bottomShelferPresentationManager.dimmingColor = .black.withAlphaComponent(0.35)

        // Custom layout metrics — every default in BottomShelferLayout can be
        // overridden here, e.g. a wider sheet and a larger grabber pill.
        var layout = BottomShelferLayoutConfiguration()
        layout.maxSheetWidth = 500
        layout.grabberPillSize = CGSize(width: 60, height: 8)
        layout.grabberPillBottomOffset = 14
        bottomShelferPresentationManager.layoutConfiguration = layout
    }

    // MARK: UI

    private func buildUI() {
        contentLabel.text = "Drag the grabber, or use the buttons below."
        contentLabel.font = .systemFont(ofSize: 16, weight: .medium)
        contentLabel.textAlignment = .center
        contentLabel.numberOfLines = 0

        snapSmallButton.setTitle("Snap to small", for: .normal)
        snapSmallButton.addTarget(self, action: #selector(snapSmall), for: .touchUpInside)

        snapLargeButton.setTitle("Snap to large", for: .normal)
        snapLargeButton.addTarget(self, action: #selector(snapLarge), for: .touchUpInside)

        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [contentLabel, snapSmallButton, snapLargeButton, dismissButton])
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

    // MARK: Actions

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

// MARK: - Presenting it

final class HostViewController: UIViewController {

    @objc func showFilters() {
        let sheet = FiltersViewController()
        sheet.presentAsBottomShelfer(from: self, animated: true)
    }
}
