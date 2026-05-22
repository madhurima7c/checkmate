import SwiftUI
import UIKit

struct TodoSavePayload {
    let text: String
    let color: StickyColor
    let assignee: TaskAssignee
    let dueDate: Date
    let allDay: Bool
    let dueAt: Date?
    let editingId: UUID?
}

struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss

    var editingTask: CheckmateTask? = nil
    var onSaved: ((TodoSavePayload) -> Void)? = nil

    @State private var text = ""
    @State private var color: StickyColor = .yellow
    @StateObject private var friendsStore = FriendsStore.shared
    @State private var assignee: TaskAssignee = .myself
    @State private var showContactPicker = false
    @State private var dueOption: DueOption = .today
    @State private var customDate: Date = Date.today.adding(days: 2)
    @State private var allDay = true
    @State private var dueAt: Date = Date()
    @State private var showCustomDatePicker = false
    @State private var isSubmitting = false
    @State private var error: String?

    @FocusState private var textFocused: Bool

    enum DueOption: Equatable {
        case today, tomorrow, custom

        func date(custom: Date) -> Date {
            switch self {
            case .today: return Date.today
            case .tomorrow: return Date.today.adding(days: 1)
            case .custom: return custom
            }
        }
    }

    private var isEditing: Bool { editingTask != nil }

    var body: some View {
        ZStack {
            Theme.Palette.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 24) {
                        stickyEditor
                        colorRow
                        assignScheduleCard
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom) { confirmButton }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            VStack {
                DatePicker(
                    "Pick a date",
                    selection: $customDate,
                    in: Date.today...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                Button("Done") {
                    dueOption = .custom
                    showCustomDatePicker = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .presentationDetents([.medium])
        }
        .overlay {
            if showContactPicker {
                SystemContactPicker(
                    onPick: { link in
                        Task { await selectContact(link) }
                        showContactPicker = false
                    },
                    onCancel: { showContactPicker = false }
                )
                .ignoresSafeArea()
            }
        }
        .onAppear(perform: loadEditingState)
    }

    private func loadEditingState() {
        guard let task = editingTask else { return }
        text = task.text
        color = task.color
        assignee = TaskAssignee.from(task: task)
        allDay = task.allDay
        dueAt = task.dueAt ?? Date()
        let today = Date.today
        let tomorrow = today.adding(days: 1)
        if task.dueDate.startOfDay() == today {
            dueOption = .today
        } else if task.dueDate.startOfDay() == tomorrow {
            dueOption = .tomorrow
        } else {
            dueOption = .custom
            customDate = task.dueDate
        }
    }

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit todo" : "Add todo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(BoopButtonStyle())
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
    }

    private var stickyEditor: some View {
        ZStack {
            ColorSpreadCard(color: $color)
                .frame(width: 172, height: 176)

            ZStack {
                if text.isEmpty && !textFocused {
                    Button {
                        textFocused = true
                    } label: {
                        VStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Tap to write")
                                    .font(.system(size: 16))
                            }
                            .foregroundStyle(Theme.Palette.strike)
                            Spacer()
                        }
                        .frame(width: 172, height: 176)
                    }
                    .buttonStyle(.plain)
                }

                TextEditor(text: $text)
                    .focused($textFocused)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Palette.body)
                    .multilineTextAlignment(.center)
                    .opacity(text.isEmpty && !textFocused ? 0.01 : 1)
                    .frame(width: 172, height: 176)
            }

            if !assignee.isMyself, let link = assignee.friendLink {
                PersonAvatarView(name: link.name, imageData: link.avatarData, size: 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
            }
        }
    }

    private func selectContact(_ link: FriendLink) async {
        let enriched = await FriendLookupService.enrich(link)
        withAnimation(Theme.boop) { assignee = .person(enriched) }
        friendsStore.remember(enriched)
    }

    private var colorRow: some View {
        HStack(spacing: 7) {
            ForEach(StickyColor.allCases) { c in
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                        color = c
                    }
                } label: {
                    ZStack {
                        if c == color {
                            Circle()
                                .stroke(Theme.Palette.dark, lineWidth: 1.6)
                                .frame(width: 34, height: 34)
                        }
                        Circle()
                            .fill(c.dot)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2.4))
                            .frame(width: 30, height: 30)
                            .stickyShadow()
                    }
                }
                .buttonStyle(BoopButtonStyle())
            }
        }
    }

    /// Figma 573:2469 — Assign to + By when in one white card.
    private var assignScheduleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Assign to")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.dim)
                FlowLayout(spacing: 6) {
                    assignChip(.myself, link: nil)
                    ForEach(friendsStore.assignablePeople(includeDemos: CheckmateConfig.isPrototype)) { link in
                        assignChip(.person(link), link: link)
                    }
                    Button {
                        Task {
                            if await ContactsService.requestAccessIfNeeded() {
                                showContactPicker = true
                            }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(Theme.Palette.body)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(chipBackground(selected: false))
                    }
                    .buttonStyle(BoopButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 23)
            .padding(.bottom, 20)

            Divider()
                .background(Color(hex: 0xE8E8E8))
                .padding(.horizontal, 1)

            VStack(alignment: .leading, spacing: 12) {
                Text("By when")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.dim)
                HStack(spacing: 6) {
                    dueChip(option: .today, label: "Today", day: Date.today)
                    dueChip(option: .tomorrow, label: "Tomorrow", day: Date.today.adding(days: 1))
                    Button { showCustomDatePicker = true } label: {
                        HStack(spacing: 2) {
                            Text("Custom")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.Palette.body)
                        .padding(.leading, 6).padding(.trailing, 8)
                        .padding(.vertical, 6)
                        .background(chipBackground(selected: dueOption == .custom))
                    }
                    .buttonStyle(BoopButtonStyle())
                }
                HStack(spacing: 12) {
                    Text("All day")
                        .font(.system(size: 16, weight: .medium))
                    Toggle("", isOn: $allDay.animation(Theme.spring))
                        .labelsHidden()
                        .tint(Color(hex: 0x34C759))
                    if !allDay {
                        DatePicker("", selection: $dueAt, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 23)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous)
                        .stroke(Color.black.opacity(0.03), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }

    private func assignChip(_ target: TaskAssignee, link: FriendLink?) -> some View {
        let selected = assignee.id == target.id
        let label = link?.chipLabel ?? "Myself"
        return Button {
            withAnimation(Theme.boop) { assignee = target }
        } label: {
            HStack(spacing: 6) {
                if let link {
                    PersonAvatarView(name: link.name, imageData: link.avatarData, size: 18)
                } else {
                    PersonAvatarView(name: "Myself", size: 18)
                }
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Theme.Palette.body)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(chipBackground(selected: selected))
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func dueChip(option: DueOption, label: String, day: Date) -> some View {
        let isSelected = dueOption == option
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return Button {
            withAnimation(Theme.boop) { dueOption = option }
        } label: {
            HStack(spacing: 4) {
                CalendarGlyph(dayNumber: formatter.string(from: day))
                Text(label)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(Theme.Palette.body)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(chipBackground(selected: isSelected))
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func chipBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.chip)
            .fill(selected ? Color(hex: 0xF1F1F1) : .white)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.chip)
                    .stroke(selected ? Theme.Palette.dark.opacity(0.6) : Color(hex: 0xE3E3E3), lineWidth: 1)
            )
    }

    private var confirmButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Group {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Confirm")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pill, style: .continuous)
                    .fill(Theme.Palette.dark)
            )
        }
        .buttonStyle(BoopButtonStyle())
        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
        .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSubmitting = true
        let payload = TodoSavePayload(
            text: trimmed,
            color: color,
            assignee: assignee,
            dueDate: dueOption.date(custom: customDate),
            allDay: allDay,
            dueAt: allDay ? nil : dueAt,
            editingId: editingTask?.id
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved?(payload)
        dismiss()
        isSubmitting = false
    }
}

// MARK: - Color spread ("zoop") on sticky

struct ColorSpreadCard: View {
    @Binding var color: StickyColor
    @State private var displayed: StickyColor = .yellow
    @State private var spreadColor: StickyColor?
    @State private var spreadProgress: CGFloat = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
        ZStack(alignment: .bottom) {
            shape.fill(displayed.paper)
            if let spread = spreadColor {
                Ellipse()
                    .fill(spread.paper)
                    .frame(width: 220, height: 180 * spreadProgress + 1)
                    .offset(y: 90 * (1 - spreadProgress))
                    .mask(shape)
            }
        }
        .overlay(shape.strokeBorder(.white, lineWidth: Theme.Stroke.cardBorderLarge))
        .stickyShadow()
        .clipShape(shape)
        .onChange(of: color) { _, new in
            playSpread(to: new)
        }
        .onAppear { displayed = color }
    }

    private func playSpread(to new: StickyColor) {
        spreadColor = new
        spreadProgress = 0.001
        withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
            spreadProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            displayed = new
            spreadColor = nil
            spreadProgress = 0.001
        }
    }
}

// MARK: - Wrapping chip row

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var origins: [CGPoint] = []
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxW, x > 0 {
                x = 0
                y += rowH + spacing
                rowH = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowH = max(rowH, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxW, height: y + rowH), origins)
    }
}

struct CalendarGlyph: View {
    let dayNumber: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.Palette.body, lineWidth: 1.4)
                .frame(width: 16, height: 16)
            Rectangle()
                .fill(Theme.Palette.body)
                .frame(width: 16, height: 5)
                .offset(y: -5.5)
            Text(dayNumber)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(Theme.Palette.body)
                .offset(y: 2)
        }
        .frame(width: 18, height: 18)
    }
}
