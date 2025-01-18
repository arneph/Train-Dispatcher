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

    func startedChangingState(connection: TrackConnection, direction: TrackConnection.Direction)
    func progressedStateChange(connection: TrackConnection, direction: TrackConnection.Direction)
    func stoppedChangingState(connection: TrackConnection, direction: TrackConnection.Direction)

    func removed(connection oldConnection: TrackConnection)
}
