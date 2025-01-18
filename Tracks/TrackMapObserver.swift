//
//  TrackMapObserver.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/10/24.
//

import Foundation

public protocol TrackMapObserver: AnyObject {
    func added(track newTrack: Track, toMap map: TrackMap)
    func replaced(tracks oldTracks: [Track], withTracks newTracks: [Track], onMap map: TrackMap)
    func removed(track oldTrack: Track, fromMap map: TrackMap)

    func added(connection: TrackConnection, toMap map: TrackMap)
    func removed(connection oldConnection: TrackConnection, fromMap map: TrackMap)

    func added(signal: Signal, toMap map: TrackMap)
    func removed(signal oldSignal: Signal, fromMap map: TrackMap)

    func trackChanged(_ track: Track, onMap map: TrackMap)
    func connectionChanged(_ connection: TrackConnection, onMap map: TrackMap)
}
