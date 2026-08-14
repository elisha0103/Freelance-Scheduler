import SwiftUI

struct MonthPickerAlert: View {
    let year: Int
    let month: Int
    var onConfirm: (Int, Int) -> Void

    @State private var yearText: String = ""
    @State private var monthText: String = ""

    init(year: Int, month: Int, onConfirm: @escaping (Int, Int) -> Void) {
        self.year = year
        self.month = month
        self.onConfirm = onConfirm
        _yearText = State(initialValue: String(year))
        _monthText = State(initialValue: String(month))
    }

    var body: some View {
        TextField("년도", text: $yearText)
            .keyboardType(.numberPad)
        TextField("월", text: $monthText)
            .keyboardType(.numberPad)
        Button("이동") {
            if let y = Int(yearText), let m = Int(monthText), (1...12).contains(m) {
                onConfirm(y, m)
            }
        }
        Button("취소", role: .cancel) {}
    }
}
