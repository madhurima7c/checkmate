import SwiftUI
import UIKit

struct PersonAvatarView: View {
    let name: String
    var imageData: Data? = nil
    var size: CGFloat = 22
    var showsBorder: Bool = true

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        if let first = parts.first {
            return String(first.prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private static let avatarTints: [(bg: UInt32, ink: UInt32)] = [
        (0xFFEEAE, 0xB38C00), // Figma 671:3078 / 671:3089
        (0xC7F0FF, 0x4A8FA8),
        (0xFFC7EC, 0xC45E9E),
        (0xFFDEC7, 0xC98A52)
    ]

    private var tint: Color {
        let pair = Self.avatarTints[abs(name.hashValue) % Self.avatarTints.count]
        return Color(hex: pair.bg)
    }

    private var initialsColor: Color {
        let pair = Self.avatarTints[abs(name.hashValue) % Self.avatarTints.count]
        return Color(hex: pair.ink)
    }

    var body: some View {
        Group {
            if let imageData, let ui = UIImage(data: imageData) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(tint)
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.35, weight: .medium))
                            .foregroundStyle(initialsColor)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showsBorder {
                Circle().stroke(Color.white, lineWidth: max(1.5, size * 0.08))
            }
        }
    }
}
