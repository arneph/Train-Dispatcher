//
//  TrackMap+SignalRemoval.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/14/24.
//

import Base
import Foundation

extension TrackMap {
    internal struct SignalRemovalChangeHandler: ChangeHandler {
        var canChange: Bool { true }
        func performChange() -> ChangeHandler { preconditionFailure("implement me!") }
    }

    public func remove(oldSignal: Signal) -> ChangeHandler {
        let updates = remove(signal: oldSignal)
        updateObservers(updates)
        return SignalAdditionChangeHandler()
    }

}
