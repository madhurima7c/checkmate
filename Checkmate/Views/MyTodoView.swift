import SwiftUI

struct MyTodoView: View {
    @StateObject private var store = TaskStore.shared
    @StateObject private var flight = AssignFlightCoordinator.shared

    /// Ensures launch-watch runs once per process (first open vs second open).
    private static var didRecordLaunchWatch = false

    @State private var dayOffset = 0
    @State private var showSettings = false
    @State private var showAddTodo = false
    @State private var editingTask: CheckmateTask?
    @State private var taskToDelete: CheckmateTask?
    @State private var selectedTab: AppTab = .myTodo
    @Namespace private var stickyNamespace

    private let dayRange = 0...14

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Palette.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .id(selectedTab)
            }

            bottomChrome
            AssignFlightOverlay()
        }
        .animation(Theme.spring, value: selectedTab)
        .task {
            await store.fetchTasks()
            if !Self.didRecordLaunchWatch {
                Self.didRecordLaunchWatch = true
                store.recordLaunchWatch()
            }
        }
        .sheet(isPresented: $showAddTodo) {
            AddTodoView(onSaved: handleSave)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingTask) { task in
            AddTodoView(editingTask: task, onSaved: handleSave)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Delete this todo?", isPresented: deleteAlertBinding) {
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    Task { await store.deleteTask(id: task.id) }
                }
                taskToDelete = nil
            }
            Button("Cancel", role: .cancel) { taskToDelete = nil }
        } message: {
            Text("This can’t be undone.")
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { taskToDelete != nil },
            set: { if !$0 { taskToDelete = nil } }
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .myTodo:
            myTodoPages
        case .friends:
            FriendsTabView(
                dayOffset: $dayOffset,
                namespace: stickyNamespace,
                onEdit: { editingTask = $0 },
                onDelete: { taskToDelete = $0 }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(selectedTab == .myTodo ? "My todo" : "Friends")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
            if selectedTab == .myTodo {
                Text(headerDateLabel)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.Palette.subtitle)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image("GearSix")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(BoopButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var headerDateLabel: String {
        if dayOffset == 0 { return "Today" }
        if dayOffset == 1 { return "Tomorrow" }
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f.string(from: Date.today.adding(days: dayOffset))
    }

    private var myTodoPages: some View {
        TabView(selection: $dayOffset) {
            ForEach(Array(dayRange), id: \.self) { offset in
                myTodoDayPage(offset: offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func myTodoDayPage(offset: Int) -> some View {
        let day = Date.today.adding(days: offset)
        let pending = store.myTodoPending(on: day)
        let completed = store.myTodoCompleted(on: day)
        let all = pending + completed

        if all.isEmpty && offset == 0 {
            ZStack(alignment: .topLeading) {
                EmptyStateView()
                Color.clear
                    .gridLandingMeasurement(tab: .myTodo)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if all.isEmpty {
            Spacer()
            Text("No todos this day")
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.dim)
            Spacer()
        } else {
            let progress = store.progress(on: day, tab: .myTodo)
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                    spacing: 10
                ) {
                    if pending.isEmpty {
                        Color.clear
                            .gridLandingMeasurement(tab: .myTodo)
                    }
                    ForEach(Array(pending.enumerated()), id: \.element.id) { index, task in
                        StickyNoteCardView(
                            task: task,
                            isNewBadge: store.isNew(task),
                            namespace: stickyNamespace,
                            onEdit: { editingTask = task },
                            onDelete: { taskToDelete = task }
                        )
                        .background {
                            if index == 0 {
                                GridLandingAnchor(tab: .myTodo)
                            }
                        }
                    }
                    ForEach(completed) { task in
                        StickyNoteCardView(
                            task: task,
                            namespace: stickyNamespace,
                            onEdit: { editingTask = task },
                            onDelete: { taskToDelete = task }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
            .overlay(alignment: .bottom) {
                if progress.total > 0 {
                    VStack(spacing: 6) {
                        LinearGradient(
                            colors: [Theme.Palette.canvas.opacity(0), Theme.Palette.canvas],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 56)
                        ProgressPill(done: progress.done, total: progress.total)
                    }
                    .allowsHitTesting(false)
                    .padding(.bottom, 88)
                }
            }
        }
    }

    private var bottomChrome: some View {
        HomeBottomBar(selectedTab: $selectedTab, onAdd: { showAddTodo = true })
    }

    // MARK: - Save + flight

    private func handleSave(_ payload: TodoSavePayload) {
        let destination: AppTab = payload.assignee.isMyself ? .myTodo : .friends

        if let editingId = payload.editingId {
            Task { await handleEditSave(payload, editingId: editingId, destination: destination) }
            return
        }

        flight.run(
            color: payload.color,
            text: payload.text,
            destination: destination,
            switchTab: { selectedTab = $0 }
        ) {
            Task {
                _ = try? await store.createTask(
                    text: payload.text,
                    color: payload.color,
                    dueDate: payload.dueDate,
                    allDay: payload.allDay,
                    dueAt: payload.dueAt,
                    assignee: payload.assignee
                )
                if case .person(let link) = payload.assignee, !link.isOnCheckmate {
                    await InviteService.shared.presentAssignInvite(for: link, taskText: payload.text)
                }
            }
        }
    }

    private func handleEditSave(_ payload: TodoSavePayload, editingId: UUID, destination: AppTab) async {
        do {
            let result = try await store.updateTask(
                id: editingId,
                text: payload.text,
                color: payload.color,
                dueDate: payload.dueDate,
                allDay: payload.allDay,
                dueAt: payload.dueAt,
                assignee: payload.assignee
            )
            if result.movedToFriends || result.movedToMyTodo {
                let dest: AppTab = result.movedToFriends ? .friends : .myTodo
                flight.run(
                    color: payload.color,
                    text: payload.text,
                    destination: dest,
                    switchTab: { selectedTab = $0 }
                ) { }
            } else if destination != selectedTab {
                withAnimation(Theme.spring) { selectedTab = destination }
            }
        } catch {
            // Task already updated in store on success path only
        }
    }
}

