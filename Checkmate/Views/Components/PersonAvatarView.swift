import SwiftUI
import UIKit

struct PersonAvatarView: View {
    let name: String
    var imageData: Data? = nil
    var size: CGFloat = 22

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private var tint: Color {
        let palette: [Color] = [
            Color(hex: 0xFFEEAE), Color(hex: 0xC7F0FF),
            Color(hex: 0xFFC7EC), Color(hex: 0xFFDEC7)
        ]
        let index = abs(name.hashValue) % palette.count
        return palette[index]
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
                            .font(.system(size: size * 0.42, weight: .semibold))
                            .foregroundStyle(Theme.Palette.body)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: max(1.5, size * 0.08)))
    }
}
