import Foundation

struct GeoIPService {

    static func lookupCountryCode(for address: String) async -> String? {
        let urlString = "https://ipwho.is/\(address)?fields=country_code"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["country_code"] as? String
        } catch {
            return nil
        }
    }
}
