//
//  Tracks.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Base
import Foundation

public final class TrackMap {
    internal private(set) var observers: [TrackMapObserver] = []
    public func add(observer: TrackMapObserver) { observers.append(observer) }
    public func remove(observer: TrackMapObserver) { observers.removeAll { $0 === observer } }

    internal let trackIDGenerator = IDGenerator<Track>()
    internal let connectionIDGenerator = IDGenerator<TrackConnection>()

    internal var trackSet = IDSet<Track>()
    internal var connectionSet = IDSet<TrackConnection>()

    public var tracks: [Track] { trackSet.elements }
    public var connections: [TrackConnection] { connectionSet.elements }

    public init() {}
    internal init(tracks: IDSet<Track>, connections: IDSet<TrackConnection>) {
        self.trackSet = tracks
        self.connectionSet = connections
    }

    deinit {
        observers = []
    }

}
