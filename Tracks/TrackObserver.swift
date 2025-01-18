//
//  TrackObserver.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/10/24.
//

import Base
import Foundation

public struct TrackAndPostionMapping {
    private var tracksAndPositionMappings: [(Track, PositionMapping)]

    public func newTrackAndPosition(for oldPosition: Position) -> (Track, Position)? {
        for (track, mapping) in tracksAndPositionMappings {
            if let newPosition = mapping.newPosition(for: oldPosition) {
                return (track, newPosition)
            }
        }
        return nil
    }

    internal init(track: Track, mapping: PositionMapping) {
        self.tracksAndPositionMappings = [(track, mapping)]
    }

    internal init(tracksAndPositionMappings: [(Track, PositionMapping)]) {
        self.tracksAndPositionMappings = tracksAndPositionMappings
    }
}

public protocol TrackObserver: AnyObject {
    func pathChanged(forTrack track: Track, withMapping mapping: PositionMapping)

    func startConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?)
    func endConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?)

    func replaced(
        track oldTrack: Track, withTracks newTracks: [Track],
        withMapping mapping: TrackAndPostionMapping)
    func removed(track oldTrack: Track)
}
