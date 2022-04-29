public enum GoalError : Error {
  case noGoalPosition
  case noBriefcaseToPickUp
}

/// The hitman state when the level is won.
public func goalHitman(state:GameState, pickupBriefcase: Bool) throws -> Hitman {
  var hitman = Hitman(x:-1,y:-1)
  if pickupBriefcase {
    let briefcasePos = find(map:state.map) { $0.item?.type == .briefcase}
    if briefcasePos == nil {
      throw GoalError.noBriefcaseToPickUp
    }
  }
  hitman.hasBriefcase = pickupBriefcase
  if let exitPosition = find(map:state.map, type:.exit) {
    hitman.position = exitPosition
  }
  return hitman
}

// Just tests for connectivity, doesn't test for lethality.
public func canMoveHitman(s: GameState, d: Direction)-> Bool {
  let pos = s.hitman.position
  if s.neighbor(p:pos, d:d) == nil {
    return false
  }
  return true
}

public enum MoveResult {
  case noPath
  case noSubway
  case wouldDie
  case done
}

public func moveHitman(s: inout GameState, d: Direction)-> MoveResult  {
  let pos = s.hitman.position
  guard let newPos = s.neighbor(p:pos, d:d),
        let newNode = s.map[newPos] else {
    return .noPath
  }
  // Not allowed to move backwards onto walkway
  if case let .walkway(walkwayDir) = newNode.type, walkwayDir == d.opposite {
    return .noPath
  }
  // Looks good, go ahead and update model
  s.hitman.position = newPos
  
  var justExitedWalkway = false
  if case .walkway = newNode.type {
    var probeGameState = s
    if case .killedHitman = moveHitmanAlongWalkway(s:&probeGameState) {
      return .wouldDie
    }
    s = probeGameState
    justExitedWalkway = true
  }

  return updateNodeForHitmanEnteringIt(s:&s, justExitedWalkway: justExitedWalkway)
}

public func moveHitmanAlongWalkway(s: inout GameState) -> MoveEnemiesResult {
  var p = s.hitman.position
  while true {
    guard let node = s.at(p:p),
          case let .walkway(dir) = node.type else {
      return .nothing
    }
    p = p.offset(direction: dir)
    s.hitman.position = p
    let nextNode = s.at(p:p)!
    // TODO: How do sniper lasers interact with walkway movement?
    for (edgeDir,edgeValue) in nextNode.edges {
      // Don't check in the direction opposite to movement.
      if edgeDir != dir.opposite && edgeValue == .open {
        if let neighborNode = s.at(p: p.offset(direction: edgeDir)) {
          for enemy in neighborNode.enemies {
            if enemy.facing == edgeDir.opposite &&
                s.hitman.costume.hitmanWillBeKilled(type:enemy.type){
              // Not sure if Alert mode affects lunge behavior or not.
              if enemy.type.lunges {
                return .killedHitman
              }
            }
          }
        }
      }
    }
  }
}

public func hitmanKilledEnemy(s: inout GameState, justExitedWalkway: Bool) {
  if s.hitman.costume == .trenchcoat {
    s.hitman.costume = .normal
  }
  if justExitedWalkway {
    s.hitman.speedKill = true
  }
}

public extension Node {
  var hasEnemies: Bool {
    !enemies.isEmpty
  }
  
  var hasPlant: Bool {
    item?.type == .plant
  }
}

public func updateNodeForHitmanEnteringIt(s: inout GameState, justExitedWalkway: Bool)-> MoveResult {
  let pos = s.hitman.position

  guard var node = s.map[pos] else {
    return .noPath
  }
  
  if node.hasEnemies && !node.hasPlant {
    let oldEnemies = node.enemies
    let updatedEnemies = oldEnemies.filter{ !s.hitman.costume.hitmanWillKill(type: $0.type) }
    if updatedEnemies != oldEnemies {
      hitmanKilledEnemy(s: &s, justExitedWalkway: justExitedWalkway)
      node.enemies = updatedEnemies
    }
  }
  switch node.item?.type {
  case .briefcase:
    s.hitman.hasBriefcase = true
    node.item = nil
  case let .key(keyType):
    openDoors(s: &s, keyType:keyType)
    // Node's edges may have been updated by openDoors.
    node.edges = s.map[pos]!.edges
    node.item = nil
  case .pistols:
    try! shootPistols(s: &s)
    node.item = nil
  case let .suit(type):
    s.hitman.costume = .suit(type:type)
    node.item = nil
  case .waitPoint:
    node.item = nil
    if moveEnemies(s: &s) == .killedHitman {
      return .wouldDie
    }

  default:
    break
  }
  s.map[pos] = node

  return .done
}

