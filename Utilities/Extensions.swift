import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func limited(to length: Int) -> String {
        guard count > length else { return self }
        let index = index(startIndex, offsetBy: length)
        return String(self[..<index])
    }
}
