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
    @State private var focusedCardId: UUID?
    @State private var selectedTab: AppTab = .myTodo
    @State private var addSheetToken = 0
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
                .zIndex(20)
            AssignFlightOverlay()
                .zIndex(30)
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
            AddTodoView(onSaved: handleSave, resetToken: addSheetToken)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
                .presentationCornerRadius(48)
                .presentationBackground(Theme.Palette.canvas)
        }
        .sheet(item: $editingTask) { task in
            AddTodoView(editingTask: task, onSaved: handleSave, resetToken: addSheetToken)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
                .presentationCornerRadius(48)
                .presentationBackground(Theme.Palette.canvas)
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
        HStack(alignment: .center, spacing: 8) {
            Text(selectedTab == .myTodo ? "My todo" : "Friends")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
            if selectedTab == .myTodo || selectedTab == .friends {
                Text(TodoDayLabel.title(forOffset: dayOffset))
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Theme.Palette.subtitle)
                    .contentTransition(.numericText())
                    .id(dayOffset)
                    .animation(Theme.snappy, value: dayOffset)
            }
            Spacer()
            Button { showSettings = true } label: {
                FigmaIcon.gear(size: 28)
            }
            .buttonStyle(BoopButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 0)
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
        .animation(Theme.snappy, value: dayOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func myTodoDayPage(offset: Int) -> some View {
        let day = Date.today.adding(days: offset)
        let pending = store.myTodoPending(on: day)
        let completed = store.myTodoCompleted(on: day)
        let all = pending + completed

        if all.isEmpty {
            TodoEmptyDayPage(tab: .myTodo, showLandingAnchor: offset == 0)
        } else {
            ScrollEdgeFades {
                TodoTaskGrid(
                        pending: pending,
                        completed: completed,
                        tab: .myTodo,
                        isNew: { store.isNew($0) },
                        avatarName: myTodoAvatarName,
                        avatarData: myTodoAvatarData,
                        allowsEdit: { !$0.isIncomingFromOther },
                        onEdit: { task in
                            addSheetToken += 1
                            editingTask = task
                        },
                        onDelete: { taskToDelete = $0 },
                        focusedCardId: $focusedCardId
                    )
                .padding(.horizontal, 24)
            }
            .scrollDisabled(focusedCardId != nil)
        }
    }

    private var bottomChrome: some View {
        let day = Date.today.adding(days: dayOffset)
        let progress = store.progress(on: day, tab: selectedTab)
        return TodoListBottomChrome(
            done: progress.done,
            total: progress.total,
            selectedTab: $selectedTab,
            onAdd: {
                addSheetToken += 1
                showAddTodo = true
            }
        )
    }

    private func myTodoAvatarName(_ task: CheckmateTask) -> String? {
        guard task.isIncomingFromOther else { return nil }
        return FriendsStore.shared.displayName(forUserId: task.senderId) ?? "Friend"
    }

    private func myTodoAvatarData(_ task: CheckmateTask) -> Data? {
        guard task.isIncomingFromOther else { return nil }
        return FriendsStore.shared.friendLink(forUserId: task.senderId)?.avatarData
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

