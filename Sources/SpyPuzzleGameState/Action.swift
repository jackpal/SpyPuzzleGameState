public enum Action : Hashable, CustomStringConvertible {
  case move(d: Direction)
  case fire(target: Point)
  case toss(d: Direction)
  case subway(name: String)
  
  public var description: String {
    switch self {
    case .move(d: let d):
      return "\(d)"
    case .fire(target: let target):
      return "fire \(target.cleanDescription)"
    case .toss(d: let d):
      return "toss \(d)"
    case let .subway(name):
      return "subway \(name)"
    }
  }
}

public extension Action {
  var turns: Int {
    switch self {
    case .move,.subway:
      return 1
    case .fire,.toss:
      return 0
    }
  }
}

/// Performs an action on a state.
// TODO: Decide semantics if the action is illegal or would kill hitman.
public func perform(action: Action, on state: inout GameState) {
  
  func move(d: Direction) {
    var state2 = state
    if let node = state2.at(p:state.hitman.position) {
      if node.edges[d] != nil {
        let moveResult = moveHitman(s: &state2, d: d)
        if moveResult == .done {
          if moveEnemies(s: &state2) == .nothing {
            state = state2
          }
        }
      }
    }
  }
  
  func fire(target:Point) {
    try! fireGun(s: &state, target:target)
  }
  
  func toss(d: Direction) {
    try! throwRock(s: &state, d: d)
  }

  func subway(name: Character) {
    var state2 = state
    if useSubway(s: &state2, peerName: name) {
      if moveEnemies(s: &state2) == .nothing {
        state = state2
      }
    }
  }
  
  switch action {
  case .move(let d):
    move(d: d)
  case .fire(let target):
    fire(target:target)
  case .toss(let d):
    toss(d: d)
  case .subway(let name):
    subway(name: name.first!)
  }
}

/// Returns legal actions, including ones that will immediately kill the hitman.
public func actions(state: GameState) -> Set<Action> {
  var actions = Set<Action>()
  switch state.at(p:state.hitman.position)?.item?.type {
  case .gun:
    let targets = targets(map:state.map)
    if !targets.isEmpty {
      for target in targets {
        actions.insert(.fire(target: target))
      }
      return actions
    }
  case .rock:
    for direction in Direction.allCases {
      if canThrowRock(s: state, d: direction) {
        actions.insert(.toss(d: direction))
      }
    }
    if !actions.isEmpty {
      return actions
    }
  case .waitPoint:
    assertionFailure("Should never encounter a WaitPoint")
    return actions
  default:
    break
  }
  
  if case let .subway(_,peerNames) = state.at(p:state.hitman.position)?.type {
    for peerName in peerNames {
      actions.insert(.subway(name: String(peerName)))
    }
  }
  
  for direction in Direction.allCases {
    if canMoveHitman(s: state, d: direction) {
      actions.insert(.move(d:direction))
    }
  }
  return actions
}
