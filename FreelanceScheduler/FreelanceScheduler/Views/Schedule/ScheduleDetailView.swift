import SwiftUI
import MapKit

struct ScheduleDetailView: View {
    let schedule: Schedule

    @Environment(AuthViewModel.self) var authViewModel
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(GroupViewModel.self) var groupVM
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
                    Text(address).font(.subheadline)

                    // 지도 프리뷰
                    if let lat = schedule.latitude, let lng = schedule.longitude {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))) {
                            Marker(schedule.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                        }
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }

                    HStack(spacing: 16) {
                        Button {
                            openNaverMap()
                        } label: {
                            Label("네이버 지도", systemImage: "map")
                                .font(.subheadline)
                        }
                        Spacer()
                        ShareLink(item: shareAddressText) {
                            Label("주소 공유", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
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
                        let name = groupVM.members.first(where: { $0.id == id })?.nickname ?? id
                        Text(name).font(.subheadline)
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: shareScheduleText) {
                    Image(systemName: "square.and.arrow.up")
                }
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
                Task { await scheduleVM.deleteSchedule(schedule); HapticManager.success(); dismiss() }
            }
            Button("취소", role: .cancel) {}
        } message: { Text("이 일정을 삭제하시겠습니까?") }
    }

    // MARK: - 네이버 지도 열기 (앱 → 웹 fallback)
    private func openNaverMap() {
        let lat = schedule.latitude ?? 37.5665
        let lng = schedule.longitude ?? 126.9780
        let name = schedule.address?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let appURL = URL(string: "nmap://place?lat=\(lat)&lng=\(lng)&name=\(name)&appname=com.TaeYoungJin.FreelanceScheduler")!
        let webURL = URL(string: "https://map.naver.com/v5/search/\(name)?c=\(lng),\(lat),15,0,0,0,dh")!

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }

    // MARK: - 주소 공유 텍스트
    private var shareAddressText: String {
        let lat = schedule.latitude ?? 37.5665
        let lng = schedule.longitude ?? 126.9780
        let name = schedule.address?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "\(schedule.address ?? "")\nhttps://map.naver.com/v5/search/\(name)?c=\(lng),\(lat),15,0,0,0,dh"
    }

    // MARK: - 일정 전체 공유 텍스트
    private var shareScheduleText: String {
        var text = "[\(schedule.category.rawValue)] \(schedule.title)\n"
        text += "시작: \(schedule.startDate.formattedDateTime)\n"
        if let deadline = schedule.deadline {
            text += "마감: \(deadline.formattedDateTime)\n"
        }
        if let address = schedule.address, !address.isEmpty {
            text += "장소: \(address)\n"
        }
        if let amount = schedule.amount {
            text += "금액: \(amount.formatted())원\n"
        }
        if let desc = schedule.description, !desc.isEmpty {
            text += "메모: \(desc)\n"
        }
        return text
    }

    private func reloadSchedules() async {
        guard let user = authViewModel.currentUser, let groupId = user.groupId else { return }
        await scheduleVM.loadSchedules(groupId: groupId, authorId: user.id)
    }
}