public enum ShootPistols: Error {
  case noPistols
}

public func shootPistols(s: inout GameState) throws {
  let pos = s.hitman.position
  guard let node = s.at(p:pos), s.at(p:pos)?.item?.type == .pistols else {
    throw ShootPistols.noPistols
  }
  // What we know from experiment with level 3-8:
  // Range of pistols is 1 square in all 4 directions.
  // Pistol will kill all enemies in a square, not just one.
  // Questions:
  // Do the pistols fire through closed doors? Assume: no.
  // Do the pistols fire through open space between nodes? Answer: no. (Seen on level 4-3)
  // Do the pistols fire through solid walls beteen nodes? Assume: never appears in any level.
  for d in Direction.allCases {
    let edge = node.edges[d]
    if edge == .open {
      let targetPos = pos.offset(direction: d)
      doBulletDamage(s:&s, targetPos:targetPos)
    }
  }
  s.map[pos]!.item = nil
}

public func doBulletDamage(s: inout GameState, targetPos: Point) {
  if s.map[targetPos]?.administerBulletDamage() == true {
    hitmanKilledEnemy(s: &s, justExitedWalkway: false)
  }
}

public func openDoors(s: inout GameState, keyType: EdgeType) {
  for (position, node) in s.map {
    let oldEdges = node.edges
    let newEdges = oldEdges.mapValues { $0 == keyType ? .open : $0 }
    if oldEdges != newEdges {
      s.map[position]!.edges = newEdges
    }
  }
}

// Returns true if subway path with index index exists.
public func useSubway(s: inout GameState, peerName: Character) -> Bool {
  // print("useSubway(\(peerName))")
  let peerName = String(peerName)
  let peerPos = find(map:s.map) {
    guard case let .subway(name, _) = $0.type else {
      return false
    }
    return name == peerName
  }
  guard let peerPos = peerPos else {
    assertionFailure("didn't find peer \(peerName)")
    return false
  }
  s.hitman.position = peerPos
  _ = updateNodeForHitmanEnteringIt(s:&s, justExitedWalkway: false)
  return true
}

public func clearDogsChaseMode(s: inout GameState) {
  for (position, node) in s.map {
    let enemies = node.enemies
    for e in 0..<enemies.count {
      if case .dog = enemies[e].type {
        s.map[position]!.enemies[e].type = .dog(chasing:[])
      }
    }
  }
}

public enum FireGunError : Error {
  case noGun
  case notAValidTarget(target: Point)
}

public func fireGun(s: inout GameState, target: Point) throws {
  let hitmanPos = s.hitman.position
  if s.map[hitmanPos]!.item?.type != .gun {
    throw FireGunError.noGun
  }
  let targetNodeType = s.map[target]?.type
  switch targetNodeType {
  case let .statue(dir):
    s.map[target] = Node(type: .rubble)
    let t2 = target.offset(direction: dir)
    if let node2 = s.at(p:t2) {
      // Disconnect t2's neighbors from t2
      for dir in node2.edges.keys {
        let t3 = t2.offset(direction: dir)
        s.map[t3]!.edges.removeValue(forKey: dir.opposite)
        
        // Update any yellow guards that were facing towards the rubble to face away from the rubble.
        for (i,e) in s.map[t3]!.enemies.enumerated() {
          if e.type == .yellow && e.facing == dir.opposite {
            var e = e
            e.facing = e.facing.opposite
            s.map[t3]!.enemies[i] = e
          }
        }
      }
    }
    // Replace t2 with rubble
    s.map[t2] = Node(type: .rubble)
    // Assume shooting statue alerts enemy. This might not be the case.
    hitmanKilledEnemy(s: &s, justExitedWalkway: false)
  case .target:
    doBulletDamage(s:&s, targetPos: target)
  default:
    throw FireGunError.notAValidTarget(target: target)
  }
  s.map[hitmanPos]?.item = nil
}

