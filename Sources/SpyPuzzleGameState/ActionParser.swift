public func parse(actions actionsArg: String)throws -> [Action] {
  var input = actionsArg[...]
  
  var actions: [Action] = []
  
  func take() -> Substring {
    let result = input.prefix(1)
    input = input.dropFirst()
    return result
  }
  
  func peek() -> Substring {
    return input.prefix(1)
  }
  
  func advance(_ s: String)-> Bool {
    if input.starts(with: s) {
      input = input.dropFirst(s.count)
      return true
    }
    return false
  }
  
  func parseDirection() -> Direction? {
    if advance("N") {
      return .north
    } else if advance("E") {
      return .east
    } else if advance("S") {
      return .south
    } else if advance("W") {
      return .west
    } else {
      return nil
    }
  }
  
  func parseInt() -> Int? {
    var buf = ""
    while true {
      let d = String(peek())
      if "0" <= d && d <= "9" {
        _ = take()
        buf.append(d)
      } else {
        return Int(buf)!
      }
    }
  }
  
  func parsePoint() -> Point? {
    if !advance("(") {
      return nil
    }
    let x = parseInt()!
    _ = advance(",")
    let y = parseInt()!
    _ = advance(")")
    return Point(x:x,y:y)
  }
  
  func parseAction() -> Action? {
    if let dir = parseDirection() {
      return .move(d: dir)
    }
    if advance("toss ") {
      return .toss(d: parseDirection()!)
    }
    if advance("subway ") {
      return .subway(name: String(take()))
    }
    if advance("fire ") {
      return .fire(target: parsePoint()!)
    }
    return nil
  }
  
  while let action = parseAction() {
    actions.append(action)
    if advance(",") {
      _ = advance(" ")
    }
  }
  return actions
}


