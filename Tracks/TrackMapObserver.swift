//
//  TrackMapObserver.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/10/24.
//

import Foundation

public protocol TrackMapObserver: AnyObject {
    func added(track: Track, toMap map: TrackMap)
    func replaced(track oldTrack: Track, withTracks newTracks: [Track], onMap map: TrackMap)
    func removed(track oldTrack: Track, fromMap map: TrackMap)

    func added(connection: TrackConnection, toMap map: TrackMap)
    func removed(connection oldConnection: TrackConnection, fromMap map: TrackMap)

    func trackChanged(_ track: Track, onMap map: TrackMap)
    func connectionChanged(_ connection: TrackConnection, onMap map: TrackMap)
}

extension TrackMapObserver {
    func added(track: Track, toMap: TrackMap) {}
    func replaced(track: Track, withTracks: [Track], onMap: TrackMap) {}
    func removed(track: Track, fromMap: TrackMap) {}

    func added(connection: TrackConnection, toMap: TrackMap) {}
    func removed(connection: TrackConnection, fromMap: TrackMap) {}

    func trackChanged(_: Track, onMap: TrackMap) {}
    func connectionChanged(_: TrackConnection, onMap: TrackMap) {}
}
