import SwiftUI

enum AccountBookFormMode: Identifiable {
    case create
    case edit(AccountBook)
    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let item): return item.id
        }
    }
}

struct AccountBookFormView: View {
    let mode: AccountBookFormMode
    var initialDate: Date?
    var onSave: (() async -> Void)?

    @Environment(AuthViewModel.self) var authViewModel
    @Environment(AccountBookViewModel.self) var accountBookVM
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var type: IncomeExpense = .income
    @State private var amountText = ""
    @State private var hasTax = false
    @State private var useDefaultTax = true
    @State private var customTaxRateText = ""
    @State private var memo = ""
    @State private var expenseCategory: ExpenseCategory = .other
    @State private var showValidationError = false
    @State private var showDeleteAlert = false

    private var isEditing: Bool { if case .edit = mode { return true }; return false }
    private var amount: Int { Int(amountText) ?? 0 }
    private var taxRate: Double { useDefaultTax ? 3.3 : (Double(customTaxRateText) ?? 0) }
    private var taxAmount: Int { guard hasTax, type == .income else { return 0 }; return Int(Double(amount) * taxRate / 100) }
    private var netAmount: Int { guard hasTax, type == .income else { return amount }; return amount - taxAmount }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("제목 (필수)", text: $title)
                        .overlay(alignment: .trailing) {
                            if showValidationError && title.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                            }
                        }
                        .onChange(of: title) { if title.count > 30 { title = String(title.prefix(30)) } }
                    DatePicker("일자", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                }
                Section("금액") {
                    Picker("유형", selection: $type) {
                        ForEach(IncomeExpense.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    TextField("금액 (필수)", text: $amountText).keyboardType(.numberPad)
                        .overlay(alignment: .trailing) {
                            if showValidationError && amountText.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                            }
                        }
                    if type == .expense {
                        Picker("카테고리", selection: $expenseCategory) {
                            ForEach(ExpenseCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                    }
                    if type == .income {
                        Toggle("세금", isOn: $hasTax)
                        if hasTax {
                            HStack {
                                Button {
                                    useDefaultTax = true; customTaxRateText = ""
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: useDefaultTax ? "checkmark.circle.fill" : "circle")
                                        Text("3.3%")
                                    }.font(.subheadline)
                                }.buttonStyle(.plain)
                                Spacer()
                                TextField("직접 입력 (%)", text: $customTaxRateText)
                                    .keyboardType(.decimalPad).frame(width: 100).textFieldStyle(.roundedBorder)
                                    .onChange(of: customTaxRateText) { if !customTaxRateText.isEmpty { useDefaultTax = false } }
                            }
                            if amount > 0 {
                                LabeledContent("세금 금액", value: "\(taxAmount.formatted())원").foregroundStyle(.secondary)
                                LabeledContent("실수령액") {
                                    Text("\(netAmount.formatted())원").fontWeight(.semibold).foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
                Section("메모") {
                    TextEditor(text: $memo).frame(minHeight: 80)
                        .onChange(of: memo) { if memo.count > 200 { memo = String(memo.prefix(200)) } }
                    Text("\(memo.count)/200").font(.caption).foregroundStyle(.secondary)
                }
                if isEditing {
                    Section { Button("삭제", role: .destructive) { showDeleteAlert = true } }
                }
            }
            .navigationTitle(isEditing ? "가계부 편집" : "가계부 등록").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("저장") { Task { await save() } } }
            }
            .alert("가계부 삭제", isPresented: $showDeleteAlert) {
                Button("삭제", role: .destructive) { Task { await deleteAndDismiss() } }
                Button("취소", role: .cancel) {}
            } message: { Text("이 가계부 항목을 삭제하시겠습니까?") }
            .onAppear { loadEditData() }
        }
    }

    private func loadEditData() {
        if case .edit(let item) = mode {
            title = item.title; date = item.date; type = item.type; amountText = String(item.amount)
            hasTax = item.hasTax
            if let rate = item.taxRate { if rate == 3.3 { useDefaultTax = true } else { useDefaultTax = false; customTaxRateText = String(rate) } }
            memo = item.memo ?? ""
            if let cat = item.expenseCategory { expenseCategory = cat }
        } else if let initialDate { date = initialDate }
    }

    private func save() async {
        guard !title.isEmpty, !amountText.isEmpty, amount > 0 else { showValidationError = true; return }
        guard let user = authViewModel.currentUser, let groupId = user.groupId else { return }
        let existingId: String
        if case .edit(let item) = mode { existingId = item.id } else { existingId = UUID().uuidString }
        let item = AccountBook(
            id: existingId, title: title, date: date, type: type, amount: amount,
            hasTax: hasTax && type == .income, taxRate: hasTax && type == .income ? taxRate : nil,
            taxAmount: hasTax && type == .income ? taxAmount : nil,
            netAmount: hasTax && type == .income ? netAmount : nil,
            memo: memo.isEmpty ? nil : memo,
            expenseCategory: type == .expense ? expenseCategory : nil,
            authorId: user.id, groupId: groupId
        )
        await accountBookVM.saveAccountBook(item); HapticManager.success(); await onSave?(); dismiss()
    }

    private func deleteAndDismiss() async {
        if case .edit(let item) = mode { await accountBookVM.deleteAccountBook(item); HapticManager.success(); await onSave?() }
        dismiss()
    }
}
