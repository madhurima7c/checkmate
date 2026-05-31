import WidgetKit
import Foundation

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [CheckmateTask]
    let doneCount: Int
    let totalCount: Int
}

extension TaskEntry {
    static var placeholder: TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: [
                CheckmateTask(
                    id: UUID(),
                    text: "Connect with dentist",
                    senderId: UUID(),
                    receiverId: UUID(),
                    dueDate: Date(),
                    status: .pending,
                    isSeen: true,
                    color: .blue,
                    allDay: true,
                    dueAt: nil,
                    createdAt: Date(),
                    assigneeName: "Alex",
                    inviteContact: nil,
                    widgetAvatarName: "Alex",
                    widgetAvatarImageData: nil
                ),
                CheckmateTask(
                    id: UUID(),
                    text: "Do grocery shopping",
                    senderId: UUID(),
                    receiverId: nil,
                    dueDate: Date(),
                    status: .pending,
                    isSeen: false,
                    color: .pink,
                    allDay: true,
                    dueAt: nil,
                    createdAt: Date(),
                    assigneeName: nil,
                    inviteContact: nil
                ),
                CheckmateTask(
                    id: UUID(),
                    text: "Pick up milk",
                    senderId: UUID(),
                    receiverId: nil,
                    dueDate: Date(),
                    status: .done,
                    isSeen: false,
                    color: .yellow,
                    allDay: true,
                    dueAt: nil,
                    createdAt: Date(),
                    assigneeName: nil,
                    inviteContact: nil
                )
            ],
            doneCount: 1,
            totalCount: 3
        )
    }

    static var largePlaceholder: TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: [
                CheckmateTask(
                    id: UUID(),
                    text: "Connect with dentist",
                    senderId: UUID(),
                    receiverId: UUID(),
                    dueDate: Date(),
                    status: .pending,
                    isSeen: false,
                    color: .blue,
                    allDay: true,
                    dueAt: nil,
                    createdAt: Date(),
                    assigneeName: "Alex",
                    inviteContact: nil,
                    widgetAvatarName: "Alex",
                    widgetAvatarImageData: nil
                ),
                CheckmateTask(
                    id: UUID(),
                    text: "Go shopping for party",
                    senderId: UUID(),
                    receiverId: nil,
                    dueDate: Date(),
                    status: .pending,
                    isSeen: true,
                    color: .pink,
                    allDay: true,
                    dueAt: nil,
                    createdAt: Date(),
                    assigneeName: nil,
                    inviteContact: nil
                ),
                CheckmateTask(
                    id: UUID(),
                    text: "Pick up milk",
                    senderId: UUID(),
                    receiverId: UUID(),
                    dueDate: Date(),
                    status: .done,
                    isSeen: true,
                    color: .yellow,
                    allDay: true,
                    dueAt: nil,
                    createdAt: Date(),
                    assigneeName: "Sam",
                    inviteContact: nil
                )
            ],
            doneCount: 1,
            totalCount: 3
        )
    }
}
