import SwiftUI
import UIKit

/// Figma 598:2632 — assign-to-contacts dial. Avatars ride a big arc; dragging
/// spins them like a dial. Selection ring only appears when someone is centered;
/// a slow auto-scroll ping-pongs between ends until the user takes over.
struct OnboardingAssignPage: View {
    @Environment(\.onboardingAssignTuning) private var tuning

    /// Index 0 sits at the far right of the arc, the last index at the far
    /// left — matching Figma (Emily far left … Peggy far right).
    private static let people: [OnboardingPerson] = [
        OnboardingPerson(name: "Peggy", initials: "PP", fill: Color(hex: 0xFFC0AC), ink: Color(hex: 0xFF5E2D)),
        OnboardingPerson(name: "Victor", imageName: "OnboardingAvatarVictor"),
        OnboardingPerson(name: "Sarah", imageName: "OnboardingAvatarSarah"),
        OnboardingPerson(name: "Myself", imageName: "OnboardingAvatarMyself"),
        OnboardingPerson(name: "Emily", initials: "ES", fill: Color(hex: 0xFFD744), ink: Color(hex: 0xB38C00))
    ]

    /// Index whose rest position is dead center (Sarah).
    private static let centerIndex = 2

    private var maxDial: Double { tuning.avatarSpacing * Double(Self.centerIndex) }
    private var minDial: Double { -tuning.avatarSpacing * Double(Self.people.count - 1 - Self.centerIndex) }

    @State private var dialAngle: Double = 0
    @State private var dragStartAngle: Double?
    @State private var cardAssignee: Int = OnboardingAssignPage.centerIndex
    @State private var autoDialTask: Task<Void, Never>?
    @State private var userInteracting = false

    private var snapAnimation: Animation {
        .spring(response: tuning.snapResponse, dampingFraction: tuning.snapDamping)
    }

