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
    internal let signalIDGenerator = IDGenerator<Signal>()

    internal var trackSet = IDSet<Track>()
    internal var connectionSet = IDSet<TrackConnection>()
    internal var signalSet = IDSet<Signal>()

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

    deinit {
        observers = []
    }

}
