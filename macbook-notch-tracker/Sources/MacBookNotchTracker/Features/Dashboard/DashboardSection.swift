import Foundation

struct DashboardSection: Identifiable, Hashable {
    let id: String
    let title: String
    let symbolName: String

    static let overview = DashboardSection(id: "overview", title: "Overview", symbolName: "square.grid.2x2")
    static let history = DashboardSection(id: "history", title: "History", symbolName: "clock.arrow.circlepath")
    static let insights = DashboardSection(id: "insights", title: "Insights", symbolName: "chart.bar")
    static let settings = DashboardSection(id: "settings", title: "Settings", symbolName: "slider.horizontal.3")
}

struct DashboardSectionRegistry {
    var sections: [DashboardSection]

    static let `default` = DashboardSectionRegistry(
        sections: [
            .overview,
            .history,
            .insights,
            .settings
        ]
    )
}
