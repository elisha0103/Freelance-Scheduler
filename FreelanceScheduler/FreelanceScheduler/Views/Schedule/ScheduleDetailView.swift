import SwiftUI

struct ScheduleDetailView: View {
    let schedule: Schedule

    @Environment(AuthViewModel.self) var authViewModel
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(\.dismiss) private var dismiss

    @State private var showEditForm = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            Section {
                LabeledContent("제목", value: schedule.title)
                LabeledContent("카테고리") {
                    HStack(spacing: 4) {
                        Circle().fill(schedule.category.color).frame(width: 10, height: 10)
                        Text(schedule.category.rawValue)
                    }
                }
                LabeledContent("유형", value: schedule.isGroupSchedule ? "그룹 일정" : "개인 일정")
            }
            Section("시간") {
                LabeledContent("시작", value: schedule.startDate.formattedDateTime)
                if let deadline = schedule.deadline {
                    LabeledContent("마감", value: deadline.formattedDateTime)
                }
            }
            if let address = schedule.address, !address.isEmpty {
                Section("장소") {
                    HStack {
                        Text(address).font(.subheadline)
                        Spacer()
                        ShareLink(item: naverMapURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            if let amount = schedule.amount {
                Section { LabeledContent("금액", value: "\(amount.formatted())원") }
            }
            if !schedule.companions.isEmpty {
                Section("동행인") {
                    ForEach(schedule.companions, id: \.self) { id in
                        Text(id).font(.subheadline)
                    }
                }
            }
            if let desc = schedule.description, !desc.isEmpty {
                Section("설명") { Text(desc).font(.subheadline) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("일정 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("편집") { showEditForm = true }
                    Button("삭제", role: .destructive) { showDeleteAlert = true }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .fullScreenCover(isPresented: $showEditForm) {
            ScheduleFormView(mode: .edit(schedule)) { await reloadSchedules() }
        }
        .alert("일정 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                Task { await scheduleVM.deleteSchedule(schedule); dismiss() }
            }
            Button("취소", role: .cancel) {}
        } message: { Text("이 일정을 삭제하시겠습니까?") }
    }

    private var naverMapURL: URL {
        let lat = schedule.latitude ?? 37.5665
        let lng = schedule.longitude ?? 126.9780
        let name = schedule.address?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "nmap://place?lat=\(lat)&lng=\(lng)&name=\(name)&appname=com.TaeYoungJin.FreelanceScheduler")
            ?? URL(string: "https://map.naver.com")!
    }

    private func reloadSchedules() async {
        guard let user = authViewModel.currentUser, let groupId = user.groupId else { return }
        await scheduleVM.loadSchedules(groupId: groupId, authorId: user.id)
    }
}
