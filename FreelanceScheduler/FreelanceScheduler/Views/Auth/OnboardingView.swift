import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    private let pages: [(icon: String, title: String, description: String)] = [
        ("calendar.badge.clock", "일정 관리", "캘린더에서 프리랜서 일정을\n한눈에 확인하고 관리하세요"),
        ("wonsign.circle.fill", "가계부", "수입과 지출을 기록하고\n세금 계산까지 자동으로"),
        ("person.2.fill", "그룹 협업", "팀원들과 일정을 공유하고\n함께 프로젝트를 관리하세요"),
        ("chart.bar.fill", "통계 & 분석", "월간/연간 수입 분석과\n세금 신고 요약을 확인하세요")
    ]

    @State private var currentPage = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: pages[index].icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.blue)

                        Text(pages[index].title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(pages[index].description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            if currentPage < pages.count - 1 {
                Button("건너뛰기") {
                    hasSeenOnboarding = true
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            }
        }
    }
}
