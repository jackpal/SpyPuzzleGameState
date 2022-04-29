import XCTest
@testable import SpyPuzzleGameState

final class ActionParserTests: XCTestCase {

    func testActionParserFire() throws {
        let actions = try parse(actions: "fire (1,2), fire (3,4)")
        XCTAssertEqual(actions, [.fire(target:Point(x:1,y:2)), .fire(target:Point(x:3,y:4))])
    }

    func testActionParserMove() throws {
        let actions = try parse(actions: "N, E, S, W")
        XCTAssertEqual(actions, [.move(d:.north),.move(d:.east),.move(d:.south),.move(d:.west)])
    }

    func testActionParserSubway() throws {
        let actions = try parse(actions: "subway a, subway z")
        XCTAssertEqual(actions, [.subway(name: "a"),.subway(name: "z")])
    }

    func testActionParserToss() throws {
        let actions = try parse(actions: "toss N,toss E,toss S,toss W")
        XCTAssertEqual(actions, [.toss(d:.north),.toss(d:.east),.toss(d:.south),.toss(d:.west)])
    }


}
