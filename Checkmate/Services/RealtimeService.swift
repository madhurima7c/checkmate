import Foundation
import Supabase

/// Subscribes to task changes so friends' apps update without push (works on free Apple account).
@MainActor
final class RealtimeService {
    static let shared = RealtimeService()

    private var channel: RealtimeChannelV2?
    private var listenTask: Task<Void, Never>?
    private var subscribed = false

    private init() {}

    func startIfNeeded() async {
        guard TaskStore.shared.usesCloud, !subscribed else { return }
        subscribed = true

        let client = SupabaseClient.shared
        let channel = client.channel("public:tasks")

        let stream = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "tasks"
        )

        try? await channel.subscribeWithError()

        listenTask = Task {
            for await _ in stream {
                guard !Task.isCancelled else { break }
                await TaskStore.shared.fetchTasks()
            }
        }

        self.channel = channel
    }

    func stop() async {
        listenTask?.cancel()
        listenTask = nil
        if let channel {
            await channel.unsubscribe()
        }
        channel = nil
        subscribed = false
    }
}
