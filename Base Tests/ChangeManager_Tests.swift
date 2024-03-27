//
//  ChangeManager_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 3/6/24.
//

import XCTest

@testable import Base

final class TestChangeObserver: ChangeObserver {
    enum Call: Equatable {
        case changeOccurred(ChangeManager)
        case changeWasUndone(ChangeManager)
        case changeWasRedone(ChangeManager)

        static func == (lhs: Call, rhs: Call) -> Bool {
            switch (lhs, rhs) {
            case (.changeOccurred(let lm), .changeOccurred(let rm)): lm === rm
            case (.changeWasUndone(let lm), .changeWasUndone(let rm)): lm === rm
            case (.changeWasRedone(let lm), .changeWasRedone(let rm)): lm === rm
            default: false
            }
        }
    }
    var calls: [Call] = []

    init(for manager: ChangeManager) {
        manager.add(observer: self)
    }

    func changeOccurred(manager: ChangeManager) {
        calls.append(.changeOccurred(manager))
    }

    func changeWasUndone(manager: ChangeManager) {
        calls.append(.changeWasUndone(manager))
    }

    func changeWasRedone(manager: ChangeManager) {
        calls.append(.changeWasRedone(manager))
    }
}

final class TestChangeHandler: ChangeHandler {
    enum State: Equatable {
        case gaveCannotChangeResponses(Int)
        case gaveCanChangeResponse
        case performedChangeWithResult(TestChangeHandler)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.gaveCannotChangeResponses(let lc), .gaveCannotChangeResponses(let rc)): lc == rc
            case (.gaveCanChangeResponse, .gaveCanChangeResponse): true
            case (.performedChangeWithResult(let lu), .performedChangeWithResult(let ru)):
                lu.index == ru.index
            default: false
            }
        }
    }

    private static var count: Int = 0
    let index: Int
    let initialCannotChangeResponses: Int
    let undoChange: TestChangeHandler?
    private(set) var state: State = .gaveCannotChangeResponses(0)

    init() {
        self.index = TestChangeHandler.count
        TestChangeHandler.count += 1
        self.initialCannotChangeResponses = 0
        self.undoChange = nil
    }

    init(initialCannotChangeResponses: Int, undoChange: TestChangeHandler) {
        self.index = TestChangeHandler.count
        TestChangeHandler.count += 1
        self.initialCannotChangeResponses = initialCannotChangeResponses
        self.undoChange = undoChange
    }

    var canChange: Bool {
        switch state {
        case .gaveCannotChangeResponses(let responses):
            if responses < initialCannotChangeResponses {
                state = .gaveCannotChangeResponses(responses + 1)
                return false
            } else {
                state = .gaveCanChangeResponse
                return true
            }
        case .gaveCanChangeResponse:
            return true
        case .performedChangeWithResult:
            XCTFail("TestChangeHandler.canChange called after performChange().")
            return false
        }
    }

    func performChange() -> ChangeHandler {
        switch state {
        case .gaveCanChangeResponse:
            let undoChange = self.undoChange ?? TestChangeHandler()
            state = .performedChangeWithResult(undoChange)
            return undoChange
        default:
            XCTFail("TestChangeHandler.performChange called when not allowed.")
            return TestChangeHandler()
        }
    }
}

final class ChangeManager_Tests: XCTestCase {

    func testAddsChange() {
        let manager = ChangeManager()
        let observer = TestChangeObserver(for: manager)
        let change = TestChangeHandler()
        manager.add(change: change, withName: "Test Change")

        XCTAssert(manager.hasUndo)
        XCTAssertFalse(manager.hasRedo)
        XCTAssertFalse(manager.canRedo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeOccurred(manager)])
        observer.calls.removeAll()

        XCTAssert(manager.canUndo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCanChangeResponse)
        XCTAssert(observer.calls.isEmpty)

        XCTAssert(manager.hasUndo)
        XCTAssertFalse(manager.hasRedo)
        XCTAssertFalse(manager.canRedo)

