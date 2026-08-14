import SwiftUI

enum ScheduleFormMode {
    case create
    case edit(Schedule)
}

struct ScheduleFormView: View {
    let mode: ScheduleFormMode
    var initialDate: Date?
    var onSave: (() async -> Void)?

    @Environment(AuthViewModel.self) var authViewModel
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(GroupViewModel.self) var groupVM
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: ScheduleCategory = .other
    @State private var isGroupSchedule = false
    @State private var startDate = Date()
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var address = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var amountText = ""
    @State private var selectedCompanions: Set<String> = []
    @State private var descriptionText = ""
    @State private var showPlaceSearch = false
    @State private var showValidationError = false
    @State private var showDeleteAlert = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("일정 제목 (필수)", text: $title)
                        .overlay(alignment: .trailing) {
                            if showValidationError && title.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                            }
                        }
                        .onChange(of: title) { if title.count > 30 { title = String(title.prefix(30)) } }
                    Picker("카테고리", selection: $category) {
                        ForEach(ScheduleCategory.allCases) { cat in
                            HStack { Circle().fill(cat.color).frame(width: 10, height: 10); Text(cat.rawValue) }.tag(cat)
                        }
                    }
                    Toggle("그룹 일정", isOn: $isGroupSchedule)
                }
                Section("일시") {
                    DatePicker("시작 날짜/시간", selection: $startDate)
                    Toggle("마감일 설정", isOn: $hasDeadline)
                    if hasDeadline { DatePicker("마감일", selection: $deadline) }
                }
                Section("장소") {
                    HStack {
                        Text(address.isEmpty ? "장소를 선택하세요" : address)
                            .foregroundStyle(address.isEmpty ? .secondary : .primary).font(.subheadline)
                        Spacer()
                        Button("검색") { showPlaceSearch = true }.font(.subheadline)
                    }
                }
                Section("금액") {
                    TextField("금액 (선택)", text: $amountText).keyboardType(.numberPad)
                }
                Section("동행인") {
                    let otherMembers = groupVM.members.filter { $0.id != authViewModel.currentUser?.id }
                    if otherMembers.isEmpty {
                        Text("그룹에 다른 멤버가 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherMembers) { member in
                            HStack {
                                Text(member.nickname)
                                Spacer()
                                if selectedCompanions.contains(member.id) {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedCompanions.contains(member.id) { selectedCompanions.remove(member.id) }
                                else { selectedCompanions.insert(member.id) }
                            }
                        }
                    }
                }
                Section("설명") {
                    TextEditor(text: $descriptionText).frame(minHeight: 80)
                        .onChange(of: descriptionText) { if descriptionText.count > 500 { descriptionText = String(descriptionText.prefix(500)) } }
                    Text("\(descriptionText.count)/500").font(.caption).foregroundStyle(.secondary)
                }
                if isEditing {
                    Section { Button("삭제", role: .destructive) { showDeleteAlert = true } }
                }
            }
            .navigationTitle(isEditing ? "일정 편집" : "일정 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(isEditing ? "수정" : "등록") { Task { await save() } } }
            }
            .sheet(isPresented: $showPlaceSearch) {
                PlaceSearchView { place in
                    address = place.roadAddress.isEmpty ? place.address : place.roadAddress
                    latitude = place.mapy; longitude = place.mapx
                }
            }
            .alert("일정 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) { Task { await deleteAndDismiss() } }
                Button("취소", role: .cancel) {}
            } message: { Text("이 일정을 삭제하시겠습니까?") }
            .onAppear {
                loadEditData()
                if let groupId = authViewModel.currentUser?.groupId {
                    Task { await groupVM.loadGroup(groupId: groupId) }
                }
            }
        }
    }

    private func loadEditData() {
        if case .edit(let schedule) = mode {
            title = schedule.title; category = schedule.category; isGroupSchedule = schedule.isGroupSchedule
            startDate = schedule.startDate; hasDeadline = schedule.deadline != nil
            deadline = schedule.deadline ?? Date(); address = schedule.address ?? ""
            latitude = schedule.latitude; longitude = schedule.longitude
            amountText = schedule.amount.map { String($0) } ?? ""
            selectedCompanions = Set(schedule.companions); descriptionText = schedule.description ?? ""
        } else if let initialDate { startDate = initialDate }
    }

    private func save() async {
        guard !title.isEmpty else { showValidationError = true; return }
        guard let user = authViewModel.currentUser, let groupId = user.groupId else { return }
        let existingId: String
        if case .edit(let s) = mode { existingId = s.id } else { existingId = UUID().uuidString }
        let schedule = Schedule(
            id: existingId, title: title, category: category, isGroupSchedule: isGroupSchedule,
            startDate: startDate, deadline: hasDeadline ? deadline : nil,
            address: address.isEmpty ? nil : address, latitude: latitude, longitude: longitude,
            amount: Int(amountText), companions: Array(selectedCompanions),
            description: descriptionText.isEmpty ? nil : descriptionText,
            authorId: user.id, groupId: groupId
        )
        await scheduleVM.saveSchedule(schedule); await onSave?(); dismiss()
    }

    private func deleteAndDismiss() async {
        if case .edit(let s) = mode { await scheduleVM.deleteSchedule(s); await onSave?() }
        dismiss()
    }
}

struct PlaceSearchView: View {
    var onSelect: (NaverPlace) -> Void
    @State private var query = ""
    @State private var results: [NaverPlace] = []
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("장소 검색", text: $query).textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await search() } }
                    Button("검색") { Task { await search() } }
                }.padding(.horizontal)
                if isSearching { ProgressView().padding() }
                List(results) { place in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.title).font(.subheadline).fontWeight(.medium)
                        Text(place.roadAddress.isEmpty ? place.address : place.roadAddress)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(place); dismiss() }
                }.listStyle(.plain)
            }
            .navigationTitle("장소 검색").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
    }

    private func search() async {
        isSearching = true; defer { isSearching = false }
        do { results = try await NaverSearchService.shared.searchPlaces(query: query) } catch { results = [] }
    }
}
