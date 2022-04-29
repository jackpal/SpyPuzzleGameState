public enum EnemyType : Codable, CustomStringConvertible, Hashable {
  case blue
  case yellow
  case green
  case duo
  case dog(chasing:[Point])
  case flashlight
  case patrol(route:Route)
  case mark
  case sniper
  
  public var description: String {
    switch self {
    case .blue:
      return "b"
    case .yellow:
      return "y"
    case .green:
      return "g"
    case .duo:
      return "2"
    case let .dog(chasing):
      return "d\(chasing.count != 0 ? "!":"")"
    case .flashlight:
      return "f"
    case .patrol:
      return "p"
    case .mark:
      return "m"
    case .sniper:
      return "s"
    }
  }
  
  public var lunges : Bool {
    switch self {
    case .blue, .green, .dog, .duo:
      return true
    default:
      return false
    }
  }

}
