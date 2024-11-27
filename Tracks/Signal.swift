//
//  Signal.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/12/24.
//

import Base
import Foundation

public final class Signal: IDObject {
    private let observers_ = ObserversOwner<SignalObserver>()
    public var observers: Observers<SignalObserver> { observers_ }

    public let id: Base.ID<Signal>

    public let position: PointAndOrientation
    public var point: Point { position.point }
    public var orientation: CircleAngle { position.orientation }

    public enum Kind: Codable, Equatable {
        case section, main
    }

    public let kind: Kind

    public enum BaseState: Codable, Equatable {
        case blocked
        case go
    }
    public struct StateChange: Codable, Equatable {
        let previous: BaseState
        let next: BaseState
        let progress: Float64
    }
    public enum State: Codable, Equatable {
        case fixed(BaseState)
        case changing(StateChange)

        public var activeState: BaseState {
            switch self {
            case .fixed(let baseState): baseState
            case .changing(let change): change.previous
            }
        }
    }

    public internal(set) var state: State = .fixed(.blocked)
    public var activeState: BaseState { state.activeState }

    public func changeState(to next: BaseState) {
        if activeState == next {
            return
        }
        state = .changing(StateChange(previous: activeState, next: next, progress: 0.0))
        updateObservers([createObserverUpdateForStartedStateChange()])
    }

    internal func tick(_ delta: Duration) {
        let changeDuration = 1.0.s
        switch state {
        case .fixed(let baseState):
            state = .fixed(baseState)
        case .changing(let change):
            let newProgress = change.progress + delta / changeDuration
            if newProgress < 1.0 {
                state = .changing(
                    StateChange(
                        previous: change.previous,
                        next: change.next,
                        progress: newProgress))
                updateObservers([createObserverUpdateForProgressedStateChange()])
            } else {
                state = .fixed(change.next)
                updateObservers([createObserverUpdateForStoppedStateChange()])
            }
        }
    }

    private func createObserverUpdateForStartedStateChange() -> ObserverUpdate {
        observers_.createUpdate({
            $0.startedChangingState(signal: self)
        })
    }

    private func createObserverUpdateForProgressedStateChange() -> ObserverUpdate {
        observers_.createUpdate({
            $0.progressedStateChange(signal: self)
        })
    }

    private func createObserverUpdateForStoppedStateChange() -> ObserverUpdate {
        observers_.createUpdate({
            $0.stoppedChangingState(signal: self)
        })
    }

    internal func createObserverUpdateForRemoval() -> ObserverUpdate {
        observers_.createUpdate({
            $0.removed(signal: self)
        })
    }

    internal init(id: Base.ID<Signal>, position: PointAndOrientation, kind: Kind) {
        self.id = id
        self.position = position
        self.kind = kind
    }

}
