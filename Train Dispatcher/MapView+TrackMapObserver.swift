//
//  MapView+TrackMapObserver.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Cocoa
import Foundation
import Tracks

extension MapView: TrackMapObserver {

    func added(track: Track, toMap map: TrackMap) {
        needsDisplay = true
    }

    func replaced(tracks oldTracks: [Track], withTracks newTracks: [Track], onMap map: TrackMap) {
        needsDisplay = true
    }

    func removed(track oldTrack: Track, fromMap map: TrackMap) {
        needsDisplay = true
    }

    func added(connection: TrackConnection, toMap map: TrackMap) {
        needsDisplay = true
    }

    func removed(connection oldConnection: TrackConnection, fromMap map: TrackMap) {
        needsDisplay = true
    }

    func added(signal: Tracks.Signal, toMap map: Tracks.TrackMap) {
        needsDisplay = true
    }

    func removed(signal oldSignal: Tracks.Signal, fromMap map: Tracks.TrackMap) {
        needsDisplay = true
    }

    func trackChanged(_ track: Track, onMap map: TrackMap) {
        needsDisplay = true
    }

    func connectionChanged(_ connection: TrackConnection, onMap map: TrackMap) {
        needsDisplay = true
    }

}
