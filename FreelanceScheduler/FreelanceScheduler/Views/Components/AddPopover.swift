import SwiftUI

struct AddPopover: View {
    var onScheduleTap: () -> Void
    var onAccountBookTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                onScheduleTap()
            } label: {
                Label("일정 등록", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }

            Divider()

            Button {
                onAccountBookTap()
            } label: {
                Label("가계부 등록", systemImage: "wonsign.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .frame(width: 180)
        .presentationCompactAdaptation(.popover)
    }
}
