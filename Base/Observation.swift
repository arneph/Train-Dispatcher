//
//  Observervation.swift
//  Base
//
//  Created by Arne Philipeit on 11/22/24.
//

import Foundation

public class Observers<Observer> {
    internal struct WeakObserver {
        weak var observer: AnyObject?
    }

    internal private(set) var observers: [WeakObserver] = []

    public func add(_ observer: Observer) {
        observers.append(WeakObserver(observer: observer as AnyObject))
    }

    public func remove(_ observer: Observer) {
        observers.removeAll { $0.observer === observer as AnyObject }
    }

    internal init() {}

    deinit {
        observers = []
    }
}

public class ObserversOwner<Observer>: Observers<Observer> {
    public func createUpdate(_ update: @escaping (Observer) -> Void) -> ObserverUpdate {
        ObserverUpdate({
            self.observers.forEach {
                if let observer = $0.observer {
                    update(observer as! Observer)
                }
            }
        })
    }

    public override init() {}

}

public struct ObserverUpdate {
    private let update: () -> Void

    public init(_ update: @escaping () -> Void) {
        self.update = update
    }

    internal func sendUpdate() {
        update()
    }
}

public func updateObservers(_ updates: [ObserverUpdate]) {
    for update in updates {
        update.sendUpdate()
    }
}