        XCTAssert(manager.canUndo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCanChangeResponse)
        XCTAssert(observer.calls.isEmpty)
    }

    func testUndoesAndRedoesChange() {
        let manager = ChangeManager()
        let observer = TestChangeObserver(for: manager)
        let redo = TestChangeHandler()
        let undo = TestChangeHandler(initialCannotChangeResponses: 0, undoChange: redo)
        let change = TestChangeHandler(initialCannotChangeResponses: 0, undoChange: undo)
        manager.add(change: change, withName: "Test Change")

        XCTAssert(manager.hasUndo)
        XCTAssertFalse(manager.hasRedo)
        XCTAssertFalse(manager.canRedo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(undo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeOccurred(manager)])
        observer.calls.removeAll()

        XCTAssert(manager.canUndo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCanChangeResponse)
        XCTAssertEqual(undo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssert(observer.calls.isEmpty)

        manager.undo()
        XCTAssertEqual(change.state, .performedChangeWithResult(undo))
        XCTAssertEqual(undo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeWasUndone(manager)])
        observer.calls.removeAll()
        XCTAssertFalse(manager.hasUndo)
        XCTAssertFalse(manager.canUndo)
        XCTAssert(manager.hasRedo)
        XCTAssert(observer.calls.isEmpty)

        XCTAssert(manager.canRedo)
        XCTAssertEqual(manager.redoName, "Test Change")
        XCTAssertEqual(undo.state, .gaveCanChangeResponse)
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssert(observer.calls.isEmpty)

        manager.redo()
        XCTAssertEqual(undo.state, .performedChangeWithResult(redo))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeWasRedone(manager)])
        observer.calls.removeAll()
        XCTAssert(manager.hasUndo)
        XCTAssertFalse(manager.hasRedo)
        XCTAssertFalse(manager.canRedo)
        XCTAssert(observer.calls.isEmpty)
    }

    func testUndoesAndRedoesChangeAfterOtherChanges() {
        let manager = ChangeManager()
        let observer = TestChangeObserver(for: manager)
        let redo = TestChangeHandler()
        let undo = TestChangeHandler(initialCannotChangeResponses: 0, undoChange: redo)
        let change = TestChangeHandler(initialCannotChangeResponses: 0, undoChange: undo)

        manager.add(change: TestChangeHandler(), withName: "Other Change")
        manager.add(change: TestChangeHandler(), withName: "Other Change")
        manager.add(change: TestChangeHandler(), withName: "Other Change")
        manager.add(change: TestChangeHandler(), withName: "Other Change")
        observer.calls.removeAll()

        manager.add(change: change, withName: "Test Change")

        XCTAssert(manager.hasUndo)
        XCTAssertFalse(manager.hasRedo)
        XCTAssertFalse(manager.canRedo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(undo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeOccurred(manager)])
        observer.calls.removeAll()

        XCTAssert(manager.canUndo)
        XCTAssertEqual(manager.undoName, "Test Change")
        XCTAssertEqual(change.state, .gaveCanChangeResponse)
        XCTAssertEqual(undo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssert(observer.calls.isEmpty)

        manager.undo()
        XCTAssertEqual(change.state, .performedChangeWithResult(undo))
        XCTAssertEqual(undo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeWasUndone(manager)])
        observer.calls.removeAll()
        XCTAssert(manager.hasUndo)
        XCTAssert(manager.hasRedo)
        XCTAssert(observer.calls.isEmpty)

        XCTAssert(manager.canRedo)
        XCTAssertEqual(manager.redoName, "Test Change")
        XCTAssertEqual(undo.state, .gaveCanChangeResponse)
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssert(observer.calls.isEmpty)

        manager.redo()
        XCTAssertEqual(undo.state, .performedChangeWithResult(redo))
        XCTAssertEqual(redo.state, .gaveCannotChangeResponses(0))
        XCTAssertEqual(observer.calls, [.changeWasRedone(manager)])
        observer.calls.removeAll()
        XCTAssert(manager.hasUndo)
        XCTAssertFalse(manager.hasRedo)
        XCTAssertFalse(manager.canRedo)
        XCTAssert(observer.calls.isEmpty)
    }

}
