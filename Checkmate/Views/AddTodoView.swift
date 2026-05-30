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

/// Figma iPhone 16 & 17 Pro - 30 (573:2413) — Add todo sheet.
struct AddTodoView: View {
    @Environment(\.dismiss) private var dismiss

    var editingTask: CheckmateTask? = nil
    var onSaved: ((TodoSavePayload) -> Void)? = nil
    var resetToken: Int = 0

    @State private var text = ""
    @State private var keyboardVisible = false
    @State private var composerDismissToken = 0
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        stickySection
                            .padding(.top, 28)

                        colorRow
                            .padding(.top, 22)

                        assignScheduleCard
                            .padding(.top, 58)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, keyboardVisible ? 24 : 108)
                }
                .scrollDismissesKeyboard(.interactively)

                if !keyboardVisible, !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    ConfirmButtonChrome { confirmButton }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            customDateSheet
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
        .animation(Theme.snappy, value: keyboardVisible)
        .tracksKeyboardVisibility($keyboardVisible)
        .onAppear {
            loadEditingState()
            KeyboardDismiss.resign()
        }
        .onChange(of: resetToken) { _, _ in
            text = editingTask?.text ?? ""
            keyboardVisible = false
            composerDismissToken += 1
            KeyboardDismiss.resign()
        }
    }

    private func dismissComposer() {
        composerDismissToken += 1
        KeyboardDismiss.resign()
    }

    // MARK: - Header (573:2452–2453)

    private var header: some View {
        ZStack {
            Text(isEditing ? "Edit todo" : "Add todo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)

            HStack {
                Button { dismiss() } label: {
                    FigmaIcon(name: "CaretLeft", size: 24)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(BoopButtonStyle())
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Sticky preview (573:2513)

    private var stickySection: some View {
        ZStack(alignment: .topTrailing) {
            ColorFlipCard(color: $color)
                .frame(width: 172, height: 176)
                .allowsHitTesting(false)

            BottomAnchoredTextEditor(
                text: $text,
                placeholderIcon: "TapToWritePlus",
                resetToken: resetToken,
                dismissToken: composerDismissToken,
                onWritingActiveChanged: { _ in }
            )
            .frame(width: 172, height: 176)

            if !assignee.isMyself, let link = assignee.friendLink {
                PersonAvatarView(name: link.name, imageData: link.avatarData, size: 28)
                    .padding(12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Theme.snappy, value: assignee.id)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Color dots (573:2462–2468)

    private var colorRow: some View {
        HStack(spacing: 6.5) {
            ForEach(StickyColor.allCases) { c in
                Button {
                    dismissComposer()
                    withAnimation(Theme.colorFlip) { color = c }
                } label: {
                    ZStack {
                        if c == color {
                            Circle()
                                .stroke(Color(hex: 0x32312F), lineWidth: 1.63)
                                .frame(width: 31.8, height: 31.8)
                        }
                        Circle()
                            .fill(c.dot)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2.45))
                            .frame(width: 30.2, height: 30.2)
                            .modalColorDotShadow()
                    }
                }
                .buttonStyle(BoopButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Assign + schedule card (573:2469)

    private var assignScheduleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("Assign to")
                AssigneeCarousel(
                    assignee: $assignee,
                    people: friendsStore.assignablePeople(includeDemos: CheckmateConfig.isPrototype),
                    onAdd: {
                        dismissComposer()
                        Task {
                            if await ContactsService.requestAccessIfNeeded() {
                                showContactPicker = true
                            }
                        }
                    },
                    onInteract: dismissComposer
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 23)
            .padding(.bottom, 20)

            Rectangle()
                .fill(Color(hex: 0xE8E8E8))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("By when")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        dueChip(option: .today, label: "Today", day: Date.today)
                        dueChip(option: .tomorrow, label: "Tomorrow", day: Date.today.adding(days: 1))
                        customDueChip
                    }
                }
                HStack(spacing: 12) {
                    Text("All day")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Palette.body)
                    Toggle("", isOn: $allDay.animation(Theme.spring))
                        .onChange(of: allDay) { _, _ in dismissComposer() }
                        .labelsHidden()
                        .tint(Color(hex: 0x34C759))
                    if !allDay {
                        DatePicker("", selection: $dueAt, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 23)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.03), lineWidth: 1)
                )
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.Palette.dim)
    }

    private var customDueChip: some View {
        Button {
            dismissComposer()
            showCustomDatePicker = true
        } label: {
            HStack(spacing: 2) {
                Text("Custom")
                    .font(.system(size: 16, weight: .medium))
                FigmaIcon(name: "CaretRight", size: 16)
            }
            .foregroundStyle(Theme.Palette.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(chipBackground(selected: dueOption == .custom))
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func dueChip(option: DueOption, label: String, day: Date) -> some View {
        let isSelected = dueOption == option
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return Button {
            dismissComposer()
            withAnimation(Theme.snappy) { dueOption = option }
        } label: {
            HStack(spacing: 4) {
                CalendarGlyph(dayNumber: formatter.string(from: day), selected: isSelected)
                Text(label)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(Theme.Palette.body)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(chipBackground(selected: isSelected))
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func chipBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(selected ? Theme.Palette.selectionFill : .white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? Theme.Palette.selectionBlue : Theme.Palette.chipBorder, lineWidth: 1)
            )
    }

    // MARK: - Confirm (573:2460–2461)

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
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(Theme.Palette.dark)
                    .tabBarShadow()
            )
        }
        .buttonStyle(BoopButtonStyle())
        .disabled(isSubmitting)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private var customDateSheet: some View {
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
            .tint(Theme.Palette.selectionBlue)
            .padding(.bottom)
        }
        .presentationDetents([.medium])
    }

    private func selectContact(_ link: FriendLink) async {
        let enriched = await FriendLookupService.enrich(link)
        withAnimation(Theme.snappy) { assignee = .person(enriched) }
        friendsStore.remember(enriched)
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

    private func submit() async {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dismissComposer()
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

// MARK: - Sticky preview card (573:2513)

struct ColorFlipCard: View {
    @Binding var color: StickyColor
    @State private var displayed: StickyColor = .yellow

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        shape
            .fill(displayed.paper)
            .overlay(shape.strokeBorder(.white, lineWidth: 6))
            .modalStickyShadow()
            .onChange(of: color) { _, new in
                withAnimation(Theme.colorFlip) { displayed = new }
            }
            .onAppear { displayed = color }
    }
}

extension View {
    fileprivate func modalColorDotShadow() -> some View {
        shadow(color: .black.opacity(0.07), radius: 7.3, x: 0, y: 1.6)
            .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 0)
    }
}

struct CalendarGlyph: View {
    let dayNumber: String
    var selected: Bool = false

    private var ink: Color { selected ? Theme.Palette.selectionBlue : Theme.Palette.body }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(ink, lineWidth: 1.4)
                .frame(width: 16, height: 16)
            Rectangle()
                .fill(ink)
                .frame(width: 16, height: 5)
                .offset(y: -5.5)
            Text(dayNumber)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(selected ? .white : ink)
                .offset(y: 2)
        }
        .frame(width: 18, height: 18)
    }
}
