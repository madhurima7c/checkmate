import Foundation

enum TodoDayLabel {
    static func title(forOffset offset: Int, from today: Date = Date.today) -> String {
        if offset == 0 { return "Today" }
        if offset == 1 { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        return formatter.string(from: today.adding(days: offset))
    }
}
