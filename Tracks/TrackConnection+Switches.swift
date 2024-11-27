//
//  TrackConnection+Switches.swift
//  Tracks
//
//  Created by Arne Philipeit on 9/15/24.
//

import Base
import Foundation

extension TrackConnection {
    public func switchDirectionA(to next: Track) {
        assert(directionATracks.contains { $0 === next })
        if directionAActiveTrack === next {
            return
        }
        directionAState =
            switch directionAState {
            case .fixed(let track):
                .changing(StateChange(previous: track, next: next, progress: 0.0))
            case .changing(let change):
                .changing(StateChange(previous: change.previous, next: next, progress: 0.0))
            case nil:
                .fixed(next)
            }
        updateObservers([createObserverUpdateForStartedStateChange(direction: .a)])
    }

    public func switchDirectionB(to next: Track) {
        assert(directionBTracks.contains { $0 === next })
        if directionBActiveTrack === next {
            return
        }
        directionBState =
            switch directionBState {
            case .fixed(let track):
                .changing(StateChange(previous: track, next: next, progress: 0.0))
            case .changing(let change):
                .changing(StateChange(previous: change.previous, next: next, progress: 0.0))
            case nil:
                .fixed(next)
            }
        updateObservers([createObserverUpdateForStartedStateChange(direction: .b)])
    }

    public func switchDirection(_ direction: Direction, to next: Track) {
        switch direction {
        case .a: switchDirectionA(to: next)
        case .b: switchDirectionB(to: next)
        }
    }

    internal func tick(_ delta: Duration) {
        let aResult: StateTickResult
        (directionAState, aResult) = TrackConnection.tick(delta, for: directionAState)
        let bResult: StateTickResult
        (directionBState, bResult) = TrackConnection.tick(delta, for: directionBState)
        switch aResult {
        case .noChange:
            break
        case .stillChanging:
            updateObservers([createObserverUpdateForProgressedStateChange(direction: .a)])
        case .finishedChanging:
            updateObservers([createObserverUpdateForStoppedStateChange(direction: .a)])
        }
        switch bResult {
        case .noChange:
            break
        case .stillChanging:
            updateObservers([createObserverUpdateForProgressedStateChange(direction: .b)])
        case .finishedChanging:
            updateObservers([createObserverUpdateForStoppedStateChange(direction: .b)])
        }
    }

    private enum StateTickResult {
        case noChange, stillChanging, finishedChanging
    }

    private static func tick(_ delta: Duration, for state: State?) -> (State?, StateTickResult) {
        let switchDuration = 5.0.s
        switch state {
        case .changing(let change):
            let newProgress = change.progress + delta / switchDuration
            return if newProgress < 1.0 {
                (
                    .changing(
                        StateChange(
                            previous: change.previous,
                            next: change.next,
                            progress: newProgress)), .stillChanging
                )
            } else {
                (.fixed(change.next), .finishedChanging)
            }
        default:
            return (state, .noChange)
        }
    }

    private func createObserverUpdateForStartedStateChange(direction: Direction) -> ObserverUpdate {
        observers_.createUpdate({
            $0.startedChangingState(connection: self, direction: direction)
        })
    }

    private func createObserverUpdateForProgressedStateChange(direction: Direction)
        -> ObserverUpdate
    {
        observers_.createUpdate({
            $0.progressedStateChange(connection: self, direction: direction)
        })
    }

    private func createObserverUpdateForStoppedStateChange(direction: Direction) -> ObserverUpdate {
        observers_.createUpdate({
            $0.stoppedChangingState(connection: self, direction: direction)
        })
    }

}
