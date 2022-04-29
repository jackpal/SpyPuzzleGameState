public enum Decision : CustomStringConvertible {
  case notApplicable
  case currentlyFailing
  case currentlySucceeding
  /// Reported by an exit objective when it succeded.
  case success
  /// Reported by any kind of objective when it permanently failed.
  case failure

  public var description: String {
    switch self {
    case .notApplicable:
      return "n/a"
    case .currentlyFailing:
      return "F?"
    case .currentlySucceeding:
      return "T?"
    case .success:
      return "T"
    case .failure:
      return "F"
    }
  }
}

public func &(lhs: Decision, rhs: Decision) -> Decision {
  switch (lhs,rhs) {
  case let (.notApplicable, r):
    return r
  case let (l,.notApplicable):
    return l
  case (.failure,_), (_, .failure):
    return .failure
  case (.success, .currentlyFailing), (.currentlyFailing, .success):
    return .failure
  case (.success,.currentlySucceeding),(.currentlySucceeding,.success),
    (.success, .success):
    return .success
  case (.currentlySucceeding, .currentlyFailing),
    (.currentlyFailing, .currentlySucceeding),
    (.currentlyFailing, .currentlyFailing):
    return .currentlyFailing
  case (.currentlySucceeding, .currentlySucceeding):
    return .currentlySucceeding
  }
}
