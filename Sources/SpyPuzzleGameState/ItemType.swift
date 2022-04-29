public enum ItemType : Codable, CustomStringConvertible, Hashable {
  case briefcase
  // Sniper rifle
  case gun
  case key(type: EdgeType)
  case pistols
  case plant
  case rock
  case suit(type: EnemyType)
  case waitPoint
  
  public var description: String {
    switch self {
    case .briefcase:
      return "briefcase"
    case .gun:
      return "gun"
    case .key(let keyType):
      return "key\(keyType)"
    case .pistols:
      return "pistols"
    case .plant:
      return "plant"
    case .rock:
      return "rock"
    case .suit(let type):
      return "suit(\(type))"
    case .waitPoint:
      return "wait"
    }
  }
}
