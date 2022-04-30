import Foundation

public enum ParseError : Error {
  case tooManyParts
  case unknownCharacter(c: Character, x: Int, y: Int)
  case unknownEdgeCharacter(c: Character, x: Int, y: Int, d: Direction)
  case mapCharacterRowsShouldBeOdd
  case mapCharacterColsShouldBeOdd
  case noHitman
  case multipleHitmen
  case subroutineExpectedOneColon
  case subroutineRepeatedDefinition
  case unknownSubroutine(name: String)
  case statementExpectedOpenParen
  case statementExpectedCloseParen
  case unknownGameStatement(name: String)
  case unknownDirection(direction: String)
  case unknownEnemy(enemy: String)
  case unknownKeyType(keyType: String)
  case subwayArgs
  case suitArgs
  case statueExpectedDirectionArgument
  case walkwayExpectedDirectionArgument
}

public func parse(level: String) throws -> GameState {
  let parts = level.components(separatedBy: "\n\n")
  if parts.count > 2 {
    throw ParseError.tooManyParts
  }
  var subroutines = [String: [String]]()
  if parts.count > 1 {
    for subroutine in parts[1].components(separatedBy:"\n") {
      let parts = subroutine.components(separatedBy:":")
      if parts.count != 2 {
        throw ParseError.subroutineExpectedOneColon
      }
      let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
      let statements = parts[1].components(separatedBy:";").map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      if subroutines[name] != nil {
        throw ParseError.subroutineRepeatedDefinition
      }
      subroutines[name] = statements
    }
  }
  
  let rows = parts[0].components(separatedBy:"\n").map{ Array($0) }
  let maxCX = rows.map{$0.count}.max() ?? 0
  if maxCX & 1 == 0 {
    throw ParseError.mapCharacterColsShouldBeOdd
  }
  let maxCY = rows.count
  if maxCY & 1 == 0 {
    throw ParseError.mapCharacterRowsShouldBeOdd
  }
  let maxX = (maxCX + 1) / 2
  let maxY = (maxCY + 1) / 2

  func at(cx: Int, cy: Int) -> Character {
    if cx < 0 || cx >= maxCX || cy < 0 || cy >= maxCY {
      return " "
    }
    let row = rows[cy]
    if row.count <= cx {
      return " "
    }
    return row[cx]
  }
  
  func at(x: Int, y:Int) -> Character {
    at(cx:x * 2, cy:y*2)
  }
  
  // This is just 1 character around x/y, so it's for links
  func at(x: Int, y:Int, d: Direction) -> Character {
    at(cx:x * 2 + d.dx, cy:y*2 + d.dy)
  }
  
  func parse(direction: String) throws -> Direction {
    switch direction {
    case "n","north":
      return .north
    case "e","east":
      return .east
    case "s","south":
      return .south
    case "w","west":
      return .west
    default:
      throw ParseError.unknownDirection(direction: direction)
    }
  }
  
  func parse(pointArgs args: [String]) throws -> Point {
    let x = Int(args[0])!
    let y = Int(args[1])!
    return Point(x:x,y:y)
  }
  
  enum RouteParseError : Error {
    case expectedFourArgs
  }
  
  func parse(routeArgs args: [String]) throws -> Route {
    if args.count != 4 {
      throw RouteParseError.expectedFourArgs
    }
    let topLeft = try parse(pointArgs:Array(args[0..<2]))
    let bottomRight = try parse(pointArgs:Array(args[2..<4]))
    return Route(topLeft: topLeft, bottomRight: bottomRight)!
  }
  
  func parse(enemyTypeArgs args: [String], pos: Point) throws ->
  (type: EnemyType, armored: Bool, facing: Direction) {
    func dir() throws -> Direction { try parse(direction: args[1]) }
    switch args[0] {
    case "b","blue":
      return (.blue, false, try dir())
    case "B","blue_armored":
      return (.blue, true, try dir())
    case "d","dog":
      return (.dog(chasing:[]), false, try dir())
    case "g","green":
      return (.green, false, try dir())
    case "2","duo":
      return (.duo, false, try dir())
    case "f","flashlight":
      return (.flashlight, false, try dir())
    case "m", "mark":
      return (.mark, false, try dir())
    case "p", "patrol":
      let route = try parse(routeArgs:Array(args.suffix(from:1)))
      return (.patrol(route: route), false, try route.facing(p: pos, clockwise: true))
    case "s", "sniper":
      return (.sniper, false, try dir())
    case "y","yellow":
      return (.yellow, false, try dir())
    case "Y","yellow_armored":
      return (.yellow, true, try dir())

    default:
      throw ParseError.unknownEnemy(enemy: args[0])
    }
  }
  
  func parse(keyType: String) throws -> EdgeType {
    switch keyType {
    case "r","red":
      return .red
    case "b","blue":
      return .blue
    case "g","green":
      return .green
    case "y","yellow":
      return .yellow
    default:
      throw ParseError.unknownKeyType(keyType: keyType)
    }
  }
  
  func parse(edgeType: String) throws -> EdgeType? {
    switch edgeType {
    case " ":
      return nil
    case "-","|","+":
      return .open
    default:
      return try parse(keyType: edgeType)
    }
  }
  
  var nextPieceID = 1
  func item(_ type: ItemType) -> Item {
    let item = Item(id: nextPieceID, type: type)
    nextPieceID += 1
    return item
  }
  var hitman : Hitman?
  var map = NodeMap()
  for y in 0..<maxY {
    for x in 0..<maxX {
      let c = at(x: x, y: y)
      if c != " " {
        var node = Node()
        switch c {
        case "A":
          if hitman != nil {
            throw ParseError.multipleHitmen
          }
          hitman = Hitman(x:x, y:y)
        case "C":
          node.item = item(.briefcase)
        case "E":
          // Eagle pistols
          node.item = item(.pistols)
        case "G":
          node.item = item(.gun)
        case "P":
          node.item = item(.plant)
        case "R":
          node.item = item(.rock)
        case "T":
          node.type = .target
        case "W":
          node.item = item(.waitPoint)
        case "X":
          node.type = .exit
        case "a":
          if hitman != nil {
            throw ParseError.multipleHitmen
          }
          hitman = Hitman(x:x, y:y)
          hitman!.costume = .trenchcoat
        case "r":
          node.item = item(.key(type:.red))
        case "g":
          node.item = item(.key(type:.green))
        case "b":
          node.item = item(.key(type:.blue))
        case "y":
          node.item = item(.key(type:.yellow))
        case "+", "-", "|":
          // No special behavior
          break
        case "0"..."9", "α"..."ω":
          guard let statements = subroutines[String(c)] else {
            throw ParseError.unknownSubroutine(name:String(c))
          }
          for statement in statements {
            let parts = statement.components(separatedBy:"(").map {
              $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if parts.count != 2 {
              throw ParseError.statementExpectedOpenParen
            }
            let funcName = parts[0]
            let args = parts[1].components(separatedBy:")")[0].components(separatedBy:",").map {
              $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            switch funcName {
            case "briefcase":
              node.item = item(.briefcase)
            case "enemy", "e":
              let (enemyType, armored, facing) = try parse(enemyTypeArgs:args, pos:Point(x:x,y:y))
              let enemy = Enemy(id: nextPieceID, type:enemyType, armored: armored, facing: facing)
              node.enemies.append(enemy)
              nextPieceID += 1
            case "exit":
              node.type = .exit
            case "gun":
              node.item = item(.gun)
            case "hitman":
              if hitman != nil {
                throw ParseError.multipleHitmen
              }
              hitman = Hitman(x:x, y:y)
            case "key":
              let keyType = try parse(keyType:args[0])
              node.item = item(.key(type: keyType))
            case "pistols":
              node.item = item(.pistols)
            case "plant":
              node.item = item(.plant)
            case "rock":
              node.item = item(.rock)
            case "statue":
              if args.count != 1 {
                throw ParseError.statueExpectedDirectionArgument
              }
              let dir = try parse(direction: args[0])
              node.type = .statue(d: dir)
            case "subway":
              if args.count != 2 {
                throw ParseError.subwayArgs
              }
              let name = args[0]
              let peers = args[1]
              node.type = .subway(name:name, peers:peers)
            case "suit":
              if args.count != 1 {
                throw ParseError.suitArgs
              }
              let enemyType = try parse(enemyTypeArgs: [args[0],"e"], pos: Point(x:x,y:y))
              node.item = item(.suit(type:enemyType.type))
            case "target":
              node.type = .target
            case "walkway":
              if args.count != 1 {
                throw ParseError.walkwayExpectedDirectionArgument
              }
              let dir = try parse(direction: args[0])
              node.type = .walkway(d: dir)
            default:
              throw ParseError.unknownGameStatement(name:funcName)
            }
          }
          break
        default:
          throw ParseError.unknownCharacter(c: c, x: x, y: y)
        }
        for d in Direction.allCases {
          let edgeChar = at(x:x, y: y, d:d)
          do {
            if let edgeType = try parse(edgeType: String(edgeChar)) {
              node.edges[d] = edgeType
            }
          } catch {
            throw ParseError.unknownEdgeCharacter(c: edgeChar, x: x, y: y, d:d)
          }
        }
        map[Point(x:x,y:y)] = node
      }
    }
  }
  guard let hitman = hitman else {
    throw ParseError.noHitman
  }
  return GameState(map:map, hitman: hitman)
}

public func parse(objectives: String) throws -> [Objective] {
  objectives.components(separatedBy:",").map { try! parse(objective:$0)}
}

public enum ObjectiveParserError : Error {
  case unknownObjective(String)
}

public func parse(objective: String)throws -> Objective {
  switch objective {
  case "CollectBriefcase":
    return .collectBriefcase
  case "DontKillDogs":
    return .dontKillDogs
  case "KillAllEnemies":
    return .killAllEnemies
  case "KillYourMark":
    return .killYourMark
  case "LevelComplete":
    return .levelComplete
  case "NoKill":
    return .noKill
  case "SpeedKill":
    return .speedKill
  default:
    if let result = try? parse(levelCompleteWithin:objective) {
      return result
    }
    throw ObjectiveParserError.unknownObjective(objective)
  }
}

func parse(levelCompleteWithin objective: String)throws -> Objective {
  let parts = objective.components(separatedBy:"(").map {
    $0.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  if parts.count != 2 {
    throw ParseError.statementExpectedOpenParen
  }
  let name = parts[0]
  if name != "LevelCompleteWithin" {
    throw ObjectiveParserError.unknownObjective(objective)
  }
  let args = String(parts[1]).components(separatedBy:")").map {
    $0.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  if args.count != 2 {
    throw ParseError.statementExpectedCloseParen
  }

  if let turns = Int(args[0]) {
    return .levelCompleteWithin(turns: turns)
  }
  throw ObjectiveParserError.unknownObjective(objective)
}
