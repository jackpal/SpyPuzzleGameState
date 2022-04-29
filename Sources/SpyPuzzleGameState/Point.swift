import simd

public typealias Point = SIMD2<Int>

public extension SIMD2 where Scalar == Int {
  func offset(direction: Direction) -> SIMD2 {
    return SIMD2(x: x + direction.dx, y: y + direction.dy)
  }
  
  // Returns the direction from self to the adjacent point, or nil if p2 is not adjacent.
  func direction(adjacent p2:SIMD2) -> Direction? {
    switch (p2.x,p2.y) {
    case (x,y-1):
      return .north
    case (x+1,y):
      return .east
    case (x,y+1):
      return .south
    case (x-1,y):
      return .west
    default:
      return nil
    }
  }
  
  var cleanDescription : String {
    "(\(x),\(y))"
  }
}

public func gridOrder(lhs: Point, rhs: Point)->Bool {
  if lhs.y != rhs.y {
    return lhs.y < rhs.y
  }
  return lhs.x < rhs.x
}
