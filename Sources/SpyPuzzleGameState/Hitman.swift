public struct Hitman: Codable, Hashable, CustomStringConvertible, Identifiable {
  public var id: Int = 0
  public var position: Point
  public var hasBriefcase : Bool
  public var costume: Costume
  public var speedKill : Bool
  
  public init(x: Int, y: Int) {
    position = Point(x:x, y: y)
    costume = .normal
    hasBriefcase = false
    speedKill = false
  }
  
  public var description: String {
    "\(position)\(costume)\(hasBriefcase)"
  }
}
