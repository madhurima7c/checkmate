import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let tray = ComposerTrayView { [weak self] in
            guard let self else { return }
            // Composer flow lands here next; for now toggle presentation so the tap is alive.
            requestPresentationStyle(presentationStyle == .compact ? .expanded : .compact)
        }

        let host = UIHostingController(rootView: tray)
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }
}
