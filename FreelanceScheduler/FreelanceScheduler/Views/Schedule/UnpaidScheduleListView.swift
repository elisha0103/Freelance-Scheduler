import SwiftUI

struct UnpaidScheduleListView: View {
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if scheduleVM.unpaidSchedules.isEmpty {
                    ContentUnavailableView("미정산 일정이 없습니다", systemImage: "checkmark.circle")
                } else {
                    List {
                        ForEach(scheduleVM.unpaidSchedules) { schedule in
                            NavigationLink {
                                ScheduleDetailView(schedule: schedule)
                            } label: {
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(schedule.category.color)
                                        .frame(width: 4)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(schedule.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        HStack(spacing: 4) {
                                            Text(schedule.startDate.formattedDate)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if let deadline = schedule.deadline {
                                                Text("→ \(deadline.formattedDate)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    if let amount = schedule.amount {
                                        Text("\(amount.formatted())원")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Image(systemName: "circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("미정산 일정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }
}
