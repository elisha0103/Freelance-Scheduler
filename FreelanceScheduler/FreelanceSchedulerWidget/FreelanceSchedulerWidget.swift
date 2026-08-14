import WidgetKit
import SwiftUI

// MARK: - Shared Data (UserDefaults via App Group)
struct WidgetData: Codable {
    let todaySchedules: [WidgetScheduleItem]
    let monthIncome: Int
    let monthExpense: Int
    let monthName: String
}

struct WidgetScheduleItem: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let time: String
    let colorHex: String
}

// MARK: - Timeline Provider
struct ScheduleTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(ScheduleEntry(date: Date(), data: loadWidgetData() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let entry = ScheduleEntry(date: Date(), data: loadWidgetData() ?? .placeholder)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadWidgetData() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: "group.com.TaeYoungJin.FreelanceScheduler"),
              let data = defaults.data(forKey: "widgetData") else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }
}

// MARK: - Entry
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

extension WidgetData {
    static let placeholder = WidgetData(
        todaySchedules: [
            WidgetScheduleItem(id: "1", title: "미팅", category: "미팅/회의", time: "10:00", colorHex: "4A90D9"),
            WidgetScheduleItem(id: "2", title: "촬영", category: "촬영/현장", time: "14:00", colorHex: "F5A623")
        ],
        monthIncome: 3500000,
        monthExpense: 800000,
        monthName: "8월"
    )
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("오늘의 일정")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            if entry.data.todaySchedules.isEmpty {
                Spacer()
                Text("오늘 일정이 없습니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.data.todaySchedules.prefix(3)) { item in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 3, height: 14)
                        Text(item.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(item.time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if entry.data.todaySchedules.count > 3 {
                    Text("+\(entry.data.todaySchedules.count - 3)개")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: ScheduleEntry

    var body: some View {
        HStack(spacing: 12) {
            // 일정 섹션
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("오늘")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                if entry.data.todaySchedules.isEmpty {
                    Text("일정 없음")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.data.todaySchedules.prefix(3)) { item in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: item.colorHex))
                                .frame(width: 3, height: 14)
                            Text(item.title)
                                .font(.caption)
                                .lineLimit(1)
                            Text(item.time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 가계부 섹션
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "wonsign.circle")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(entry.data.monthName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("수입")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(entry.data.monthIncome.formatted())원")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Text("지출")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(entry.data.monthExpense.formatted())원")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }
                    Divider()
                    HStack {
                        Text("순이익")
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Spacer()
                        let net = entry.data.monthIncome - entry.data.monthExpense
                        Text("\(net.formatted())원")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(net >= 0 ? .blue : .red)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition
struct FreelanceSchedulerWidget: Widget {
    let kind: String = "FreelanceSchedulerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                SmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("프리랜서 스케줄러")
        .description("오늘의 일정과 이번 달 수입을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle
@main
struct FreelanceSchedulerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FreelanceSchedulerWidget()
    }
}

// MARK: - Color Extension for Widget
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
