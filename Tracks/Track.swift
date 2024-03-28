//
//  Track.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/9/24.
//

import Base
import Foundation

let gauge = 1.435.m
let railTopWidth = 0.05.m
let railBottomWidth = 0.2.m
let sleeperLength = gauge + 0.5.m
let sleeperWidth = 0.25.m
let minSleeperOffset = 0.6.m
public let trackBedWidth = sleeperLength + 1.5.m

public func isValid(trackPath path: SomeFinitePath) -> Bool {
    switch path {
    case .circular(let path):
        path.radius >= 100.0.m && path.length >= 5.0.m
    case .linear(let path):
        path.length >= 5.0.m
    case .compound(let path):
        path.length >= 5.0.m
            && path.components.allSatisfy {
                switch $0 {
                case .circular(let component):
                    component.radius >= 100.0.m
                case .linear: true
                }
            }
    }
}

public final class Track: IDObject {
    private var observers: [TrackObserver] = []
    public func add(observer: TrackObserver) { observers.append(observer) }
    public func remove(observer: TrackObserver) { observers.removeAll { $0 === observer } }

    public let id: ID<Track>

    public private(set) var path: SomeFinitePath {
        didSet {
            leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
            rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
        }
    }
    public private(set) var leftRail: SomeFinitePath
    public private(set) var rightRail: SomeFinitePath

    public var atomicPathTypeAtStart: AtomicPathType { path.forwardAtomicPathType(at: 0.0.m)! }
    public var atomicPathTypeAtEnd: AtomicPathType { path.backwardAtomicPathType(at: path.length)! }

    internal func set(
        path: SomeFinitePath, withPositionUpdate positionUpdate: @escaping PositionUpdateFunc
    ) {
        self.path = path
        observers.forEach { $0.pathChanged(forTrack: self, withPositionUpdate: positionUpdate) }
    }

    public internal(set) weak var startConnection: TrackConnection? = nil {
        didSet {
            observers.forEach { $0.startConnectionChanged(forTrack: self, oldConnection: oldValue) }
        }
    }
    public internal(set) weak var endConnection: TrackConnection? = nil {
        didSet {
            observers.forEach { $0.endConnectionChanged(forTrack: self, oldConnection: oldValue) }
        }
    }

    public func connection(at extremity: PathExtremity) -> TrackConnection? {
        switch extremity {
        case .start: startConnection
        case .end: endConnection
        }
    }

    internal func setConnection(_ connection: TrackConnection, at extremity: PathExtremity) {
        switch extremity {
        case .start: startConnection = connection
        case .end: endConnection = connection
        }
    }

    internal func informObserversOfReplacement(
        by newTracks: [Track], withUpdateFunc f: @escaping TrackAndPostionUpdateFunc
    ) {
        observers.forEach { $0.replaced(track: self, withTracks: newTracks, withUpdateFunc: f) }
    }

    internal func informObserversOfRemoval() {
        observers.forEach { $0.removed(track: self) }
    }

    internal init(id: ID<Track>, path: SomeFinitePath) {
        self.id = id
        self.path = path
        self.leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
        self.rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
    }

    deinit {
        observers = []
    }

}
