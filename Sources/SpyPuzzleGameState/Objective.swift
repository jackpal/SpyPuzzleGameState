public enum Objective : CustomStringConvertible {
  case collectBriefcase
  case dontKillDogs
  case killYourMark
  case killAllEnemies
  case levelComplete
  case levelCompleteWithin(turns:Int)
  case noKill
  case speedKill
  
  public var description: String {
    switch self {
    case .collectBriefcase:
      return "Collect Briefcase"
    case .dontKillDogs:
      return "Don't Kill Dogs"
    case .killYourMark:
      return "Kill Your Mark"
    case .killAllEnemies:
      return "Kill All Enemies"
    case .levelComplete:
      return "Level Complete"
    case let .levelCompleteWithin(turns):
      return "\(turns) Turns or Fewer"
    case .noKill:
      return "No Kill"
    case .speedKill:
      return "Speed Kill"
    }
  }
}

public extension Objective {
  
  func judge(initial: GameState,
             current: GameState,
             turns: Int) -> Decision {
    switch self {
    case .collectBriefcase:
      if current.hitman.hasBriefcase {
        return .currentlySucceeding
      }
      if findBriefcase(map: current.map) == nil {
        return .notApplicable
      }
      return .currentlyFailing
      
    case .dontKillDogs:
      let initialDogCount = countDogs(map:initial.map)
      if initialDogCount == 0 {
        return .notApplicable
      }
      let currentDogCount = countDogs(map:current.map)
      assert(currentDogCount <= initialDogCount)
      if currentDogCount == initialDogCount {
        return .currentlySucceeding
      }
      return .failure
      
    case .killYourMark:
      if findYourMark(map:initial.map) == nil {
        return .notApplicable
      }
      if findYourMark(map: current.map) == nil {
        return .success
      }
      return .currentlyFailing
      
    case .killAllEnemies:
      if countEnemies(map:initial.map) == 0 {
        return .notApplicable
      }
      if countEnemies(map: current.map) == 0 {
        return .currentlySucceeding
      }
      return .currentlyFailing
      
    case .levelComplete:
      guard let exit = findExit(map:initial.map) else {
        return .notApplicable
      }
      if exit == current.hitman.position {
        return .success
      }
      return .currentlyFailing

    case let .levelCompleteWithin(turnsLimit):
      guard let exit = findExit(map:initial.map) else {
        return .notApplicable
      }
      if exit == current.hitman.position {
        if turns <= turnsLimit {
          return .success
        } else {
          return .failure
        }
      }
      return .currentlyFailing

    case .noKill:
      let initialEnemies = countEnemies(map:initial.map)
      if initialEnemies == 0 {
        return .notApplicable
      }
      if countEnemies(map: current.map) == initialEnemies {
        return .currentlySucceeding
      }
      return .failure
      
    case .speedKill:
      if !(hasEnemies(map: initial.map) && hasWalkways(map: initial.map)) {
        return .notApplicable
      }
      if current.hitman.speedKill {
        return .currentlySucceeding
      }
      return .currentlyFailing
    }
  }
  
}
