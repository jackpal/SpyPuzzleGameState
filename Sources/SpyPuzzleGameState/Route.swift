public enum RouteError: Error {
  case notOnRoute
}

public enum Octant : Int, RawRepresentable {
  case topLeft
  case top
  case topRight
  case right
  case bottomRight
  case bottom
  case bottomLeft
  case left
}

// TODO: Make this a test.
func testRoute() {
  let route = Route(topLeft:Point(1,2), bottomRight: Point(3,4))!
  let points = [
    Point(x:1,y:2),
    Point(x:2, y:2),
    Point(x:3, y:2),
    Point(x:3, y:3),
    Point(x:3, y:4),
    Point(x:2, y:4),
    Point(x:1, y:4),
    Point(x:1, y:3)
  ]
  let edges : [Direction:EdgeType] = [.north: .open, .east: .open, .south : .open, .west : .open]
  var state = (points[0],Direction.east)
  for i in 0..<8 {
    state = try! route.advance(p: state.0, facing: state.1, edges: edges)
    assert(state.0 == points[(i+1)&7])
  }
  
  state = (points[0],Direction.south)
  for i in 0..<8 {
    state = try! route.advance(p: state.0, facing: state.1, edges: edges)
    assert(state.0 == points[7-i])
  }
}

public struct Route : Codable, CustomStringConvertible, Hashable {
  var topLeft: Point
  var bottomRight: Point
  
  public init?(topLeft: Point, bottomRight: Point) {
    if topLeft.x >= bottomRight.x || topLeft.y >= bottomRight.y {
      return nil
    }
    self.topLeft = topLeft
    self.bottomRight = bottomRight
  }
  
  public var description: String {
    "(\(topLeft.x),\(topLeft.y))-(\(bottomRight.x),\(bottomRight.y))"
  }
  
  public func contains(p: Point)-> Bool {
    (p.x == left || p.x == right) && (top <= p.y && p.y <= bottom) ||
    (left <= p.x && p.x <= right) && (p.y == top || p.y == bottom)
  }
  
  public func advance(p: Point, facing: Direction, edges: [Direction:EdgeType]) throws -> (p: Point, facing: Direction) {
    // Is the patrol currently moving clockwise or counter-clockwise order?
    let cwFacing = try self.facing(p: p, clockwise:true)
    let clockwise = facing == cwFacing
    // Can patrol proceed to the next square?
    if edges[facing] == .open {
      // Yes, the way is clear.
      
      let newP = p.offset(direction: facing)
      return (newP, try! self.facing(p: newP, clockwise: clockwise))
    } else {
      // Blocked. Reverse the patrol route.
      let newFacing = try self.facing(p:p, clockwise:!clockwise)
      if edges[newFacing] == .open {
        // Yes, the way is clear.
        
        let newP = p.offset(direction: newFacing)
        return (newP, try! self.facing(p: newP, clockwise: !clockwise))
      } else {
        // Blocked.
        return (p, newFacing)
      }
    }
  }
  
  // Which direction should the patrol be facing for a given point.
  public func facing(p: Point, clockwise: Bool) throws -> Direction {
    let octantIndex = try octant(p: p).rawValue
    if clockwise {
      return Route.octantToFacingCW[octantIndex]
    } else {
      return Route.octantToFacingCCW[octantIndex]
    }
  }
  
  private static let octantToFacingCW:  [Direction] = [.east, .east, .south, .south, .west, .west, .north, .north]
  private static let octantToFacingCCW:  [Direction] = [.south, .west, .west, .north, .north, .east, .east, .south]

  var left : Int {
    topLeft.x
  }

  var top : Int {
    topLeft.y
  }
  
  var right : Int {
    bottomRight.x
  }
  
  var bottom : Int {
    bottomRight.y
  }
  
  private func octant(p: Point) throws -> Octant {
    if p.y < top || bottom < p.y || p.x < left || right < p.x {
      throw RouteError.notOnRoute
    }
    if p.y == top {
      if p.x < left {
        throw RouteError.notOnRoute
      }
      if p.x == left {
        return .topLeft
      } else if p.x < right {
        return .top
      } else if p.x == right {
        return .topRight
      }
    } else if p.y < bottom {
      if p.x == left {
        return .left
      } else if p.x == right {
        return .right
      }
    } else if p.y == bottom {
      if p.x == left {
        return .bottomLeft
      } else if p.x < right {
        return .bottom
      } else if p.x == right {
        return .bottomRight
      }
    }
    throw RouteError.notOnRoute
  }

}