public extension Node {
  mutating func administerBulletDamage() -> Bool {
    if enemies.count == 0 {
      return false
    }
    // Armor protects every enemy.
    if enemies.contains(where: { $0.armored }) {
      return false
    }
    enemies = []
    return true
  }
}

public extension Node {
  func neighbor(position: Point, d: Direction) -> Point? {
    if edges[d] == .open {
      return position.offset(direction: d)
    }
    return nil
  }
}

public func canThrowRock(s: GameState, d: Direction) -> Bool {
  let pos = s.hitman.position
  guard let node = s.at(p:pos) else {
    return false
  }
  
  // Only throw into non-enemy-occupied nodes
  guard let targetNode = s.at(p:pos.offset(direction: d)), targetNode.enemies.isEmpty else {
    return false
  }
  
  // Check if there's an edge in that direction.
  if let edge = node.edges[d] {
    // If so, only allow if edge is open.
    return edge == .open
  }

  return true
}

public enum ThrowRockError : Error {
  case closedDoor(position: Point, direction: Direction)
  case noNode(position: Point, direction: Direction)
}

public func throwRock(s: inout GameState, d: Direction) throws {
  // print("throw \(d)")
  let pos = s.hitman.position
  if let edge = s.at(p:pos)?.edges[d], edge != .open {
    throw ThrowRockError.closedDoor(position:pos, direction:d)
  }
  let rx = pos.x + d.dx
  let ry = pos.y + d.dy
  if s.at(x:rx, y:ry) == nil {
    throw ThrowRockError.noNode(position:pos, direction:d)
  }
  s.map[pos]?.item = nil
  let noisePosition = Point(x: rx, y: ry)
  for i in (-1)...1 {
    for j in (-1)...1 {
      let bx = rx + i
      let by = ry + j
      let position = Point(x:bx,y:by)
      if var node = s.at(p:position) {
        if !node.enemies.isEmpty {
          for (i,oldE) in node.enemies.enumerated() {
            var e = oldE
            if e.type != .mark {
              e.goal = noisePosition
              if let (dir, _) = directionTowards(s:s, from:position, to:noisePosition) {
                e.facing = dir
              }
              if case .dog = e.type {
                e.type = .dog(chasing:[])
              }
            }
            node.enemies[i] = e
          }
          s.map[position] = node
        }
      }
    }
  }
}

/// Returns the path to the first node where goal is true using
/// breadth first search. Returns nil if no such node is found.
///
/// This is a reverse-engineered version of  enemy pathfinding. It might be worth
/// creating alternate versions that has different restrictions.
/// Only considers open edges. Does not consider doors or subways.
/// Uses the NWES search order that the actual Hitman Go game appears to use for enemy
/// path finding.
public func pathTo(s: GameState, from start: Point, goal: (Point)->Bool) -> [Point]? {
  // Breadth first search adapted from https://en.wikipedia.org/wiki/Breadth-first_search
  
  var queue = [[Point]]()
  var visited = Set<Point>()
  
  visited.insert(start)
  queue.append([start])
  
  while !queue.isEmpty {
    let path = queue.removeFirst()
    guard let last = path.last else {
      continue
    }
    if goal(last) {
      return path
    }
    guard let node = s.at(p:last) else {
      continue
    }
    // The order of search can affect how "ties" are broken. One leve where this makes a difference:
    // Level 6-1 when we toss the rock south, the blue guard at (1,3) turns west in the game.
    // Level 4-13 second rock tossed north, the same issue with the direction a particular
    // green guard takes when alerted.
    //
    // These search orders fail: ENSW, ENWS, ESNW, ESWN, EWNS, EWSN,
    //        NESW, NEWS, NSEW, NSWE, NWSE
    // Succeeds: NWES
    // lexigraphically later search orders haven't been tried yet.
    for d in [Direction.north, Direction.west, Direction.east, Direction.south] {
      if let neighbor = node.neighbor(position:last, d:d), !visited.contains(neighbor) {
        visited.insert(neighbor)
        queue.append(path + [neighbor])
      }
    }
  }
  return nil
}

