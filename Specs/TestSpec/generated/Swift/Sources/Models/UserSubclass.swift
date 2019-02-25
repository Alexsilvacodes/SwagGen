//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation

public class UserSubclass: User {

    public var age: Int?

    public init(id: Int? = nil, name: String? = nil, age: Int? = nil) {
        self.age = age
        super.init(id: id, name: name)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        age = try container.decodeIfPresent("age")
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encodeIfPresent(age, forKey: "age")
        try super.encode(to: encoder)
    }

    override public func isEqual(to object: Any?) -> Bool {
      guard let object = object as? UserSubclass else { return false }
      guard self.age == object.age else { return false }
      return super.isEqual(to: object)
    }
}
