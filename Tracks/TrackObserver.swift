//
//  TrackObserver.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/10/24.
//

import Base
import Foundation

public typealias PositionUpdateFunc = (Position) -> (Position)
public typealias TrackAndPostionUpdateFunc = (Position) -> (Track, Position)

public protocol TrackObserver: AnyObject {
    func pathChanged(forTrack track: Track, withPositionUpdate f: @escaping PositionUpdateFunc)

    func startConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?)
    func endConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?)

    func replaced(
        track oldTrack: Track, withTracks newTracks: [Track],
        withUpdateFunc f: @escaping TrackAndPostionUpdateFunc)
    func removed(track oldTrack: Track)
}

extension TrackObserver {
    func pathChanged(forTrack: Track, withPositionUpdate f: @escaping PositionUpdateFunc) {}
    func startConnectionChanged(forTrack: Track, oldConnection: TrackConnection?) {}
    func endConnectionChanged(forTrack: Track, oldConnection: TrackConnection?) {}
    func replaced(
        track: Track, withTracks: [Track], withUpdateFunc: @escaping TrackAndPostionUpdateFunc
    ) {}
    func removed(track: Track) {}
}
