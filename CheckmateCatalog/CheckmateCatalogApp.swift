import Prefire
import SwiftUI

@main
struct CheckmateCatalogApp: App {
    var body: some Scene {
        WindowGroup {
            PlaybookView(
                isComponent: true,
                previewModels: PreviewModels.models
            )
            .tint(Theme.Palette.selectionBlue)
        }
    }
}
