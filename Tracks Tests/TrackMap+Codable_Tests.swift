//
//  TrackMap+Codable_Tests.swift
//  Tracks Tests
//
//  Created by Arne Philipeit on 3/31/24.
//

import Base
import XCTest

@testable import Tracks

func encodeAndDecode(_ original: TrackMap) throws -> TrackMap {
    let encoder = JSONEncoder()
    let encoded = try encoder.encode(original)
    let decoder = JSONDecoder()
    return try decoder.decode(TrackMap.self, from: encoded)
}

final class TrackMap_Codable_Tests: XCTestCase {

    func testEncodesAndDecodesEmptyTrackMap() throws {
        let original = TrackMap()
        let result = try Tracks_Tests.encodeAndDecode(original)
        XCTAssert(result.tracks.isEmpty)
        XCTAssert(result.connections.isEmpty)
    }

    func testEncodesAndDecodesTrackMapWithSingleTrack() throws {
        let path: SomeFinitePath = .linear(
            LinearPath(start: Point(x: -5.0.m, y: 0.0.m), end: Point(x: +5.0.m, y: 0.0.m))!)
        let originalMap = TrackMap()
        let (originalTrack, _) = originalMap.addTrack(
            withPath: path, startConnection: .none, endConnection: .none)
        let originalTrackObserver = TestTrackObserver(for: originalTrack)

        let resultMap = try Tracks_Tests.encodeAndDecode(originalMap)
        XCTAssertEqual(resultMap.tracks.count, 1)
        XCTAssert(resultMap.connections.isEmpty)

        let resultTrack = resultMap.tracks.first!
        XCTAssertEqual(resultTrack.path, path)
        XCTAssertEqual(resultTrack.leftRail, originalTrack.leftRail)
        XCTAssertEqual(resultTrack.rightRail, originalTrack.rightRail)
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)

        XCTAssert(originalTrackObserver.calls.isEmpty)
    }

}
