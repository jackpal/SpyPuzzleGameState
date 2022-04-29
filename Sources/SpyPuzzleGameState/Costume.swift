public enum Costume : Codable, Hashable, CustomStringConvertible {
  case normal
  case trenchcoat
  case suit(type: EnemyType)
  
  public var description: String {
    switch self {
    case .normal:
      return ""
    case .trenchcoat:
      return "t"
    case let .suit(type):
      return type.description
    }
  }
  
  public func hitmanWillKill(type enemyType: EnemyType)-> Bool {
    switch self {
    case .normal:
      return true
    case .trenchcoat:
      return true
    case let .suit(type: suitType):
      return suitType != enemyType
    }
  }
  
  public func hitmanWillBeKilled(type enemyType: EnemyType)-> Bool {
    switch self {
    case .normal:
      return true
    case .trenchcoat:
      return false
    case let .suit(type: suitType):
      return suitType != enemyType
    }
  }

}
