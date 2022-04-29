public struct GameState: Hashable {
  public var map: NodeMap
  public var hitman: Hitman
  
  public func at(x:Int, y:Int) -> Node? {
    at(p:Point(x:x, y:y))
  }
  
  public func at(p:Point) -> Node? {
    map[p]
  }
  
  public func neighbor(p: Point, d: Direction) -> Point? {
    at(p:p)?.neighbor(position:p, d:d)
  }

}
