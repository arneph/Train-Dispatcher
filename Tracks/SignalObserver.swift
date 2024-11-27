//
//  SignalObserver.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/12/24.
//

import Foundation

public protocol SignalObserver: AnyObject {
    func startedChangingState(signal: Signal)
    func progressedStateChange(signal: Signal)
    func stoppedChangingState(signal: Signal)

    func removed(signal oldSignal: Signal)
}

extension SignalObserver {
    func startedChangingState(signal: Signal) {}
    func progressedStateChange(signal: Signal) {}
    func stoppedChangingState(signal: Signal) {}
    func removed(signal oldSignal: Signal) {}
}
