public enum Direction : Int, RawRepresentable, Codable, CaseIterable, Hashable, CustomStringConvertible {
  
  case north
  case east
  case south
  case west
  
  public var description: String {
    switch self {
    case .north: return "N"
    case .east: return "E"
    case .south: return "S"
    case .west: return "W"
    }
  }

  public var opposite : Direction {
    switch self {
    case .north:
      return .south
    case .east:
      return .west
    case .south:
      return .north
    case .west:
      return .east
    }
  }
  
  public var clockwise : Direction {
    switch self {
    case .north:
      return .east
    case .east:
      return .south
    case .south:
      return .west
    case .west:
      return .north
    }
  }
  
  public var counterClockwise : Direction {
    switch self {
    case .north:
      return .west
    case .east:
      return .north
    case .south:
      return .east
    case .west:
      return .south
    }
  }
  
  public var dx : Int {
    switch self {
    case .north:
      return 0
    case .east:
      return 1
    case .south:
      return 0
    case .west:
      return -1
    }
  }
  
  public var dy : Int {
    switch self {
    case .north:
      return -1
    case .east:
      return 0
    case .south:
      return 1
    case .west:
      return 0
    }
  }

}

