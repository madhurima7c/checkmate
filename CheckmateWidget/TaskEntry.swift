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
                    id: UUID(), text: "Pick up milk",
                    senderId: UUID(), receiverId: UUID(),
                    dueDate: Date(), status: .pending,
                    isSeen: false, color: .yellow,
                    allDay: true, dueAt: nil, createdAt: Date(),
                    assigneeName: nil, inviteContact: nil
                ),
                CheckmateTask(
                    id: UUID(), text: "Connect with dentist",
                    senderId: UUID(), receiverId: nil,
                    dueDate: Date(), status: .pending,
                    isSeen: true, color: .pink,
                    allDay: true, dueAt: nil, createdAt: Date(),
                    assigneeName: nil, inviteContact: nil
                )
            ],
            doneCount: 1,
            totalCount: 3
        )
    }
}
