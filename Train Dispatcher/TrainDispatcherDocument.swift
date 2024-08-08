//
//  Document.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Base
import Cocoa
import Foundation
import Tracks
import Trains

private func randomPath() -> SomeFinitePath {
    var path: SomeFinitePath = .linear(
        LinearPath(
            start: Point(x: -100.0.m, y: 0.0.m), end: Point(x: 0.0.m, y: 0.0.m))!)
    while path.length < 30.0.km {
        let r = Distance(Double.random(in: 100.0...400.0))
        let t = Bool.random()
        let d = t ? +90.0.deg : -90.0.deg
        let c = path.end + (path.endOrientation + d) ** r
        let alpha = CircleAngle(angle(from: c, to: path.end))
        let delta = t ? Double.random(in: 15.0...90.0).deg : -Double.random(in: 15.0...90.0).deg
        let curve = CircularPath(center: c, radius: r, startAngle: alpha, deltaAngle: delta)!
        let l = Distance(Double.random(in: 20.0...500.0))
        let straight = LinearPath(
            start: curve.end,
            end: curve.end + curve.endOrientation.asAngle ** l)!
        path = SomeFinitePath.combine([path, .circular(curve), .linear(straight)])!
    }
    return path
}

private func defaultMap() -> Map {
    let map = Map()
    let middlePath = randomPath()
    let pathA = middlePath.offsetLeft(by: 2.5.m)!
    let pathB = middlePath.offsetRight(by: 2.5.m)!
    let (_, _) = map.trackMap.addTrack(
        withPath: pathA, startConnection: .none, endConnection: .none)
    let (_, _) = map.trackMap.addTrack(
        withPath: pathB, startConnection: .none, endConnection: .none)
    let numContainerWagons = 40
    let containerWagons: [Vehicle] = (0..<numContainerWagons).map { i in
        ContainerWagon(direction: .forward)
    }
    let engine = BR186(direction: .forward)
    let freightTrain = Train(
        position: TrainPosition(
            path: pathA,
            position: 600.0.m,
            direction: .forward),
        vehicles: [engine] + containerWagons)
    let numICEWagons = 6
    let iceBack1 = ICE3Head(direction: .backward)
    let iceWagons1: [Vehicle] = (0..<numICEWagons).map { i in
        ICE3Wagon(
            direction: i < numICEWagons / 2 ? .forward : .backward,
            hasPantograph: i == 0 || i == numICEWagons - 1)
    }
    let iceFront1 = ICE3Head(direction: .forward)
    let iceBack2 = ICE3Head(direction: .backward)
    let iceWagons2: [Vehicle] = (0..<numICEWagons).map { i in
        ICE3Wagon(
            direction: i < numICEWagons / 2 ? .forward : .backward,
            hasPantograph: i == 0 || i == numICEWagons - 1)
    }
    let iceFront2 = ICE3Head(direction: .forward)
    let ice = Train(
        position: TrainPosition(path: pathB, position: 500.0.m, direction: .forward),
        vehicles: [iceFront1] + iceWagons1 + [iceBack1] + [iceFront2] + iceWagons2 + [iceBack2])
    map.trains = [freightTrain, ice]
    map.containers = [
        Container(center: Point(x: 0.0.m, y: 20.0.m), orientation: CircleAngle(60.0.deg))
    ]
    map.timer?.fire()
    return map
}

class TrainDispatcherDocument: NSDocument, ChangeObserver {
    private(set) var map: Map = defaultMap()
    let changeManager: ChangeManager = ChangeManager()

    override init() {
        super.init()
        hasUndoManager = false
        changeManager.add(observer: self)
    }

    override class var autosavesInPlace: Bool { true }

    override func makeWindowControllers() {
        let windowController = TrainDispatcherWindowController(
            windowNibName: "TrainDispatcherDocument")
        addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(map)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        let decoder = JSONDecoder()
        map = try decoder.decode(Map.self, from: data)
    }

    override func close() {
        changeManager.remove(observer: self)
    }

    func changeOccurred(manager: ChangeManager) {
        updateChangeCount(.changeDone)
    }

    func changeWasUndone(manager: ChangeManager) {
        updateChangeCount(.changeUndone)
    }

    func changeWasRedone(manager: ChangeManager) {
        updateChangeCount(.changeRedone)
    }

    @IBAction func undoChange(_: NSMenuItem) {
        changeManager.undo()
    }

    @IBAction func redoChange(_: NSMenuItem) {
        changeManager.redo()
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(undoChange(_:)):
            if changeManager.hasUndo {
                menuItem.title = "Undo " + changeManager.undoName
            } else {
                menuItem.title = "Undo"
            }
            return changeManager.canUndo
        case #selector(redoChange(_:)):
            if changeManager.hasRedo {
                menuItem.title = "Redo " + changeManager.redoName
            } else {
                menuItem.title = "Redo"
            }
            return changeManager.canRedo
        default:
            return super.validateMenuItem(menuItem)
        }
    }

}
