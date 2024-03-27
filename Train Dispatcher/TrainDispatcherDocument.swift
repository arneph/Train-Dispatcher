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

private func defaultMap() -> Map {
    let map = Map()
    let (_, _) = map.trackMap.addTrack(
        withPath: .compound(
            CompoundPath(components: [
                .linear(
                    LinearPath(
                        start: Point(x: -50.0.m, y: 0.0.m), end: Point(x: 0.0.m, y: 0.0.m))!),
                .circular(
                    CircularPath(
                        center: Point(x: 0.0.m, y: 120.0.m), radius: 120.0.m,
                        startAngle: CircleAngle(-90.0.deg), endAngle: CircleAngle(0.0.deg),
                        direction: .positive)!),
            ])!), startConnection: .none, endConnection: .none)
    map.vehicles = [
        ContainerWagon(
            vehiclePosition:
                VehiclePosition(
                    path: LinearPath(
                        start: Point(x: -50.0.m, y: 0.0.m), end: Point(x: 0.0.m, y: 0.0.m))!,
                    pathPosition: 10.0.m)),
        ContainerWagon(
            vehiclePosition:
                VehiclePosition(
                    path: LinearPath(
                        start: Point(x: -50.0.m, y: 0.0.m), end: Point(x: 0.0.m, y: 0.0.m))!,
                    pathPosition: 10.0.m + ContainerWagon.length)),
        ContainerWagon(
            vehiclePosition:
                VehiclePosition(
                    path: LinearPath(
                        start: Point(x: -50.0.m, y: 0.0.m), end: Point(x: 0.0.m, y: 0.0.m))!,
                    pathPosition: 10.0.m + ContainerWagon.length * 2.0)),
        ContainerWagon(
            vehiclePosition:
                VehiclePosition(
                    path: CircularPath(
                        center: Point(x: 0.0.m, y: 120.0.m), radius: 120.0.m,
                        startAngle: CircleAngle(-90.0.deg), endAngle: CircleAngle(0.0.deg),
                        direction: .positive)!, pathPosition: 30.0.m)),
    ]
    map.containers = [
        Container(center: Point(x: 0.0.m, y: 10.0.m), orientation: CircleAngle(60.0.deg))
    ]
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
