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

    private var canConfirm: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                            .padding(.top, 20)

                        assignScheduleCard
                            .padding(.top, 29)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ConfirmButtonChrome { confirmButton }
                }
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .dismissKeyboardOnTap {
            if keyboardVisible { dismissComposer() }
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
        .tracksKeyboardVisibility($keyboardVisible)
        .onAppear {
            friendsStore.cleanAddTodoAssigneesOnce()
            loadEditingState()
            KeyboardDismiss.resign()
        }
        .task {
            await friendsStore.refreshContactPhotos()
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

    /// Figma 573:2464 — four 30.156 dots, 6.52pt gap; selection ring 2pt #08f (573:2463),
    /// drawn just outside the dot so its inner edge meets the dot rim cleanly.
    private var colorRow: some View {
        HStack(spacing: 6.52) {
            ForEach(StickyColor.allCases) { c in
                Button {
                    dismissComposer()
                    withAnimation(Theme.colorFlip) { color = c }
                } label: {
                    ZStack {
                        Circle()
                            .fill(c.dot)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2.445))
                            .frame(width: 30.156, height: 30.156)
                            .modalColorDotShadow()

                        if c == color {
                            Circle()
                                .stroke(Theme.Palette.selectionBlue, lineWidth: 2)
                                .frame(width: 32.156, height: 32.156)
                        }
                    }
                    .frame(width: 32.156, height: 32.156)
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
                    .padding(.horizontal, 20)
                AssigneeCarousel(
                    assignee: $assignee,
                    people: friendsStore.assignablePeople(includeDemos: false),
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
            .padding(.top, 23)
            .padding(.bottom, 20)

            Rectangle()
                .fill(Color(hex: 0xEDEDED))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("By when")
                    .padding(.horizontal, 20)
                dueDateRow
                allDayRow
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom, 23)
        }
        .figmaPanelChrome()
    }

    /// Figma 573:2473 — Today / Tomorrow / Custom pill row.
    private var dueDateRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DueDateChipMetrics.pillSpacing) {
                dueChip(option: .today, label: "Today", day: Date.today)
                dueChip(option: .tomorrow, label: "Tomorrow", day: Date.today.adding(days: 1))
                customDueChip
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    private var allDayRow: some View {
        HStack(spacing: 12) {
            Text("All day")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Palette.body)
            FigmaSwitch(isOn: $allDay)
                .onChange(of: allDay) { _, _ in dismissComposer() }
            if !allDay {
                DatePicker("", selection: $dueAt, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(Theme.Palette.selectionBlue)
            }
            Spacer(minLength: 0)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.Palette.dim)
    }

    private var customDueChip: some View {
        let isSelected = dueOption == .custom
        return Button {
            dismissComposer()
            showCustomDatePicker = true
        } label: {
            dueChipLabel(isSelected: isSelected) {
                HStack(spacing: DueDateChipMetrics.customCaretGap) {
                    Text("Custom")
                        .font(DueDateChipMetrics.labelFont)
                    FigmaIcon(name: "CaretRight", size: 16)
                }
            }
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func dueChip(option: DueOption, label: String, day: Date) -> some View {
        let isSelected = dueOption == option
        return Button {
            dismissComposer()
            withAnimation(Theme.snappy) { dueOption = option }
        } label: {
            dueChipLabel(isSelected: isSelected) {
                HStack(spacing: DueDateChipMetrics.iconTextGap) {
                    CalendarGlyph(dayNumber: dayOfMonth(day))
                    Text(label)
                        .font(DueDateChipMetrics.labelFont)
                }
            }
        }
        .buttonStyle(BoopButtonStyle())
    }

    private func dueChipLabel<Content: View>(
        isSelected: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .foregroundStyle(Theme.Palette.body)
            .padding(.horizontal, DueDateChipMetrics.paddingX)
            .padding(.vertical, DueDateChipMetrics.paddingY)
            .frame(minHeight: DueDateChipMetrics.minHeight, alignment: .center)
            .background(chipBackground(selected: isSelected))
            .fixedSize(horizontal: true, vertical: false)
            .contentShape(
                RoundedRectangle(cornerRadius: DueDateChipMetrics.cornerRadius, style: .continuous)
            )
    }

    private func dayOfMonth(_ date: Date) -> String {
        String(Calendar.current.component(.day, from: date))
    }

    /// Figma 573:2474 selected — 1.6pt #08f; 573:2480/2486 unselected — 1pt #e3e3e3.
    private func chipBackground(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: DueDateChipMetrics.cornerRadius, style: .continuous)
            .fill(selected ? Theme.Palette.selectionFill : .white)
            .overlay(
                RoundedRectangle(cornerRadius: DueDateChipMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(
                        selected ? Theme.Palette.selectionBlue : Theme.Palette.chipBorder,
                        lineWidth: selected ? 1.6 : 1
                    )
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
                        .foregroundStyle(canConfirm ? .white : Color.white.opacity(0.72))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(canConfirm ? Theme.Palette.dark : Color(hex: 0xB5B5B5))
                    .tabBarShadow()
            )
        }
        .buttonStyle(BoopButtonStyle())
        .disabled(!canConfirm || isSubmitting)
        .padding(.horizontal, 24)
        .accessibilityHint(canConfirm ? "" : "Enter todo text to enable")
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
        let enriched = ContactsService.linkWithContactPhoto(
            await FriendLookupService.enrich(link)
        )
        withAnimation(Theme.snappy) { assignee = .person(enriched) }
        friendsStore.remember(enriched)
    }

    private func loadEditingState() {
        guard let task = editingTask else { return }
        text = task.text
        color = task.color
        var resolvedAssignee = TaskAssignee.from(task: task)
        if case .person(let link) = resolvedAssignee {
            resolvedAssignee = .person(ContactsService.linkWithContactPhoto(link))
        }
        assignee = resolvedAssignee
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
            .stickyShadow()
            .onChange(of: color) { _, new in
                withAnimation(Theme.colorFlip) { displayed = new }
            }
            .onAppear { displayed = color }
    }
}

extension View {
    /// Figma 573:2465 dot shadow: 0 1.63 7.335 0.815 rgba(0,0,0,0.07) + crisp 1px 3% outline.
    fileprivate func modalColorDotShadow() -> some View {
        shadow(color: .black.opacity(0.07), radius: 3.67, x: 0, y: 1.63)
            .shadow(color: .black.opacity(0.03), radius: 0.4, x: 0, y: 0)
    }
}

// MARK: - Figma 573:2473 due-date pills

private enum DueDateChipMetrics {
    /// Figma 573:2473 — 12pt between pills; each chip 573:2474/2480/2486 uses px 12, py 8.
    static let pillSpacing: CGFloat = 12
    static let paddingX: CGFloat = 12
    static let paddingY: CGFloat = 8
    static let iconTextGap: CGFloat = 4
    static let customCaretGap: CGFloat = 2
    static let cornerRadius: CGFloat = 12
    static let calendarSize: CGFloat = 18.601
    static var minHeight: CGFloat { calendarSize + paddingY * 2 }
    static let labelFont = Font.system(size: 16, weight: .medium)
}

/// Figma 573:2476 CalendarBlank — dark icon (#2f2f2f) + white day number; chip border shows selection.
struct CalendarGlyph: View {
    let dayNumber: String

    private let size: CGFloat = DueDateChipMetrics.calendarSize

    var body: some View {
        ZStack {
            FigmaIcon(name: "CalendarBlank", size: size)
            Text(dayNumber)
                .font(.system(size: 6.975, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: 2.5)
        }
        .frame(width: size, height: size)
    }
}
