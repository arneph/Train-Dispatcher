//
//  TestTrackObserver.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/26/24.
//

import Base
import Foundation

@testable import Tracks

func == (lhs: TrackAndPostionMapping, rhs: TrackAndPostionMapping) -> Bool {
    for i in stride(from: -200.0, through: +200.0, by: 1.23) {
        let x = Position(i)
        let l = lhs.newTrackAndPosition(for: x)
        let r = rhs.newTrackAndPosition(for: x)
        guard let l = l, let r = r else {
            if (l == nil) != (r == nil) {
                return false
            } else {
                continue
            }
        }
        let (lt, lx) = l
        let (rt, rx) = r
        guard lt === rt, lx == rx else {
            return false
        }
        guard lt.path.point(at: lx) == rt.path.point(at: rx) else {
            return false
        }
    }
    return true
}

final class TestTrackObserver: TrackObserver {
    enum Call: Equatable {
        case pathChanged(Track, PositionMapping)
        case startConnectionChanged(Track, TrackConnection?)
        case endConnectionChanged(Track, TrackConnection?)
        case replaced(Track, [Track], TrackAndPostionMapping)
        case removed(Track)

        static func == (lhs: Call, rhs: Call) -> Bool {
            switch (lhs, rhs) {
            case (.pathChanged(let lt, let lf), .pathChanged(let rt, let rf)):
                lt === rt && lf == rf
            case (.startConnectionChanged(let lt, let lc), .startConnectionChanged(let rt, let rc)):
                lt === rt && lc === rc
            case (.endConnectionChanged(let lt, let lc), .endConnectionChanged(let rt, let rc)):
                lt === rt && lc === rc
            case (.replaced(let lo, let ln, let lf), .replaced(let ro, let rn, let rf)):
                lo === ro && zip(ln, rn).allSatisfy { $0 === $1 } && lf == rf
            case (.removed(let lt), .removed(let rt)):
                lt === rt
            default:
                false
            }
        }
    }
    var calls: [Call] = []

    init(for track: Track) {
        track.observers.add(self)
    }

    func pathChanged(forTrack track: Track, withMapping mapping: PositionMapping) {
        calls.append(.pathChanged(track, mapping))
    }

    func startConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?) {
        calls.append(.startConnectionChanged(track, oldConnection))
    }

    func endConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?) {
        calls.append(.endConnectionChanged(track, oldConnection))
    }

    func replaced(
        track oldTrack: Track, withTracks newTracks: [Track],
        withMapping mapping: TrackAndPostionMapping
    ) {
        calls.append(.replaced(oldTrack, newTracks, mapping))
    }

    func removed(track oldTrack: Track) {
        calls.append(.removed(oldTrack))
    }

}
