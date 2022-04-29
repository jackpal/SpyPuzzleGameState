public struct Enemy : Codable, Hashable, CustomStringConvertible, Identifiable {

  /// ID is needed for SwiftUI, but we don't want it to affect
  /// the A* pathfinding algorithm. Therefore we override
  /// hash and == to ignore id.
  public let id: Int
  public var type: EnemyType
  public var armored: Bool
  public var facing: Direction
  /// If the enemy has heard a sound, this is the goal they are moving towards.
  public var goal: Point? = nil
  
  public var description: String {
    "\(type)\(armored ? "a":"")\(facing)\(goal?.description ?? "")"
  }
  
  public func hash(into hasher: inout Hasher) {
    // Do not use id as part of hash.
    hasher.combine(type)
    hasher.combine(armored)
    hasher.combine(facing)
    hasher.combine(goal)
  }
  
  public static func ==(lhs: Enemy, rhs: Enemy) -> Bool {
    // Do not use id as part of ==.
    lhs.type == rhs.type && lhs.armored == rhs.armored
    && lhs.facing == rhs.facing && lhs.goal == rhs.goal
  }

}
