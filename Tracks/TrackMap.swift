//
//  Tracks.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Base
import Foundation

public final class TrackMap {
    internal let observers_ = ObserversOwner<TrackMapObserver>()
    public var observers: Observers<TrackMapObserver> { observers_ }

    internal let trackIDGenerator = IDGenerator<Track>()
    internal let connectionIDGenerator = IDGenerator<TrackConnection>()
    internal let signalIDGenerator = IDGenerator<Signal>()

    internal private(set) var trackSet = IDSet<Track>()
    internal private(set) var connectionSet = IDSet<TrackConnection>()
    internal private(set) var signalSet = IDSet<Signal>()

    internal func add(track newTrack: Track) -> ObserverUpdate {
        trackSet.add(newTrack)
        return observers_.createUpdate({
            $0.added(track: newTrack, toMap: self)
        })
    }

    internal func replace(
        oldTracksAndUpdateFuncs: [(Track, TrackAndPostionUpdateFunc)],
        withTracks newTracks: [Track]
    ) -> [ObserverUpdate] {
        let oldTracks = oldTracksAndUpdateFuncs.map { $0.0 }
        trackSet.remove(oldTracks)
        trackSet.add(newTracks)
        let trackUpdates = oldTracksAndUpdateFuncs.map { (oldTrack, f) in
            oldTrack.createObserverUpdateForReplacement(by: newTracks, withUpdateFunc: f)
        }
        let mapUpdate = observers_.createUpdate({
            $0.replaced(tracks: oldTracks, withTracks: newTracks, onMap: self)
        })
        return trackUpdates + [mapUpdate]
    }

    internal func remove(track oldTrack: Track) -> [ObserverUpdate] {
        trackSet.remove(oldTrack)
        let update1 = oldTrack.createObserverUpdateForRemoval()
        let update2 = observers_.createUpdate({
            $0.removed(track: oldTrack, fromMap: self)
        })
        return [update1, update2]
    }

    internal func add(connection newConnection: TrackConnection) -> ObserverUpdate {
        connectionSet.add(newConnection)
        return observers_.createUpdate({
            $0.added(connection: newConnection, toMap: self)
        })
    }

    internal func remove(connection oldConnection: TrackConnection) -> [ObserverUpdate] {
        connectionSet.remove(oldConnection)
        let update1 = oldConnection.createObserverUpdateForRemoval()
        let update2 = observers_.createUpdate({
            $0.removed(connection: oldConnection, fromMap: self)
        })
        return [update1, update2]
    }

    internal func add(signal newSignal: Signal) -> ObserverUpdate {
        signalSet.add(newSignal)
        return observers_.createUpdate({
            $0.added(signal: newSignal, toMap: self)
        })
    }

    internal func remove(signal oldSignal: Signal) -> [ObserverUpdate] {
        signalSet.remove(oldSignal)
        let update1 = oldSignal.createObserverUpdateForRemoval()
        let update2 = observers_.createUpdate({
            $0.removed(signal: oldSignal, fromMap: self)
        })
        return [update1, update2]
    }

    public var tracks: [Track] { trackSet.elements }
    public var connections: [TrackConnection] { connectionSet.elements }
    public var signals: [Signal] { signalSet.elements }

    public init() {}
    internal init(tracks: IDSet<Track>, connections: IDSet<TrackConnection>, signals: IDSet<Signal>)
    {
        self.trackSet = tracks
        self.connectionSet = connections
        self.signalSet = signals
    }

}
