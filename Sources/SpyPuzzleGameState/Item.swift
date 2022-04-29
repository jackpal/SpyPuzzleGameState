public struct Item: Codable, Hashable, Identifiable, CustomStringConvertible {
  
  /// ID is needed for SwiftUI, but we don't want it to affect
  /// the A* pathfinding algorithm. Therefore we override
  /// hash and == to ignore id.
  public let id: Int
  public let type: ItemType
  
  public var description: String {
    type.description
  }
  
  public func hash(into hasher: inout Hasher) {
    // Do not use id as part of hash.
    hasher.combine(type)
  }
  
  public static func ==(lhs: Item, rhs: Item) -> Bool {
    // Do not use id as part of ==.
    lhs.type == rhs.type
  }

}