    private var selectAnimation: Animation {
        .spring(response: tuning.selectResponse, dampingFraction: tuning.selectDamping)
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            ZStack {
                arcs(centerX: centerX)
                avatars(centerX: centerX)
                stickyCard
                    .position(x: centerX, y: tuning.stickyCardY)
            }
            .contentShape(Rectangle())
            .gesture(dialGesture)
        }
        .onAppear { startAutoDial() }
        .onDisappear { autoDialTask?.cancel() }
        .onChange(of: dialAngle) { _, _ in
            if let centered = centeredIndex() {
                cardAssignee = centered
            }
        }
    }

    // MARK: - Arcs

    private func arcs(centerX: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.39), lineWidth: CGFloat(tuning.arcStrokeWidth))
                .opacity(tuning.arcStrokeOpacity)
                .frame(width: tuning.outerArcRadius * 2, height: tuning.outerArcRadius * 2)
            Circle()
                .stroke(Color.black.opacity(0.39), lineWidth: CGFloat(tuning.arcStrokeWidth))
                .opacity(tuning.arcStrokeOpacity)
                .frame(width: tuning.innerArcRadius * 2, height: tuning.innerArcRadius * 2)
        }
        .position(x: centerX, y: tuning.dialCenterY)
    }

    // MARK: - Avatars on the dial

    private func avatars(centerX: CGFloat) -> some View {
        let highlighted = centeredIndex()
        return ForEach(Array(Self.people.enumerated()), id: \.element.id) { index, person in
            let angle = Angle.degrees(
                tuning.restAngle + tuning.avatarSpacing * Double(index - Self.centerIndex) + dialAngle
            )
            let x = centerX + tuning.orbitRadius * cos(angle.radians)
            let y = tuning.dialCenterY + tuning.orbitRadius * sin(angle.radians)

            OnboardingDialAvatar(person: person, selected: index == highlighted, tuning: tuning)
                .position(x: x, y: y)
                .onTapGesture {
                    userInteracting = true
                    autoDialTask?.cancel()
                    snap(to: index)
                    userInteracting = false
                    startAutoDial(after: 1.2)
                }
        }
    }

    private var dialGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                userInteracting = true
                autoDialTask?.cancel()
                if dragStartAngle == nil {
                    dragStartAngle = dialAngle
                }
                let delta = -Double(value.translation.width / tuning.orbitRadius) * 180 / .pi
                var next = (dragStartAngle ?? 0) + delta

                if next > maxDial {
                    next = maxDial + (next - maxDial) * tuning.rubberBand
                } else if next < minDial {
                    next = minDial + (next + minDial) * tuning.rubberBand
                }
                dialAngle = next
            }
            .onEnded { _ in
                dragStartAngle = nil
                snap(to: nearestIndex())
                userInteracting = false
                startAutoDial(after: 1.2)
            }
    }

    /// Only returns an index when an avatar is actually centered — not merely nearest.
    private func centeredIndex() -> Int? {
        let raw = Double(Self.centerIndex) - dialAngle / tuning.avatarSpacing
        let rounded = raw.rounded()
        guard abs(raw - rounded) < tuning.centerSnapTolerance else { return nil }
        return min(max(0, Int(rounded)), Self.people.count - 1)
    }

    private func nearestIndex() -> Int {
        let raw = Double(Self.centerIndex) - dialAngle / tuning.avatarSpacing
        return min(Self.people.count - 1, max(0, Int(raw.rounded())))
    }

    private func snap(to index: Int, animated: Bool = true) {
        let target = tuning.avatarSpacing * Double(Self.centerIndex - index)
        let apply = {
            dialAngle = target
            cardAssignee = index
        }
        if animated {
            withAnimation(snapAnimation, apply)
        } else {
            apply()
        }
    }

    // MARK: - Auto dial

    private func startAutoDial(after delay: Double = 0.6) {
        autoDialTask?.cancel()
        autoDialTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            var direction = 1
            var current = nearestIndex()

            while !Task.isCancelled {
                guard !userInteracting else {
                    try? await Task.sleep(for: .milliseconds(200))
                    continue
                }

                try? await Task.sleep(for: .seconds(tuning.autoDialStepDelay))
                guard !Task.isCancelled, !userInteracting else { continue }

                let next = current + direction
                guard next >= 0, next < Self.people.count else {
                    direction *= -1
                    continue
                }

                snap(to: next)
                current = next

                let atEmilyEnd = direction > 0 && current >= Self.people.count - 2
                let atPeggyEnd = direction < 0 && current <= 1
                if atEmilyEnd || atPeggyEnd {
                    try? await Task.sleep(for: .seconds(tuning.autoDialPauseDuration))
                    direction *= -1
                }
            }
        }
    }

    // MARK: - Sticky card (Figma 2049:2879)

    private var stickyCard: some View {
        let shape = RoundedRectangle(cornerRadius: CGFloat(tuning.stickyCornerRadius), style: .continuous)
        let checkboxScale = tuning.stickyCheckboxSize / 20
        return ZStack(alignment: .topLeading) {
            Color(dialHex: tuning.stickyPaperHex)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 7.16 * checkboxScale, style: .continuous)
                        .stroke(Theme.Palette.checkboxStroke, lineWidth: 1.8)
                        .frame(width: tuning.stickyCheckboxSize, height: tuning.stickyCheckboxSize)
                    Spacer()
                    cardAvatar
                        .padding(.top, -2)
                        .padding(.trailing, -4)
                }
                Spacer(minLength: 0)
                Text("Pick up milk")
                    .font(.system(size: tuning.stickyTextSize, weight: .medium))
                    .foregroundStyle(Theme.Palette.body)
            }
            .padding(.horizontal, 23)
            .padding(.top, 23)
            .padding(.bottom, 22)
        }
        .frame(width: tuning.stickyCardWidth, height: tuning.stickyCardHeight)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white, lineWidth: CGFloat(tuning.stickyBorderWidth)))
        .stickyShadow()
    }

    private var cardAvatar: some View {
        ZStack {
            OnboardingAvatarFace(person: Self.people[cardAssignee], size: CGFloat(tuning.stickyAvatarSize))
                .id(cardAssignee)
                .transition(.scale(scale: tuning.avatarTransitionScale).combined(with: .opacity))
        }
        .animation(Theme.boop, value: cardAssignee)
        .overlay(Circle().stroke(Color.white.opacity(0.91), lineWidth: 1.19))
        .shadow(color: .black.opacity(0.1), radius: 0.6)
    }
}

