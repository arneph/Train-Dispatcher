//
//  Tracks_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/26/24.
//

@testable import Train_Dispatcher

import XCTest

final class Tracks_Tests: XCTestCase {
    
    func testAddsSingleTrack() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                              end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)
        
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === track)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(track.path, .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                      end: Point(x: +5.0.m, y: 0.0.m))!))
        XCTAssertEqual(track.leftRail, .linear(LinearPath(start: Point(x: -5.0.m, y: +0.7425.m),
                                                          end: Point(x: +5.0.m, y: +0.7425.m))!))
        XCTAssertEqual(track.rightRail, .linear(LinearPath(start: Point(x: -5.0.m, y: -0.7425.m),
                                                           end: Point(x: +5.0.m, y: -0.7425.m))!))
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track, map),
        ])
        XCTAssert(trackObserver.calls.isEmpty)
    }
    
    func testRemovesSingleTrack() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                              end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)
        map.remove(oldTrack: track)
        
        XCTAssert(map.tracks.isEmpty)
        XCTAssert(map.connections.isEmpty)
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track, map),
            .removedTrack(track, map),
        ])
        XCTAssertEqual(trackObserver.calls, [
            .removed(track),
        ])
    }
    
    func testConnectsTrackStartAndTrackStartWithLinearPath() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                               end: Point(x: -15.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: +5.0.m, y: 0.0.m),
                                                               end: Point(x: +15.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        let resultTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                   end: Point(x: +5.0.m, y: 0.0.m))!),
                                       startConnection: .toExistingTrack(track1, .start),
                                       endConnection: .toExistingTrack(track2, .start))
        let resultTrackObserver = TestTrackObserver(for: resultTrack)
        
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === resultTrack)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(resultTrack.path,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: 0.0.m),
                                          end: Point(x: +15.0.m, y: 0.0.m))!))
        XCTAssertEqual(resultTrack.leftRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: +0.7425.m),
                                          end: Point(x: +15.0.m, y: +0.7425.m))!))
        XCTAssertEqual(resultTrack.rightRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: -0.7425.m),
                                          end: Point(x: +15.0.m, y: -0.7425.m))!))
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)
        XCTAssertNil(track1.startConnection)
        XCTAssertNil(track1.endConnection)
        XCTAssertNil(track2.startConnection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .replacedTrack(track1, [resultTrack], map),
            .replacedTrack(track2, [resultTrack], map),
        ])
        XCTAssert(resultTrackObserver.calls.isEmpty)
        XCTAssertEqual(track1Observer.calls, [
            .replaced(track1, [resultTrack], { (resultTrack, 10.0.m - $0) })
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [resultTrack], { (resultTrack, $0 + 20.0.m) })
        ])
    }
    
    func testConnectsTrackStartAndTrackEndWithLinearPath() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                               end: Point(x: -15.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: +15.0.m, y: 0.0.m),
                                                               end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        let resultTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                   end: Point(x: +5.0.m, y: 0.0.m))!),
                                       startConnection: .toExistingTrack(track1, .start),
                                       endConnection: .toExistingTrack(track2, .end))
        let resultTrackObserver = TestTrackObserver(for: resultTrack)
        
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === resultTrack)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(resultTrack.path,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: 0.0.m),
                                          end: Point(x: +15.0.m, y: 0.0.m))!))
        XCTAssertEqual(resultTrack.leftRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: +0.7425.m),
                                          end: Point(x: +15.0.m, y: +0.7425.m))!))
        XCTAssertEqual(resultTrack.rightRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: -0.7425.m),
                                          end: Point(x: +15.0.m, y: -0.7425.m))!))
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)
        XCTAssertNil(track1.startConnection)
        XCTAssertNil(track1.endConnection)
        XCTAssertNil(track2.startConnection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .replacedTrack(track1, [resultTrack], map),
            .replacedTrack(track2, [resultTrack], map),
        ])
        XCTAssert(resultTrackObserver.calls.isEmpty)
        XCTAssertEqual(track1Observer.calls, [
            .replaced(track1, [resultTrack], { (resultTrack, 10.0.m - $0) })
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [resultTrack], { (resultTrack, 30.0.m - $0) })
        ])
    }
    
    func testConnectsTrackEndAndTrackStartWithLinearPath() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -15.0.m, y: 0.0.m),
                                                               end: Point(x: -5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: +5.0.m, y: 0.0.m),
                                                               end: Point(x: +15.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        let resultTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                   end: Point(x: +5.0.m, y: 0.0.m))!),
                                       startConnection: .toExistingTrack(track1, .end),
                                       endConnection: .toExistingTrack(track2, .start))
        let resultTrackObserver = TestTrackObserver(for: resultTrack)
        
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === resultTrack)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(resultTrack.path,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: 0.0.m),
                                          end: Point(x: +15.0.m, y: 0.0.m))!))
        XCTAssertEqual(resultTrack.leftRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: +0.7425.m),
                                          end: Point(x: +15.0.m, y: +0.7425.m))!))
        XCTAssertEqual(resultTrack.rightRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: -0.7425.m),
                                          end: Point(x: +15.0.m, y: -0.7425.m))!))
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)
        XCTAssertNil(track1.startConnection)
        XCTAssertNil(track1.endConnection)
        XCTAssertNil(track2.startConnection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .replacedTrack(track1, [resultTrack], map),
            .replacedTrack(track2, [resultTrack], map),
        ])
        XCTAssert(resultTrackObserver.calls.isEmpty)
        XCTAssertEqual(track1Observer.calls, [
            .replaced(track1, [resultTrack], { (resultTrack, $0) })
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [resultTrack], { (resultTrack, $0 + 20.0.m) })
        ])
    }
    
    func testConnectsTrackEndAndTrackEndWithLinearPath() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -15.0.m, y: 0.0.m),
                                                               end: Point(x: -5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: +15.0.m, y: 0.0.m),
                                                               end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        let resultTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                   end: Point(x: +5.0.m, y: 0.0.m))!),
                                       startConnection: .toExistingTrack(track1, .end),
                                       endConnection: .toExistingTrack(track2, .end))
        let resultTrackObserver = TestTrackObserver(for: resultTrack)
        
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === resultTrack)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(resultTrack.path,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: 0.0.m),
                                          end: Point(x: +15.0.m, y: 0.0.m))!))
        XCTAssertEqual(resultTrack.leftRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: +0.7425.m),
                                          end: Point(x: +15.0.m, y: +0.7425.m))!))
        XCTAssertEqual(resultTrack.rightRail,
                       .linear(LinearPath(start: Point(x: -15.0.m, y: -0.7425.m),
                                          end: Point(x: +15.0.m, y: -0.7425.m))!))
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)
        XCTAssertNil(track1.startConnection)
        XCTAssertNil(track1.endConnection)
        XCTAssertNil(track2.startConnection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .replacedTrack(track1, [resultTrack], map),
            .replacedTrack(track2, [resultTrack], map),
        ])
        XCTAssert(resultTrackObserver.calls.isEmpty)
        XCTAssertEqual(track1Observer.calls, [
            .replaced(track1, [resultTrack], { (resultTrack, $0) })
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [resultTrack], { (resultTrack, 30.0.m - $0) })
        ])
    }
    
    func testConnectsTracksWithCircularPath() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -20.0.m, y: 0.0.m),
                                                               end: Point(x: 0.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 200.0.m, y: 220.0.m),
                                   end: Point(x: 200.0.m, y: 200.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        let resultTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 0.0.m, y: 200.0.m),
                                       radius: 200.0.m,
                                       startAngle: CircleAngle(-90.0.deg),
                                       endAngle: CircleAngle(0.0.deg),
                                       direction: .positive)!),
                                       startConnection: .toExistingTrack(track1, .end),
                                       endConnection: .toExistingTrack(track2, .end))
        let resultTrackObserver = TestTrackObserver(for: resultTrack)
        
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === resultTrack)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(resultTrack.path, .compound(CompoundPath(components: [
            .linear(LinearPath(start: Point(x: -20.0.m, y: 0.0.m),
                               end: Point(x: 0.0.m, y: 0.0.m))!),
            .circular(CircularPath(center: Point(x: 0.0.m, y: 200.0.m),
                                   radius: 200.0.m,
                                   startAngle: CircleAngle(-90.0.deg),
                                   endAngle: CircleAngle(0.0.deg),
                                   direction: .positive)!),
            .linear(LinearPath(start: Point(x: 200.0.m, y: 200.0.m),
                               end: Point(x: 200.0.m, y: 220.0.m))!),
        ])!))
        XCTAssertEqual(resultTrack.leftRail.finitePathType, .compound)
        XCTAssertEqual(resultTrack.rightRail.finitePathType, .compound)
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)
        XCTAssertNil(track1.startConnection)
        XCTAssertNil(track1.endConnection)
        XCTAssertNil(track2.startConnection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .replacedTrack(track1, [resultTrack], map),
            .replacedTrack(track2, [resultTrack], map),
        ])
        XCTAssert(resultTrackObserver.calls.isEmpty)
        XCTAssertEqual(track1Observer.calls, [
            .replaced(track1, [resultTrack], { (resultTrack, $0) })
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [resultTrack], 
                      { (resultTrack, 40.0.m + 90.0.deg.withoutUnit * 200.0.m - $0) })
        ])
    }
    
    func testExtendsTrackStartWithPathStart() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                              end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)
        let resultTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: -5.0.m, y: 99.0.m),
                                       radius: 99.0.m,
                                       startAngle: CircleAngle(-90.0.deg),
                                       endAngle: CircleAngle(-160.0.deg),
                                       direction: .negative)!),
                                       startConnection: .toExistingTrack(track, .start),
                                       endConnection: .none)
        XCTAssert(track === resultTrack)
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === track)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(track.path, .compound(CompoundPath(components: [
            .circular(CircularPath(center: Point(x: -5.0.m, y: 99.0.m),
                                   radius: 99.0.m,
                                   startAngle: CircleAngle(-160.0.deg),
                                   endAngle: CircleAngle(-90.0.deg),
                                   direction: .positive)!),
            .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                               end: Point(x: +5.0.m, y: 0.0.m))!),
        ])!))
        XCTAssertEqual(track.leftRail, .compound(CompoundPath(components: [
            .circular(CircularPath(center: Point(x: -5.0.m, y: 99.0.m),
                                   radius: 98.2575.m,
                                   startAngle: CircleAngle(-160.0.deg),
                                   endAngle: CircleAngle(-90.0.deg),
                                   direction: .positive)!),
            .linear(LinearPath(start: Point(x: -5.0.m, y: +0.7425.m),
                               end: Point(x: +5.0.m, y: +0.7425.m))!),
        ])!))
        XCTAssertEqual(track.rightRail, .compound(CompoundPath(components: [
            .circular(CircularPath(center: Point(x: -5.0.m, y: 99.0.m),
                                   radius: 99.7425.m,
                                   startAngle: CircleAngle(-160.0.deg),
                                   endAngle: CircleAngle(-90.0.deg),
                                   direction: .positive)!),
            .linear(LinearPath(start: Point(x: -5.0.m, y: -0.7425.m),
                               end: Point(x: +5.0.m, y: -0.7425.m))!),
        ])!))
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track, map),
            .trackChanged(track, map),
        ])
        XCTAssertEqual(trackObserver.calls, [
            .pathChanged(track, { $0 + 70.0.deg.withoutUnit * 99.0.m }),
        ])
    }
    
    func testExtendsTrackStartWithPathEnd() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                              end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)
        let resultTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: -5.0.m, y: 99.0.m),
                                       radius: 99.0.m,
                                       startAngle: CircleAngle(-160.0.deg),
                                       endAngle: CircleAngle(-90.0.deg),
                                       direction: .positive)!),
                                       startConnection: .none,
                                       endConnection: .toExistingTrack(track, .start))
        XCTAssert(track === resultTrack)
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === track)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(track.path, .compound(CompoundPath(components: [
            .circular(CircularPath(center: Point(x: -5.0.m, y: 99.0.m),
                                   radius: 99.0.m,
                                   startAngle: CircleAngle(-160.0.deg),
                                   endAngle: CircleAngle(-90.0.deg),
                                   direction: .positive)!),
            .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                               end: Point(x: +5.0.m, y: 0.0.m))!),
        ])!))
        XCTAssertEqual(track.leftRail.finitePathType, .compound)
        XCTAssertEqual(track.rightRail.finitePathType, .compound)
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track, map),
            .trackChanged(track, map),
        ])
        XCTAssertEqual(trackObserver.calls, [
            .pathChanged(track, { $0 + 70.0.deg.withoutUnit * 99.0.m }),
        ])
    }
    
    func testExtendsTrackEndWithPathStart() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                              end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)
        let resultTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: +5.0.m, y: 99.0.m),
                                       radius: 99.0.m,
                                       startAngle: CircleAngle(-90.0.deg),
                                       endAngle: CircleAngle(-10.0.deg),
                                       direction: .positive)!),
                                       startConnection: .toExistingTrack(track, .end),
                                       endConnection: .none)
        XCTAssert(track === resultTrack)
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === track)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(track.path, .compound(CompoundPath(components: [
            .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                               end: Point(x: +5.0.m, y: 0.0.m))!),
            .circular(CircularPath(center: Point(x: +5.0.m, y: 99.0.m),
                                   radius: 99.0.m,
                                   startAngle: CircleAngle(-90.0.deg),
                                   endAngle: CircleAngle(-10.0.deg),
                                   direction: .positive)!),
        ])!))
        XCTAssertEqual(track.leftRail.finitePathType, .compound)
        XCTAssertEqual(track.rightRail.finitePathType, .compound)
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track, map),
            .trackChanged(track, map),
        ])
        XCTAssertEqual(trackObserver.calls, [
            .pathChanged(track, { $0 }),
        ])
    }
    
    func testExtendsTrackEndWithPathEnd() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track = map.addTrack(withPath: .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                              end: Point(x: +5.0.m, y: 0.0.m))!),
                                 startConnection: .none,
                                 endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)
        let resultTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: +5.0.m, y: 99.0.m),
                                       radius: 99.0.m,
                                       startAngle: CircleAngle(-10.0.deg),
                                       endAngle: CircleAngle(-90.0.deg),
                                       direction: .negative)!),
                                       startConnection: .none,
                                       endConnection: .toExistingTrack(track, .end))
        XCTAssert(track === resultTrack)
        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.first! === track)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(track.path, .compound(CompoundPath(components: [
            .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                               end: Point(x: +5.0.m, y: 0.0.m))!),
            .circular(CircularPath(center: Point(x: +5.0.m, y: 99.0.m),
                                   radius: 99.0.m,
                                   startAngle: CircleAngle(-90.0.deg),
                                   endAngle: CircleAngle(-10.0.deg),
                                   direction: .positive)!),
        ])!))
        XCTAssertEqual(track.leftRail.finitePathType, .compound)
        XCTAssertEqual(track.rightRail.finitePathType, .compound)
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track, map),
            .trackChanged(track, map),
        ])
        XCTAssertEqual(trackObserver.calls, [
            .pathChanged(track, { $0 }),
        ])
    }
    
    func testAddsTrackToNewConnectionAtStart() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let oldTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -10.0.m, y: -50.0.m),
                                   end: Point(x: -10.0.m, y: 50.0.m))!),
                                         startConnection: .none,
                                         endConnection: .none)
        let oldTrackObserver = TestTrackObserver(for: oldTrack)
        let newTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 60.0.m, y: 0.0.m),
                                       radius: 70.0.m,
                                       startAngle: CircleAngle(-180.0.deg),
                                       endAngle: CircleAngle(+100.0.deg),
                                       direction: .negative)!),
                                    startConnection: .toNewConnection(oldTrack, 50.0.m),
                                    endConnection: .none)
        let newTrackObserver = TestTrackObserver(for: newTrack)
        
        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertFalse(map.tracks.contains{ $0 === oldTrack })
        XCTAssert(map.tracks.contains{ $0 === newTrack })
        let splitTrack1 = map.tracks.filter{ $0 !== newTrack }[0]
        let splitTrack1Observer = TestTrackObserver(for: splitTrack1)
        let splitTrack2 = map.tracks.filter{ $0 !== newTrack }[1]
        let splitTrack2Observer = TestTrackObserver(for: splitTrack2)
        XCTAssertEqual(map.connections.count, 1)
        let newConnection = map.connections.first!
        let newConnectionObserver = TestTrackConnectionObserver(for: newConnection)
        
        XCTAssertEqual(newTrack.path, .circular(CircularPath(center: Point(x: 60.0.m, y: 0.0.m),
                                                             radius: 70.0.m,
                                                             startAngle: CircleAngle(180.0.deg),
                                                             endAngle: CircleAngle(100.0.deg),
                                                             direction: .negative)!))
        XCTAssert(newTrack.startConnection === newConnection)
        XCTAssertNil(newTrack.endConnection)
        XCTAssertEqual(splitTrack1.path, .linear(LinearPath(start: Point(x: -10.0.m, y: -50.0.m),
                                                            end: Point(x: -10.0.m, y: 0.0.m))!))
        XCTAssertNil(splitTrack1.startConnection)
        XCTAssert(splitTrack1.endConnection === newConnection)
        XCTAssertEqual(splitTrack2.path, .linear(LinearPath(start: Point(x: -10.0.m, y: 0.0.m),
                                                            end: Point(x: -10.0.m, y: +50.0.m))!))
        XCTAssert(splitTrack2.startConnection === newConnection)
        XCTAssertNil(splitTrack2.endConnection)
        
        XCTAssertEqual(newConnection.point, Point(x: -10.0.m, y: 0.0.m))
        XCTAssertEqual(newConnection.directionA, CircleAngle(+90.0.deg))
        XCTAssertEqual(newConnection.directionB, CircleAngle(-90.0.deg))
        XCTAssertEqual(newConnection.directionATracks.count, 2)
        XCTAssertEqual(newConnection.directionBTracks.count, 1)
        XCTAssert(newConnection.directionATracks[0] === splitTrack2)
        XCTAssert(newConnection.directionATracks[1] === newTrack)
        XCTAssert(newConnection.directionBTracks[0] === splitTrack1)
        
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(oldTrack, map),
            .replacedTrack(oldTrack, [splitTrack1, splitTrack2], map),
            .addedConnection(newConnection, map),
            .addedTrack(newTrack, map),
        ])
        XCTAssertEqual(oldTrackObserver.calls, [
            .replaced(oldTrack, [splitTrack1, splitTrack2], { (x) in
                x < 50.0.m ? (splitTrack1, x) : (splitTrack2, x - 50.0.m)
            })
        ])
        XCTAssert(splitTrack1Observer.calls.isEmpty)
        XCTAssert(splitTrack2Observer.calls.isEmpty)
        XCTAssert(newTrackObserver.calls.isEmpty)
        XCTAssert(newConnectionObserver.calls.isEmpty)
    }
    
    func testAddsTrackToNewConnectionAtEnd() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let oldTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -10.0.m, y: -25.0.m),
                                   end: Point(x: -10.0.m, y: 75.0.m))!),
                                         startConnection: .none,
                                         endConnection: .none)
        let oldTrackObserver = TestTrackObserver(for: oldTrack)
        let newTrack = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 60.0.m, y: 0.0.m),
                                       radius: 70.0.m,
                                       startAngle: CircleAngle(100.0.deg),
                                       endAngle: CircleAngle(180.0.deg),
                                       direction: .positive)!),
                                    startConnection: .none,
                                    endConnection: .toNewConnection(oldTrack, 25.0.m))
        let newTrackObserver = TestTrackObserver(for: newTrack)
        
        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertFalse(map.tracks.contains{ $0 === oldTrack })
        XCTAssert(map.tracks.contains{ $0 === newTrack })
        let splitTrack1 = map.tracks.filter{ $0 !== newTrack }[0]
        let splitTrack1Observer = TestTrackObserver(for: splitTrack1)
        let splitTrack2 = map.tracks.filter{ $0 !== newTrack }[1]
        let splitTrack2Observer = TestTrackObserver(for: splitTrack2)
        XCTAssertEqual(map.connections.count, 1)
        let newConnection = map.connections.first!
        let newConnectionObserver = TestTrackConnectionObserver(for: newConnection)
        
        XCTAssertEqual(newTrack.path, .circular(CircularPath(center: Point(x: 60.0.m, y: 0.0.m),
                                                             radius: 70.0.m,
                                                             startAngle: CircleAngle(100.0.deg),
                                                             endAngle: CircleAngle(180.0.deg),
                                                             direction: .positive)!))
        XCTAssertNil(newTrack.startConnection)
        XCTAssert(newTrack.endConnection === newConnection)
        XCTAssertEqual(splitTrack1.path, .linear(LinearPath(start: Point(x: -10.0.m, y: -25.0.m),
                                                            end: Point(x: -10.0.m, y: 0.0.m))!))
        XCTAssertNil(splitTrack1.startConnection)
        XCTAssert(splitTrack1.endConnection === newConnection)
        XCTAssertEqual(splitTrack2.path, .linear(LinearPath(start: Point(x: -10.0.m, y: 0.0.m),
                                                            end: Point(x: -10.0.m, y: +75.0.m))!))
        XCTAssert(splitTrack2.startConnection === newConnection)
        XCTAssertNil(splitTrack2.endConnection)
        
        XCTAssertEqual(newConnection.point, Point(x: -10.0.m, y: 0.0.m))
        XCTAssertEqual(newConnection.directionA, CircleAngle(+90.0.deg))
        XCTAssertEqual(newConnection.directionB, CircleAngle(-90.0.deg))
        XCTAssertEqual(newConnection.directionATracks.count, 2)
        XCTAssertEqual(newConnection.directionBTracks.count, 1)
        XCTAssert(newConnection.directionATracks[0] === splitTrack2)
        XCTAssert(newConnection.directionATracks[1] === newTrack)
        XCTAssert(newConnection.directionBTracks[0] === splitTrack1)
        
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(oldTrack, map),
            .replacedTrack(oldTrack, [splitTrack1, splitTrack2], map),
            .addedConnection(newConnection, map),
            .addedTrack(newTrack, map),
        ])
        XCTAssertEqual(oldTrackObserver.calls, [
            .replaced(oldTrack, [splitTrack1, splitTrack2], { (x) in
                x < 25.0.m ? (splitTrack1, x) : (splitTrack2, x - 25.0.m)
            })
        ])
        XCTAssert(splitTrack1Observer.calls.isEmpty)
        XCTAssert(splitTrack2Observer.calls.isEmpty)
        XCTAssert(newTrackObserver.calls.isEmpty)
        XCTAssert(newConnectionObserver.calls.isEmpty)
    }
    
    func testAddsTrackToExistingConnectionAtStart() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let tmpTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -40.0.m, y: 10.0.m),
                                   end: Point(x: 60.0.m, y: 10.0.m))!),
                                    startConnection: .none,
                                    endConnection: .none)
        let curve1 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 25.0.m, y: 160.0.m),
                                       radius: 150.0.m,
                                       startAngle: CircleAngle(-90.0.deg),
                                       endAngle: CircleAngle(-60.0.deg),
                                       direction: .positive)!),
                                  startConnection: .toNewConnection(tmpTrack, 65.0.m),
                                  endConnection: .none)
        let curve1Observer = TestTrackObserver(for: curve1)
        
        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertEqual(map.tracks[0].path.finitePathType, .linear)
        let straight1 = map.tracks[0]
        let straight1Observer = TestTrackObserver(for: straight1)
        XCTAssertEqual(map.tracks[1].path.finitePathType, .linear)
        let straight2 = map.tracks[1]
        let straight2Observer = TestTrackObserver(for: straight2)
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections.first!
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        let curve2 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 25.0.m, y: -110.0.m),
                                       radius: 120.0.m,
                                       startAngle: CircleAngle(90.0.deg),
                                       endAngle: CircleAngle(120.0.deg),
                                       direction: .positive)!),
                                  startConnection: .toExistingConnection(connection),
                                  endConnection: .none)
        let curve2Observer = TestTrackObserver(for: curve2)
        
        XCTAssertEqual(map.tracks.count, 4)
        XCTAssert(map.tracks[0] === straight1)
        XCTAssert(map.tracks[1] === straight2)
        XCTAssert(map.tracks[2] === curve1)
        XCTAssert(map.tracks[3] === curve2)
        XCTAssertEqual(map.connections.count, 1)
        XCTAssert(map.connections[0] === connection)
        XCTAssertEqual(straight1.path, .linear(LinearPath(start: Point(x: -40.0.m, y: 10.0.m),
                                                          end: Point(x: 25.0.m, y: 10.0.m))!))
        XCTAssertNil(straight1.startConnection)
        XCTAssert(straight1.endConnection === connection)
        XCTAssertEqual(straight2.path, .linear(LinearPath(start: Point(x: 25.0.m, y: 10.0.m),
                                                          end: Point(x: 60.0.m, y: 10.0.m))!))
        XCTAssert(straight2.startConnection === connection)
        XCTAssertNil(straight2.endConnection)
        XCTAssertEqual(curve1.path,
                       .circular(CircularPath(center: Point(x: 25.0.m, y: 160.0.m),
                                              radius: 150.0.m,
                                              startAngle: CircleAngle(-90.0.deg),
                                              endAngle: CircleAngle(-60.0.deg),
                                              direction: .positive)!))
        XCTAssert(curve1.startConnection === connection)
        XCTAssertNil(curve1.endConnection)
        XCTAssertEqual(curve2.path, 
                       .circular(CircularPath(center: Point(x: 25.0.m, y: -110.0.m),
                                              radius: 120.0.m,
                                              startAngle: CircleAngle(90.0.deg),
                                              endAngle: CircleAngle(120.0.deg),
                                              direction: .positive)!))
        XCTAssert(curve2.startConnection === connection)
        XCTAssertNil(curve2.endConnection)
        XCTAssertEqual(connection.point, Point(x: 25.0.m, y: 10.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(0.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(-180.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 2)
        XCTAssertEqual(connection.directionBTracks.count, 2)
        XCTAssert(connection.directionATracks[0] === straight2)
        XCTAssert(connection.directionATracks[1] === curve1)
        XCTAssert(connection.directionBTracks[0] === straight1)
        XCTAssert(connection.directionBTracks[1] === curve2)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(tmpTrack, map),
            .replacedTrack(tmpTrack, [straight1, straight2], map),
            .addedConnection(connection, map),
            .addedTrack(curve1, map),
            .connectionChanged(connection, map),
            .addedTrack(curve2, map),
        ])
        XCTAssert(straight1Observer.calls.isEmpty)
        XCTAssert(straight2Observer.calls.isEmpty)
        XCTAssert(curve1Observer.calls.isEmpty)
        XCTAssert(curve2Observer.calls.isEmpty)
        XCTAssertEqual(connectionObserver.calls, [
            .addedTrack(curve2, connection, .b),
        ])
    }
    
    func testAddsTrackToExistingConnectionAtEnd() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let tmpTrack = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: -40.0.m, y: 10.0.m),
                                   end: Point(x: 60.0.m, y: 10.0.m))!),
                                    startConnection: .none,
                                    endConnection: .none)
        let curve1 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 25.0.m, y: 160.0.m),
                                       radius: 150.0.m,
                                       startAngle: CircleAngle(-90.0.deg),
                                       endAngle: CircleAngle(-60.0.deg),
                                       direction: .positive)!),
                                  startConnection: .toNewConnection(tmpTrack, 65.0.m),
                                  endConnection: .none)
        let curve1Observer = TestTrackObserver(for: curve1)
        
        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertEqual(map.tracks[0].path.finitePathType, .linear)
        let straight1 = map.tracks[0]
        let straight1Observer = TestTrackObserver(for: straight1)
        XCTAssertEqual(map.tracks[1].path.finitePathType, .linear)
        let straight2 = map.tracks[1]
        let straight2Observer = TestTrackObserver(for: straight2)
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections.first!
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        let curve2 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 25.0.m, y: -110.0.m),
                                       radius: 120.0.m,
                                       startAngle: CircleAngle(60.0.deg),
                                       endAngle: CircleAngle(90.0.deg),
                                       direction: .positive)!),
                                  startConnection: .none,
                                  endConnection: .toExistingConnection(connection))
        let curve2Observer = TestTrackObserver(for: curve2)
        
        XCTAssertEqual(map.tracks.count, 4)
        XCTAssert(map.tracks[0] === straight1)
        XCTAssert(map.tracks[1] === straight2)
        XCTAssert(map.tracks[2] === curve1)
        XCTAssert(map.tracks[3] === curve2)
        XCTAssertEqual(map.connections.count, 1)
        XCTAssert(map.connections[0] === connection)
        XCTAssertEqual(straight1.path, .linear(LinearPath(start: Point(x: -40.0.m, y: 10.0.m),
                                                          end: Point(x: 25.0.m, y: 10.0.m))!))
        XCTAssertNil(straight1.startConnection)
        XCTAssert(straight1.endConnection === connection)
        XCTAssertEqual(straight2.path, .linear(LinearPath(start: Point(x: 25.0.m, y: 10.0.m),
                                                          end: Point(x: 60.0.m, y: 10.0.m))!))
        XCTAssert(straight2.startConnection === connection)
        XCTAssertNil(straight2.endConnection)
        XCTAssertEqual(curve1.path,
                       .circular(CircularPath(center: Point(x: 25.0.m, y: 160.0.m),
                                              radius: 150.0.m,
                                              startAngle: CircleAngle(-90.0.deg),
                                              endAngle: CircleAngle(-60.0.deg),
                                              direction: .positive)!))
        XCTAssert(curve1.startConnection === connection)
        XCTAssertNil(curve1.endConnection)
        XCTAssertEqual(curve2.path,
                       .circular(CircularPath(center: Point(x: 25.0.m, y: -110.0.m),
                                              radius: 120.0.m,
                                              startAngle: CircleAngle(60.0.deg),
                                              endAngle: CircleAngle(90.0.deg),
                                              direction: .positive)!))
        XCTAssertNil(curve2.startConnection)
        XCTAssert(curve2.endConnection === connection)
        XCTAssertEqual(connection.point, Point(x: 25.0.m, y: 10.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(0.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(-180.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 3)
        XCTAssertEqual(connection.directionBTracks.count, 1)
        XCTAssert(connection.directionATracks[0] === straight2)
        XCTAssert(connection.directionATracks[1] === curve1)
        XCTAssert(connection.directionATracks[2] === curve2)
        XCTAssert(connection.directionBTracks[0] === straight1)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(tmpTrack, map),
            .replacedTrack(tmpTrack, [straight1, straight2], map),
            .addedConnection(connection, map),
            .addedTrack(curve1, map),
            .connectionChanged(connection, map),
            .addedTrack(curve2, map),
        ])
        XCTAssert(straight1Observer.calls.isEmpty)
        XCTAssert(straight2Observer.calls.isEmpty)
        XCTAssert(curve1Observer.calls.isEmpty)
        XCTAssert(curve2Observer.calls.isEmpty)
        XCTAssertEqual(connectionObserver.calls, [
            .addedTrack(curve2, connection, .a),
        ])
    }
    
    func testExtendsTrackStartToNewConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 50.0.m, y: 30.0.m),
                                   end: Point(x: 10.0.m, y: 30.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 170.0.m, y: 40.0.m),
                                   end: Point(x: 170.0.m, y: 180.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        
        let result = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 50.0.m, y: 150.0.m),
                                       radius: 120.0.m,
                                       startAngle: CircleAngle(0.0.deg),
                                       endAngle: CircleAngle(-90.0.deg),
                                       direction: .negative)!),
                                  startConnection: .toNewConnection(track2, 110.0.m),
                                  endConnection: .toExistingTrack(track1, .start))
        
        XCTAssert(track1 === result)
        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertFalse(map.tracks.contains{ $0 === track2 })
        XCTAssert(map.tracks[0] === track1)
        let track3 = map.tracks[1]
        let track3Observer = TestTrackObserver(for: track3)
        let track4 = map.tracks[2]
        let track4Observer = TestTrackObserver(for: track4)
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        XCTAssertEqual(track1.path, .compound(CompoundPath(components: [
            .circular(CircularPath(center: Point(x: 50.0.m, y: 150.0.m),
                                   radius: 120.0.m,
                                   startAngle: CircleAngle(0.0.deg),
                                   endAngle: CircleAngle(-90.0.deg),
                                   direction: .negative)!),
            .linear(LinearPath(start: Point(x: 50.0.m, y: 30.0.m),
                               end: Point(x: 10.0.m, y: 30.0.m))!),
        ])!))
        XCTAssert(track1.startConnection === connection)
        XCTAssertNil(track1.endConnection)
        XCTAssertEqual(track3.path, .linear(LinearPath(start: Point(x: 170.0.m, y: 40.0.m),
                                                       end: Point(x: 170.0.m, y: 150.0.m))!))
        XCTAssertNil(track3.startConnection)
        XCTAssert(track3.endConnection === connection)
        XCTAssertEqual(track4.path, .linear(LinearPath(start: Point(x: 170.0.m, y: 150.0.m),
                                                       end: Point(x: 170.0.m, y: 180.0.m))!))
        XCTAssert(track4.startConnection === connection)
        XCTAssertNil(track4.endConnection)
        XCTAssertEqual(connection.point, Point(x: 170.0.m, y: 150.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(+90.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(-90.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 1)
        XCTAssertEqual(connection.directionBTracks.count, 2)
        XCTAssert(connection.directionATracks[0] === track4)
        XCTAssert(connection.directionBTracks[0] === track3)
        XCTAssert(connection.directionBTracks[1] === track1)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .trackChanged(track1, map),
            .replacedTrack(track2, [track3, track4], map),
            .addedConnection(connection, map),
        ])
        XCTAssertEqual(track1Observer.calls, [
            .pathChanged(track1, { $0 + 90.0.deg.withoutUnit * 120.0.m }),
            .startConnectionChanged(track1, nil),
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [track3, track4], { (x) in
                (x < 110.0.m) ? (track3, x) : (track4, x - 110.0.m)
            })
        ])
        XCTAssert(track3Observer.calls.isEmpty)
        XCTAssert(track4Observer.calls.isEmpty)
        XCTAssert(connectionObserver.calls.isEmpty)
    }
    
    func testExtendsTrackEndToNewConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 10.0.m, y: 30.0.m),
                                   end: Point(x: 50.0.m, y: 30.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 170.0.m, y: 40.0.m),
                                   end: Point(x: 170.0.m, y: 180.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        
        let result = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 50.0.m, y: 150.0.m),
                                       radius: 120.0.m,
                                       startAngle: CircleAngle(-90.0.deg),
                                       endAngle: CircleAngle(0.0.deg),
                                       direction: .positive)!),
                                  startConnection: .toExistingTrack(track1, .end),
                                  endConnection: .toNewConnection(track2, 110.0.m))
        
        XCTAssert(track1 === result)
        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertFalse(map.tracks.contains{ $0 === track2 })
        XCTAssert(map.tracks[0] === track1)
        let track3 = map.tracks[1]
        let track3Observer = TestTrackObserver(for: track3)
        let track4 = map.tracks[2]
        let track4Observer = TestTrackObserver(for: track4)
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        XCTAssertEqual(track1.path, .compound(CompoundPath(components: [
            .linear(LinearPath(start: Point(x: 10.0.m, y: 30.0.m),
                               end: Point(x: 50.0.m, y: 30.0.m))!),
            .circular(CircularPath(center: Point(x: 50.0.m, y: 150.0.m),
                                   radius: 120.0.m,
                                   startAngle: CircleAngle(-90.0.deg),
                                   endAngle: CircleAngle(0.0.deg),
                                   direction: .positive)!),
        ])!))
        XCTAssertNil(track1.startConnection)
        XCTAssert(track1.endConnection === connection)
        XCTAssertEqual(track3.path, .linear(LinearPath(start: Point(x: 170.0.m, y: 40.0.m),
                                                       end: Point(x: 170.0.m, y: 150.0.m))!))
        XCTAssertNil(track3.startConnection)
        XCTAssert(track3.endConnection === connection)
        XCTAssertEqual(track4.path, .linear(LinearPath(start: Point(x: 170.0.m, y: 150.0.m),
                                                       end: Point(x: 170.0.m, y: 180.0.m))!))
        XCTAssert(track4.startConnection === connection)
        XCTAssertNil(track4.endConnection)
        XCTAssertEqual(connection.point, Point(x: 170.0.m, y: 150.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(+90.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(-90.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 1)
        XCTAssertEqual(connection.directionBTracks.count, 2)
        XCTAssert(connection.directionATracks[0] === track4)
        XCTAssert(connection.directionBTracks[0] === track3)
        XCTAssert(connection.directionBTracks[1] === track1)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedTrack(track2, map),
            .trackChanged(track1, map),
            .replacedTrack(track2, [track3, track4], map),
            .addedConnection(connection, map),
        ])
        XCTAssertEqual(track1Observer.calls, [
            .pathChanged(track1, { $0 }),
            .endConnectionChanged(track1, nil),
        ])
        XCTAssertEqual(track2Observer.calls, [
            .replaced(track2, [track3, track4], { (x) in
                (x < 110.0.m) ? (track3, x) : (track4, x - 110.0.m)
            })
        ])
        XCTAssert(track3Observer.calls.isEmpty)
        XCTAssert(track4Observer.calls.isEmpty)
        XCTAssert(connectionObserver.calls.isEmpty)
    }
    
    func testJoinsTrackStartAndTrackStartWithNewConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 10.0.m, y: 0.0.m),
                                   end: Point(x: 10.0.m, y: 100.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                       radius: 100.0.m,
                                       startAngle: CircleAngle(180.0.deg),
                                       endAngle: CircleAngle(90.0.deg),
                                       direction: .negative)!),
                                  startConnection: .toNewConnection(track1, 0.0.m),
                                  endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        
        XCTAssertEqual(map.tracks.count, 2)
        XCTAssert(map.tracks.contains{ $0 === track1 })
        XCTAssert(map.tracks.contains{ $0 === track2 })
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections[0]
        XCTAssertEqual(track1.path, .linear(LinearPath(start: Point(x: 10.0.m, y: 0.0.m),
                                                       end: Point(x: 10.0.m, y: 100.0.m))!))
        XCTAssert(track1.startConnection === connection)
        XCTAssertNil(track1.endConnection)
        XCTAssertEqual(track2.path, .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                                           radius: 100.0.m,
                                                           startAngle: CircleAngle(180.0.deg),
                                                           endAngle: CircleAngle(90.0.deg),
                                                           direction: .negative)!))
        XCTAssert(track2.startConnection === connection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(connection.point, Point(x: 10.0.m, y: 0.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(+90.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(-90.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 2)
        XCTAssert(connection.directionATracks.contains{ $0 === track1 })
        XCTAssert(connection.directionATracks.contains{ $0 === track2 })
        XCTAssertEqual(connection.directionBTracks.count, 0)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedConnection(connection, map),
            .addedTrack(track2, map),
        ])
        XCTAssertEqual(track1Observer.calls, [
            .startConnectionChanged(track1, nil)
        ])
        XCTAssert(track2Observer.calls.isEmpty)
    }
    
    func testJoinsTrackStartAndTrackEndWithNewConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 10.0.m, y: 0.0.m),
                                   end: Point(x: 10.0.m, y: 100.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                       radius: 100.0.m,
                                       startAngle: CircleAngle(90.0.deg),
                                       endAngle: CircleAngle(180.0.deg),
                                       direction: .positive)!),
                                  startConnection: .none,
                                  endConnection: .toNewConnection(track1, 0.0.m))
        let track2Observer = TestTrackObserver(for: track2)
        
        XCTAssertEqual(map.tracks.count, 2)
        XCTAssert(map.tracks.contains{ $0 === track1 })
        XCTAssert(map.tracks.contains{ $0 === track2 })
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections[0]
        XCTAssertEqual(track1.path, .linear(LinearPath(start: Point(x: 10.0.m, y: 0.0.m),
                                                       end: Point(x: 10.0.m, y: 100.0.m))!))
        XCTAssert(track1.startConnection === connection)
        XCTAssertNil(track1.endConnection)
        XCTAssertEqual(track2.path, .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                                           radius: 100.0.m,
                                                           startAngle: CircleAngle(90.0.deg),
                                                           endAngle: CircleAngle(180.0.deg),
                                                           direction: .positive)!))
        XCTAssertNil(track2.startConnection)
        XCTAssert(track2.endConnection === connection)
        XCTAssertEqual(connection.point, Point(x: 10.0.m, y: 0.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(+90.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(-90.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 2)
        XCTAssert(connection.directionATracks.contains{ $0 === track1 })
        XCTAssert(connection.directionATracks.contains{ $0 === track2 })
        XCTAssertEqual(connection.directionBTracks.count, 0)
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedConnection(connection, map),
            .addedTrack(track2, map),
        ])
        XCTAssertEqual(track1Observer.calls, [
            .startConnectionChanged(track1, nil)
        ])
        XCTAssert(track2Observer.calls.isEmpty)
    }
    
    func testJoinsTrackEndAndTrackStartWithNewConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 10.0.m, y: 100.0.m),
                                   end: Point(x: 10.0.m, y: 0.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                       radius: 100.0.m,
                                       startAngle: CircleAngle(180.0.deg),
                                       endAngle: CircleAngle(90.0.deg),
                                       direction: .negative)!),
                                  startConnection: .toNewConnection(track1, 100.0.m),
                                  endConnection: .none)
        let track2Observer = TestTrackObserver(for: track2)
        
        XCTAssertEqual(map.tracks.count, 2)
        XCTAssert(map.tracks.contains{ $0 === track1 })
        XCTAssert(map.tracks.contains{ $0 === track2 })
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections[0]
        XCTAssertEqual(track1.path, .linear(LinearPath(start: Point(x: 10.0.m, y: 100.0.m),
                                                       end: Point(x: 10.0.m, y: 0.0.m))!))
        XCTAssertNil(track1.startConnection)
        XCTAssert(track1.endConnection === connection)
        XCTAssertEqual(track2.path, .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                                           radius: 100.0.m,
                                                           startAngle: CircleAngle(180.0.deg),
                                                           endAngle: CircleAngle(90.0.deg),
                                                           direction: .negative)!))
        XCTAssert(track2.startConnection === connection)
        XCTAssertNil(track2.endConnection)
        XCTAssertEqual(connection.point, Point(x: 10.0.m, y: 0.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(-90.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(+90.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 0)
        XCTAssertEqual(connection.directionBTracks.count, 2)
        XCTAssert(connection.directionBTracks.contains{ $0 === track1 })
        XCTAssert(connection.directionBTracks.contains{ $0 === track2 })
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedConnection(connection, map),
            .addedTrack(track2, map),
        ])
        XCTAssertEqual(track1Observer.calls, [
            .endConnectionChanged(track1, nil)
        ])
        XCTAssert(track2Observer.calls.isEmpty)
    }
    
    func testJoinsTrackEndAndTrackEndWithNewConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let track1 = map.addTrack(withPath:
                .linear(LinearPath(start: Point(x: 10.0.m, y: 100.0.m),
                                   end: Point(x: 10.0.m, y: 0.0.m))!),
                                  startConnection: .none,
                                  endConnection: .none)
        let track1Observer = TestTrackObserver(for: track1)
        let track2 = map.addTrack(withPath:
                .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                       radius: 100.0.m,
                                       startAngle: CircleAngle(90.0.deg),
                                       endAngle: CircleAngle(180.0.deg),
                                       direction: .positive)!),
                                  startConnection: .none,
                                  endConnection: .toNewConnection(track1, 100.0.m))
        let track2Observer = TestTrackObserver(for: track2)
        
        XCTAssertEqual(map.tracks.count, 2)
        XCTAssert(map.tracks.contains{ $0 === track1 })
        XCTAssert(map.tracks.contains{ $0 === track2 })
        XCTAssertEqual(map.connections.count, 1)
        let connection = map.connections[0]
        XCTAssertEqual(track1.path, .linear(LinearPath(start: Point(x: 10.0.m, y: 100.0.m),
                                                       end: Point(x: 10.0.m, y: 0.0.m))!))
        XCTAssertNil(track1.startConnection)
        XCTAssert(track1.endConnection === connection)
        XCTAssertEqual(track2.path, .circular(CircularPath(center: Point(x: 110.0.m, y: 0.0.m),
                                                           radius: 100.0.m,
                                                           startAngle: CircleAngle(90.0.deg),
                                                           endAngle: CircleAngle(180.0.deg),
                                                           direction: .positive)!))
        XCTAssertNil(track2.startConnection)
        XCTAssert(track2.endConnection === connection)
        XCTAssertEqual(connection.point, Point(x: 10.0.m, y: 0.0.m))
        XCTAssertEqual(connection.directionA, CircleAngle(-90.0.deg))
        XCTAssertEqual(connection.directionB, CircleAngle(+90.0.deg))
        XCTAssertEqual(connection.directionATracks.count, 0)
        XCTAssertEqual(connection.directionBTracks.count, 2)
        XCTAssert(connection.directionBTracks.contains{ $0 === track1 })
        XCTAssert(connection.directionBTracks.contains{ $0 === track2 })
        XCTAssertEqual(mapObserver.calls, [
            .addedTrack(track1, map),
            .addedConnection(connection, map),
            .addedTrack(track2, map),
        ])
        XCTAssertEqual(track1Observer.calls, [
            .endConnectionChanged(track1, nil)
        ])
        XCTAssert(track2Observer.calls.isEmpty)
    }
    
    static func encodeAndDecode(_ original: TrackMap) throws -> TrackMap {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(original)
        let decoder = JSONDecoder()
        return try decoder.decode(TrackMap.self, from: encoded)
    }
    
    func testEncodesAndDecodesEmptyTrackMap() throws {
        let original = TrackMap()
        let result = try Tracks_Tests.encodeAndDecode(original)
        XCTAssert(result.tracks.isEmpty)
        XCTAssert(result.connections.isEmpty)
    }
    
    func testEncodesAndDecodesTrackMapWithSingleTrack() throws {
        let path: SomeFinitePath = .linear(LinearPath(start: Point(x: -5.0.m, y: 0.0.m),
                                                      end: Point(x: +5.0.m, y: 0.0.m))!)
        let originalMap = TrackMap()
        let originalTrack = originalMap.addTrack(withPath: path,
                                                 startConnection: .none,
                                                 endConnection: .none)
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
