import SwiftUI

/// Renders the actual Figma-exported asset-catalog icons.
struct FigmaIcon: View {
    let name: String
    var size: CGFloat = 28
    var renderingMode: Image.TemplateRenderingMode = .original
    var tint: Color? = nil

    var body: some View {
        Image(name)
            .renderingMode(renderingMode)
            .resizable()
            .scaledToFit()
            .foregroundStyle(tint ?? .primary)
            .frame(width: size, height: size)
    }
}

extension FigmaIcon {
    /// Figma 670:3070 — header settings control (28×28, #8C8C8C).
    static func gear(size: CGFloat = 28) -> FigmaIcon {
        FigmaIcon(name: "GearSix", size: size, renderingMode: .original)
    }

    static func noteTab(size: CGFloat = 27) -> FigmaIcon {
        FigmaIcon(name: "NoteBlank", size: size)
    }

    static func friendsTab(size: CGFloat = 27) -> FigmaIcon {
        FigmaIcon(name: "UsersTab", size: size)
    }

    static func addFAB(size: CGFloat = 25) -> FigmaIcon {
        FigmaIcon(name: "PlusFab", size: size)
    }

    static func actionTrash(size: CGFloat = 24) -> FigmaIcon {
        FigmaIcon(name: "ActionTrash", size: size)
    }

    static func actionPencil(size: CGFloat = 24) -> FigmaIcon {
        FigmaIcon(name: "ActionPencil", size: size)
    }
}
