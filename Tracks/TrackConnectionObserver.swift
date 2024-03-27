//
//  TrackConnectionObserver.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/10/24.
//

import Foundation

public protocol TrackConnectionObserver: AnyObject {
    func added(
        track newTrack: Track, toConnection connection: TrackConnection,
        inDirection direction: TrackConnection.Direction)
    func replaced(
        track oldTrack: Track, withTrack newTrack: Track, inConnection connection: TrackConnection,
        inDirection direction: TrackConnection.Direction)
    func removed(track oldTrack: Track, fromConnection connection: TrackConnection)

    func removed(connection oldConnection: TrackConnection)
}

extension TrackConnectionObserver {
    func added(
        track: Track, toConnection: TrackConnection, inDirection: TrackConnection.Direction
    ) {}
    func replaced(
        track: Track, withTrack: Track, inConnection: TrackConnection,
        inDirection: TrackConnection.Direction
    ) {}
    func removed(track: Track, fromConnection: TrackConnection) {}
    func removed(connection: TrackConnection) {}
}
