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
    private let observers_ = ObserversOwner<TrackObserver>()
    public var observers: Observers<TrackObserver> { observers_ }

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
    ) -> ObserverUpdate {
        self.path = path
        return observers_.createUpdate({
            $0.pathChanged(forTrack: self, withPositionUpdate: positionUpdate)
        })
    }

    public private(set) weak var startConnection: TrackConnection? = nil
    public private(set) weak var endConnection: TrackConnection? = nil

    public func connection(at extremity: PathExtremity) -> TrackConnection? {
        switch extremity {
        case .start: startConnection
        case .end: endConnection
        }
    }

    internal func setStartConnection(_ newConnection: TrackConnection?) -> ObserverUpdate {
        let oldConnection = startConnection
        startConnection = newConnection
        return observers_.createUpdate({
            $0.startConnectionChanged(forTrack: self, oldConnection: oldConnection)
        })
    }

    internal func setEndConnection(_ newConnection: TrackConnection?) -> ObserverUpdate {
        let oldConnection = endConnection
        endConnection = newConnection
        return observers_.createUpdate({
            $0.endConnectionChanged(forTrack: self, oldConnection: oldConnection)
        })
    }

    internal func setConnection(_ connection: TrackConnection, at extremity: PathExtremity)
        -> ObserverUpdate
    {
        switch extremity {
        case .start: setStartConnection(connection)
        case .end: setEndConnection(connection)
        }
    }

    internal func createObserverUpdateForReplacement(
        by newTracks: [Track], withUpdateFunc f: @escaping TrackAndPostionUpdateFunc
    ) -> ObserverUpdate {
        observers_.createUpdate({
            $0.replaced(track: self, withTracks: newTracks, withUpdateFunc: f)
        })
    }

    internal func createObserverUpdateForRemoval() -> ObserverUpdate {
        observers_.createUpdate({ $0.removed(track: self) })
    }

    internal init(id: ID<Track>, path: SomeFinitePath) {
        self.id = id
        self.path = path
        self.leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
        self.rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
    }

}
