//
//  TestTrackConnectionObserver.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/27/24.
//

@testable import Train_Dispatcher

import Foundation

final class TestTrackConnectionObserver: TrackConnectionObserver {
    enum Call: Equatable {
        case addedTrack(Track, TrackConnection, TrackConnection.Direction)
        case replacedTrack(Track, Track, TrackConnection, TrackConnection.Direction)
        case removedTrack(Track, TrackConnection)
        case removed(TrackConnection)
        
        static func == (lhs: Call, rhs: Call) -> Bool {
            switch (lhs, rhs) {
            case (.addedTrack(let lt, let lc, let ld), .addedTrack(let rt, let rc, let rd)):
                return lt === rt && lc === rc && ld == rd
            case (.replacedTrack(let lo, let ln, let lc, let ld),
                  .replacedTrack(let ro, let rn, let rc, let rd)):
                return lo === ro && ln === rn && lc === rc && ld == rd
            case (.removedTrack(let lt, let lc), .removedTrack(let rt, let rc)):
                return lt === rt && lc === rc
            case (.removed(let lc), .removed(let rc)):
                return lc === rc
            default:
                return false
            }
        }
    }
    var calls: [Call] = []
    
    init(for connection: TrackConnection) {
        connection.add(observer: self)
    }
    
    func added(track newTrack: Track,
               toConnection connection: TrackConnection,
               inDirection direction: TrackConnection.Direction) {
        calls.append(.addedTrack(newTrack, connection, direction))
    }
    
    func replaced(track oldTrack: Track,
                  withTrack newTrack: Track,
                  inConnection connection: TrackConnection,
                  inDirection direction: TrackConnection.Direction) {
        calls.append(.replacedTrack(oldTrack, newTrack, connection, direction))
    }
    
    func removed(track oldTrack: Track, fromConnection connection: TrackConnection) {
        calls.append(.removedTrack(oldTrack, connection))
    }
    
    func removed(connection oldConnection: TrackConnection) {
        calls.append(.removed(oldConnection))
    }
    
}
