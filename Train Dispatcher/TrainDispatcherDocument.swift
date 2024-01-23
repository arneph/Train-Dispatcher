//
//  Document.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation
import Cocoa

class TrainDispatcherDocument: NSDocument {
    var map: Map = Map()
    
    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool { true }

    override func makeWindowControllers() {
        let windowController = TrainDispatcherWindowController(windowNibName: "TrainDispatcherDocument")
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

}