/// Same as pathTo, except just returns count of steps.
public func stepsTo(s: GameState, from start: Point, goal: (Point)->Bool) -> Int? {
  pathTo(s:s, from: start, goal: goal)?.count
}

public func directionTowards(s: GameState, from: Point, to: Point) -> (Direction, Int)? {
  directionTowards(s: s, from: from, goal: {$0 == to})
}

public func directionTowards(s: GameState, from: Point, goal: (Point)->Bool) -> (Direction, Int)? {
  let path = pathTo(s:s, from:from, goal:goal) ?? []
  if path.count < 2 {
    return nil
  }
  let next = path[1]
  let dx = next.x - from.x
  if dx < 0 {
    return (.west, path.count-1)
  } else if dx > 0 {
    return (.east, path.count-1)
  }
  let dy = next.y - from.y
  if dy < 0 {
    return (.north, path.count-1)
  } else if dy > 0 {
    return (.south, path.count-1)
  }
  return nil
}

public enum MoveEnemiesResult {
  case nothing
  case killedHitman
}

public func moveEnemies(s: inout GameState) -> MoveEnemiesResult {
  var newEnemyNodes = [Point : [Enemy]]()
  for (position, node) in s.map {
    if node.enemies.isEmpty {
      continue
    }
    var node = node
    let oldEnemies = node.enemies
    node.enemies = []
    s.map[position] = node
    for oldEnemy in oldEnemies {
      var enemy = oldEnemy
      let oldPos = position
      var pos = oldPos
      if let goal = enemy.goal {
        if let (dir, steps) = directionTowards(s:s, from: pos, to:goal) {
          pos = pos.offset(direction: dir)
          enemy.facing = dir
          // If we're done with steps, drop alert mode
          if steps <= 1 {
            enemy.goal = nil
            // If on patrol route, resume patrol.
            if case let .patrol(route) = enemy.type, let facing = try? route.facing(p: pos, clockwise: true) {
              enemy.facing = facing
            }
          }
        } else {
          enemy.goal = nil
        }
      }
      if oldPos == pos {
        switch enemy.type {
        case .blue:
          // Only moves to attack hitman.
          if let newPos = node.neighbor(position:pos, d:enemy.facing) {
            if newPos == s.hitman.position && s.hitman.costume.hitmanWillBeKilled(type:enemy.type) {
              pos = newPos
            }
          }
        case .green:
          // Only moves to attack hitman.
          if let newPos = node.neighbor(position:pos,d:enemy.facing) {
            if newPos == s.hitman.position && s.hitman.costume.hitmanWillBeKilled(type:enemy.type) {
              pos = newPos
            }
          }
          // If didn't move, flips direction.
          if pos == oldPos {
            enemy.facing = enemy.facing.opposite
          }
        case .yellow:
          // Runs forward until hits end of path, then reverses
          if let newPos = node.neighbor(position:pos, d:enemy.facing) {
            pos = newPos
          }
        case .flashlight:
          // Attacks clockwise of facing
          if let newPos = node.neighbor(position:pos, d:enemy.facing.clockwise) {
            if newPos == s.hitman.position && s.hitman.costume.hitmanWillBeKilled(type:enemy.type) {
              pos = newPos
            }
          }
          if pos == oldPos {
            // Runs forward until hits end of path, then reverses
            if let newPos = node.neighbor(position:pos, d:enemy.facing) {
              pos = newPos
            }
          }
        case .duo:
          // Only moves to attack hitman.
          for d in [enemy.facing, enemy.facing.opposite] {
            if let newPos = node.neighbor(position:pos, d:d) {
              if newPos == s.hitman.position && s.hitman.costume.hitmanWillBeKilled(type:enemy.type) {
                pos = newPos
                break
              }
            }
        }
        case let .dog(chasing):
          if chasing.count > 0 {
            var chasing = chasing
            let newPos = chasing.first!
            enemy.facing = pos.direction(adjacent: newPos)!
            pos = newPos
            chasing = Array(chasing.dropFirst())
            if chasing.last?.direction(adjacent: s.hitman.position) != nil {
              chasing.append(s.hitman.position)
            }
            enemy.type = .dog(chasing:chasing)
          } else {
            // Moves to attack hitman
            if let newPos = node.neighbor(position:pos, d:enemy.facing) {
              if newPos == s.hitman.position && s.hitman.costume.hitmanWillBeKilled(type:enemy.type) {
                pos = newPos
              } else {
                // If hitman is two squares ahead, chase hitman
                let newNode = s.at(p:newPos)!
                if let newPos2 = newNode.neighbor(position: newPos, d:enemy.facing) {
                  if newPos2 == s.hitman.position && s.hitman.costume.hitmanWillBeKilled(type:enemy.type) {
                    enemy.type = .dog(chasing:[newPos,newPos2])
                  }
                }
              }
            }
          }
          break
        case let .patrol(route):
          // Either on patrol or returning to patrol
          do {
            (pos, enemy.facing) = try route.advance(p: pos, facing: enemy.facing, edges:node.edges)
          } catch {
            // Return to patrol
            if let (dir, steps) = directionTowards(s:s, from: pos, goal: { route.contains(p: $0) }) {
              pos = pos.offset(direction: dir)
              enemy.facing = dir
              // If we're done with steps
              if steps <= 1 {
                // Resume patrol.
                enemy.facing = try! route.facing(p: pos, clockwise: true)
              }
            } else {
              assertionFailure("Unexpected state")
            }
          }
          break
        case .mark:
          break
        case .sniper:
          break
        }
      }
      
      // Travel along walkway
      pos = endOfWalkway(s:s, start:pos)
      
      // Edge case: yellow and flashlight enemies check for the need to reverse whenever not goal seeking.
      if (enemy.type == .yellow || enemy.type == .flashlight) && enemy.goal == nil {
        if s.neighbor(p:pos, d:enemy.facing) == nil {
          enemy.facing = enemy.facing.opposite
        }
      }
      if newEnemyNodes[pos] == nil {
        newEnemyNodes[pos] = [enemy]
      } else {
        newEnemyNodes[pos]!.append(enemy)
      }
    }
  }
  
  // Update enemy positions
  for (pos,enemies) in newEnemyNodes {
    s.map[pos]?.enemies = enemies
  }
  if enemiesWouldKillHitman(s: s) {
    return .killedHitman
  }
  
  // Sniper check after everyone is in their new position
  for (pos,enemies) in newEnemyNodes {
    for e in enemies {
      switch e.type {
      case .sniper:
        if e.goal == nil && laserSeesHitman(s: s, start: pos, facing: e.facing) {
          return .killedHitman
        }
      default:
        break
      }
    }
  }
  
  return .nothing
}

func endOfWalkway(s: GameState, start: Point) -> Point {
  var p = start
  while true {
    guard let node = s.at(p:p),
          case let .walkway(dir) = node.type else {
      return p
    }
    p = p.offset(direction: dir)
  }
}
  
func laserSeesHitman(s: GameState, start: Point, facing: Direction) -> Bool {
  // Assume laser only travels on grid lines, gets stopped by plants, doors and enemies.
  if !s.hitman.costume.hitmanWillBeKilled(type: .sniper) {
    return false
  }
  var p = start
  while true {
    guard let newPoint = s.at(p:p)?.neighbor(position:p, d:facing) else {
      return false
    }
    if s.hitman.position == newPoint {
      return true
    }
    let node = s.at(p:newPoint)!
    if node.hasPlant || node.hasEnemies {
      return false
    }
    p = newPoint
  }
}

func enemiesWouldKillHitman(s: GameState) -> Bool {
  let pos = s.hitman.position
  let node = s.at(p:pos)!
  if node.hasPlant {
    return false
  }
  let costume = s.hitman.costume
  for enemy in node.enemies {
    if costume.hitmanWillBeKilled(type:enemy.type) {
      return true
    }
  }
  return false
}
