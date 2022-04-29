public enum NodeType : Codable, CustomStringConvertible, Hashable {
  case exit
  case plain
  case rubble
  case statue(d: Direction)
  case subway(name:String, peers: String)
  case target
  case walkway(d: Direction)

  public var description: String {
    switch self {
    case .exit:
      return "exit"
    case .plain:
      return ""
    case .rubble:
      return "rubble"
    case .statue(let d):
      return "statue\(d)"
    case .subway(let name, let peers):
      return "subway(\(name)-\(peers))"
    case .target:
      return "target"
    case let .walkway(d):
      return "walkway(\(d))"
    }
  }
  
  public var isTargetable: Bool {
    switch self {
    case .statue,.target:
      return true
    default:
      return false
    }
  }
}
