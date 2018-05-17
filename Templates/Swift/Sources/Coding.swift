{% include "Includes/Header.stencil" %}

import Foundation

struct StringCodingKey: CodingKey, ExpressibleByStringLiteral {

    private let string: String
    private let int: Int?

    var stringValue: String { return string }

    init(string: String) {
        self.string = string
        int = nil
    }
    init?(stringValue: String) {
        string = stringValue
        int = nil
    }

    var intValue: Int? { return int }
    init?(intValue: Int) {
        string = String(describing: intValue)
        int = intValue
    }

    init(stringLiteral value: String) {
        string = value
        int = nil
    }
}

// any json decoding
extension JSONDecoder {

    func decodeAny<T>(_ type: T.Type, from data: Data) throws -> T {
        guard let decoded = try decode(AnyCodable.self, from: data) as? T else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: [StringCodingKey(string: "")], debugDescription: "Decoding of \(T.self) failed"))
        }
        return decoded
    }
}

// any decoding
extension KeyedDecodingContainer {

    func decodeAny<T>(_ type: T.Type, forKey key: K) throws -> T {
        guard let value = try decode(AnyCodable.self, forKey: key).value as? T else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Decoding of \(T.self) failed"))
        }
        return value
    }

    func decodeAnyIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? {
        return try decodeOptional {
            guard let value = try decodeIfPresent(AnyCodable.self, forKey: key)?.value else { return nil }
            if let typedValue = value as? T {
                return typedValue
            } else {
                throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Decoding of \(T.self) failed"))
            }
        }
    }

    func toDictionary() throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        for key in allKeys {
            dictionary[key.stringValue] = try decodeAny(key)
        }
        return dictionary
    }

    func decode<T>(_ key: KeyedDecodingContainer.Key) throws -> T where T: Decodable {
        return try decode(T.self, forKey: key)
    }

    func decodeIfPresent<T>(_ key: KeyedDecodingContainer.Key) throws -> T? where T: Decodable {
        return try decodeOptional {
            try decodeIfPresent(T.self, forKey: key)
        }
    }

    func decodeAny<T>(_ key: K) throws -> T {
        return try decodeAny(T.self, forKey: key)
    }

    func decodeAnyIfPresent<T>(_ key: K) throws -> T? {
        return try decodeAnyIfPresent(T.self, forKey: key)
    }

    public func decodeArray<T: Decodable>(_ key: K) throws -> [T] {
        var container = try nestedUnkeyedContainer(forKey: key)
        var array: [T] = []
        while !container.isAtEnd {
            do {
                let element = try container.decode(T.self)
                array.append(element)
            } catch {
                if {{ options.name }}.safeArrayDecoding {
                    // hack to advance the current index
                    _ = try? container.decode(AnyCodable.self)
                } else {
                    throw error
                }
            }
        }
        return array
    }

    public func decodeArrayIfPresent<T: Decodable>(_ key: K) throws -> [T]? {
        return try decodeOptional {
            if contains(key) {
                return try decodeArray(key)
            } else {
                return nil
            }
        }
    }

    fileprivate func decodeOptional<T>(_ closure: () throws -> T? ) throws -> T? {
        if {{ options.name }}.safeOptionalDecoding {
            do {
                return try closure()
            } catch {
                return nil
            }
        } else {
            return try closure()
        }
    }
}

// any encoding
extension KeyedEncodingContainer {

    mutating func encodeAnyIfPresent<T>(_ value: T?, forKey key: K) throws {
        try encodeIfPresent(AnyCodable(value), forKey: key)
    }

    mutating func encodeAny<T>(_ value: T, forKey key: K) throws {
        try encode(AnyCodable(value), forKey: key)
    }
}

public struct DateDay: Codable, Equatable {

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYY-MM-dd"
        formatter.calendar = .current
        return formatter
    }()

    let date: Date
    public let year: Int
    public let month: Int
    public let day: Int

    public init(date: Date) {
        self.date = date
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        guard let year = dateComponents.year,
            let month = dateComponents.month,
            let day = dateComponents.day else {
                fatalError("Date does not contain correct components")
        }
        self.year = year
        self.month = month
        self.day = day
    }

    public init(year: Int, month: Int, day: Int) {
        let dateComponents = DateComponents(calendar: .current, year: year, month: month, day: day)
        guard let date = dateComponents.date else {
            fatalError("Could not create date in current calendar")
        }
        self.date = date
        self.year = year
        self.month = month
        self.day = day
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let date = DateDay.dateFormatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date not in correct format of \( DateDay.dateFormatter.dateFormat)")
        }
        self.init(date: date)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let string = DateDay.dateFormatter.string(from: date)
        try container.encode(string)
    }

    public static func == (lhs: DateDay, rhs: DateDay) -> Bool {
        return lhs.year == rhs.year &&
            lhs.month == rhs.month &&
            lhs.day == rhs.day
    }
}

extension DateDay {
    func encode() -> Any {
        return DateDay.dateFormatter.string(from: date)
    }
}

extension Date {
    func encode() -> Any {
        return {{ options.name }}.dateFormatter.string(from: self)
    }
}

extension URL {
    func encode() -> Any {
        return absoluteString
    }
}

extension RawRepresentable {
    func encode() -> Any {
        return rawValue
    }
}

extension Array where Element: RawRepresentable {
    func encode() -> [Any] {
        return map { $0.rawValue }
    }
}

extension Dictionary where Key == String, Value: RawRepresentable {
    func encode() -> [String: Any] {
        return mapValues { $0.rawValue }
    }
}