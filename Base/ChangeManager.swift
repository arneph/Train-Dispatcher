//
//  ChangeManager.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 3/5/24.
//

import Foundation

public protocol ChangeHandler {
    var canChange: Bool { get }
    func performChange() -> ChangeHandler
}

public protocol ChangeObserver: AnyObject {
    func changeOccurred(manager: ChangeManager)
    func changeWasUndone(manager: ChangeManager)
    func changeWasRedone(manager: ChangeManager)
}

public class ChangeManager {
    private var observers: [ChangeObserver] = []

    public func add(observer: ChangeObserver) {
        observers.append(observer)
    }

    public func remove(observer: ChangeObserver) {
        observers.removeAll { $0 === observer }
    }

    private struct NamedChangeHandler {
        let name: String
        let handler: ChangeHandler
    }

    private var undoChanges: [NamedChangeHandler] = []
    private var redoChanges: [NamedChangeHandler] = []

    public var hasUndo: Bool { !undoChanges.isEmpty }
    public var hasRedo: Bool { !redoChanges.isEmpty }

    public var canUndo: Bool { hasUndo && undoChanges.last!.handler.canChange }
    public var canRedo: Bool { hasRedo && redoChanges.last!.handler.canChange }

    public var undoName: String { undoChanges.last!.name }
    public var redoName: String { redoChanges.last!.name }

    public func add(change: ChangeHandler, withName name: String) {
        undoChanges.append(NamedChangeHandler(name: name, handler: change))
        redoChanges.removeAll()
        observers.forEach { $0.changeOccurred(manager: self) }
    }

    public func undo() {
        assert(canUndo)
        let undo = undoChanges.removeLast()
        let undoHandler = undo.handler
        let redoHandler = undoHandler.performChange()
        let redo = NamedChangeHandler(name: undo.name, handler: redoHandler)
        redoChanges.append(redo)
        observers.forEach { $0.changeWasUndone(manager: self) }
    }

    public func redo() {
        assert(canRedo)
        let redo = redoChanges.removeLast()
        let redoHandler = redo.handler
        let undoHandler = redoHandler.performChange()
        let undo = NamedChangeHandler(name: redo.name, handler: undoHandler)
        undoChanges.append(undo)
        observers.forEach { $0.changeWasRedone(manager: self) }
    }

    public init() {}

    deinit {
        observers = []
    }

}
