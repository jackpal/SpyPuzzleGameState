public typealias NodeMap = [Point: Node]

public func find(map:NodeMap, type: NodeType)->Point? {
  return find(map:map) { $0.type == type }
}

public func find(map:NodeMap, test: (Node)->Bool)->Point? {
  for (position, node) in map {
    if test(node) {
      return position
    }
  }
  return nil
}

public func findAll(map:NodeMap, test: (Node)->Bool) -> [Point] {
  var points = [Point]()
  for (position, node) in map {
      if test(node) {
        points.append(position)
    }
  }
  return points
}

public func size(map:NodeMap)-> Point {
  var size = Point.zero
  for position in map.keys {
    size.x = max(size.x, position.x)
    size.y = max(size.y, position.y)
  }
  return size
}

public func countEnemies(map: NodeMap)-> Int {
  var enemyCount = 0
  for node in map.values {
    enemyCount += node.enemies.count
  }
  return enemyCount
}

public func hasEnemies(map: NodeMap)-> Bool {
  map.values.first(where: {node in
    !node.enemies.isEmpty
  }) != nil
}

public func countDogs(map: NodeMap)-> Int {
  var dogCount = 0
  for node in map.values {
    for enemy in node.enemies {
      if case .dog = enemy.type {
        dogCount += 1
      }
    }
  }
  return dogCount
}

func targets(map: NodeMap) -> [Point] {
  findAll(map: map) { $0.type.isTargetable }.sorted(by:gridOrder)
}

public func findBriefcase(map: NodeMap)-> Point? {
  find(map: map, test: { $0.item?.type == .briefcase })
}

public func findYourMark(map: NodeMap)-> Point? {
  find(map: map, test: { $0.enemies.contains { $0.type == .mark }})
}

public func findExit(map: NodeMap)-> Point? {
  find(map:map, type: .exit)
}

public func hasExit(map: NodeMap)-> Bool {
  find(map:map, type: .exit) != nil
}

public func hasWalkways(map: NodeMap)-> Bool {
  find(map: map, test: {
    if case .walkway = $0.type {
      return true
    }
    return false
  }) != nil
}