// MARK: - Person model

struct OnboardingPerson: Identifiable {
    let id = UUID()
    let name: String
    var imageName: String?
    var initials: String?
    var fill: Color?
    var ink: Color?

    init(name: String, imageName: String) {
        self.name = name
        self.imageName = imageName
    }

    init(name: String, initials: String, fill: Color, ink: Color) {
        self.name = name
        self.initials = initials
        self.fill = fill
        self.ink = ink
    }
}

/// Round face: photo/memoji asset, or tinted circle with initials.
struct OnboardingAvatarFace: View {
    let person: OnboardingPerson
    let size: CGFloat

    var body: some View {
        Group {
            if let imageName = person.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(person.fill ?? Theme.Palette.chipBorder)
                    .overlay(
                        Text(person.initials ?? "")
                            .font(.system(size: size * 0.35, weight: .medium))
                            .foregroundStyle(person.ink ?? Theme.Palette.body)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

/// Figma 2049:2841 — dial avatar with the Add-todo carousel's selection
/// treatment: white halo + 2pt blue ring + rim badge, name label beneath.
private struct OnboardingDialAvatar: View {
    let person: OnboardingPerson
    let selected: Bool
    let tuning: OnboardingAssignTuning

    private var avatarSize: CGFloat { CGFloat(tuning.avatarSize) }
    private var selectionGap: CGFloat { CGFloat(tuning.selectionGap) }
    private var selectionStrokeWidth: CGFloat { CGFloat(tuning.selectionStroke) }
    private var badgeSize: CGFloat { CGFloat(tuning.badgeSize) }
    private var whiteRingDiameter: CGFloat { avatarSize + selectionGap * 2 }
    private var selectionRingDiameter: CGFloat { whiteRingDiameter + selectionStrokeWidth }
    private var checkIconSize: CGFloat { badgeSize * (6.158 / 15.674) }

    var body: some View {
        ZStack {
            if selected {
                Circle()
                    .fill(Color.white)
                    .frame(width: whiteRingDiameter, height: whiteRingDiameter)
                Circle()
                    .stroke(
                        Color(dialHex: tuning.selectionHex),
                        style: StrokeStyle(lineWidth: selectionStrokeWidth, lineCap: .round)
                    )
                    .frame(width: selectionRingDiameter, height: selectionRingDiameter)
            }

            OnboardingAvatarFace(person: person, size: avatarSize)
                .overlay {
                    if person.imageName == nil {
                        Circle().stroke(Color.black.opacity(0.12), lineWidth: 1.12)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    badge.offset(x: -selectionGap, y: selectionGap)
                }
        }
        .frame(width: selectionRingDiameter, height: selectionRingDiameter)
        .overlay(alignment: .bottom) {
            Text(person.name)
                .font(.system(size: tuning.nameSize, weight: .medium))
                .foregroundStyle(Theme.Palette.assignLabelMuted)
                .lineLimit(1)
                .fixedSize()
                .offset(y: tuning.nameOffsetY)
        }
        .animation(
            .spring(response: tuning.selectResponse, dampingFraction: tuning.selectDamping),
            value: selected
        )
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(selected ? Color(dialHex: tuning.selectionHex) : .white)
                .overlay(
                    Circle().stroke(Color.black.opacity(selected ? 0.06 : 0.12), lineWidth: 1.12)
                )
            if selected {
                FigmaIcon(name: "AssignCheck", size: checkIconSize)
            }
        }
        .frame(width: badgeSize, height: badgeSize)
    }
}
