import Foundation

struct NaverPlace: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let address: String
    let roadAddress: String
    let mapx: Double // WGS84 경도
    let mapy: Double // WGS84 위도
}

final class NaverSearchService {
    static let shared = NaverSearchService()

    // TODO: 네이버 개발자 센터에서 발급받은 키로 교체
    private let clientId = "2sfSLog69aR23X05l8xB"
    private let clientSecret = "gcVAv9nZgD"

    private init() {}

    func searchPlaces(query: String) async throws -> [NaverPlace] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: "https://openapi.naver.com/v1/search/local.json")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "display", value: "10"),
            URLQueryItem(name: "sort", value: "random")
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(NaverSearchResponse.self, from: data)

        return result.items.map { item in
            // 네이버 지역 검색은 KATEC 좌표계 → WGS84 변환 필요
            let (lng, lat) = katecToWGS84(x: Double(item.mapx) ?? 0, y: Double(item.mapy) ?? 0)
            return NaverPlace(
                title: item.title.stripHTML(),
                address: item.address,
                roadAddress: item.roadAddress,
                mapx: lng,
                mapy: lat
            )
        }
    }

    // KATEC → WGS84 근사 변환 (간이 변환)
    private func katecToWGS84(x: Double, y: Double) -> (longitude: Double, latitude: Double) {
        // 네이버 지역검색 API의 mapx, mapy는 실제로는 정수형 좌표
        // 예: mapx=1269876543 → 126.9876543
        let longitude = x / 10_000_000.0
        let latitude = y / 10_000_000.0
        return (longitude, latitude)
    }
}

private struct NaverSearchResponse: Codable {
    let items: [NaverSearchItem]
}

private struct NaverSearchItem: Codable {
    let title: String
    let address: String
    let roadAddress: String
    let mapx: String
    let mapy: String
}

extension String {
    func stripHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
