import XCTest
@testable import SpyPuzzleGameState

final class ParserTests: XCTestCase {

  func testParseSimpleLevel() throws {
    let state = try parse(level: "A-X")
    let hitman = Hitman(x: 0, y: 0)
    var a = Node()
    a.edges[.east] = .open
    var b = Node(type:.exit)
    b.edges[.west] = .open
    let map : NodeMap = [
      Point(x:0,y:0) : a,
      Point(x:1,y:0) : b
    ]
    let expectedState = GameState(map:map, hitman: hitman)
    XCTAssertEqual(state, expectedState)
  }

  func testParseSubroutineNames() throws {
    let state = try parse(level: "A-G-X")
    let state2 = try parse(level: "0-1-9\n\n0: hitman()\n1: gun()\n9: exit()")
    XCTAssertEqual(state, state2)
  }

  func testParseSubroutineGreekNames() throws {
    let state = try parse(level: "A-G-X")
    let state2 = try parse(level: "α-β-ω\n\nα: hitman()\nβ: gun()\nω: exit()")
    XCTAssertEqual(state, state2)
  }

}
