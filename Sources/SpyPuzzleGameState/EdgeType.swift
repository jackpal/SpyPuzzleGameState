public enum EdgeType : Int, Codable, CustomStringConvertible, Hashable {
  case open
  case red
  case green
  case blue
  case yellow
  
  public var description: String {
    switch self {
    case .open:
      return "o"
    case .red:
      return "r"
    case .green:
      return "g"
    case .blue:
      return "b"
    case .yellow:
      return "y"
    }
  }
}
