//
//  TrackMap+SignalAddition.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/14/24.
//

import Base
import Foundation

extension TrackMap {
    internal struct SignalAdditionChangeHandler: ChangeHandler {
        var canChange: Bool { true }
        func performChange() -> ChangeHandler { preconditionFailure("implement me!") }
    }

    public func addSignal(
        kind: Signal.Kind,
        at position: PointAndOrientation
    ) -> (Signal, ChangeHandler) {
        let signal = Signal(id: signalIDGenerator.new(), position: position, kind: kind)
        let update = add(signal: signal)
        updateObservers([update])
        return (signal, SignalRemovalChangeHandler())
    }

}
