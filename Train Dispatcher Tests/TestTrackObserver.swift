//
//  TestTrackObserver.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/26/24.
//

@testable import Train_Dispatcher

import Foundation

func == (lhs: PositionUpdateFunc, rhs: PositionUpdateFunc) -> Bool {
    lhs(0.0.m) == rhs(0.0.m) && lhs(+1.23.m) == rhs(+1.23.m) && lhs(-1.23.m) == rhs(-1.23.m)
}

func == (lhs: TrackAndPostionUpdateFunc, rhs: TrackAndPostionUpdateFunc) -> Bool {
    for i in stride(from: -200.0, through: +200.0, by: 1.23) {
        let x = Position(i)
        let (lt, lx) = lhs(x)
        let (rt, rx) = rhs(x)
        guard lt === rt, lx == rx else { return false }
    }
    return true
}

final class TestTrackObserver: TrackObserver {
    enum Call: Equatable {
        case pathChanged(Track, PositionUpdateFunc)
        case startConnectionChanged(Track, TrackConnection?)
        case endConnectionChanged(Track, TrackConnection?)
        case replaced(Track, [Track], TrackAndPostionUpdateFunc)
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
                lo === ro && zip(ln, rn).allSatisfy{ $0 === $1 } && lf == rf
            case (.removed(let lt), .removed(let rt)):
                lt === rt
            default:
                false
            }
        }
    }
    var calls: [Call] = []
    
    init(for track: Track) {
        track.add(observer: self)
    }
    
    func pathChanged(forTrack track: Track, withPositionUpdate f: @escaping PositionUpdateFunc) {
        calls.append(.pathChanged(track, f))
    }
    
    func startConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?) {
        calls.append(.startConnectionChanged(track, oldConnection))
    }
    
    func endConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?) {
        calls.append(.endConnectionChanged(track, oldConnection))
    }
        
    func replaced(track oldTrack: Track, 
                  withTracks newTracks: [Track],
                  withUpdateFunc f: @escaping TrackAndPostionUpdateFunc) {
        calls.append(.replaced(oldTrack, newTracks, f))
    }
    
    func removed(track oldTrack: Track) {
        calls.append(.removed(oldTrack))
    }
    
}
