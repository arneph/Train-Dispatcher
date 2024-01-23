//
//  TrainDispatcherWindowController.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/2/23.
//

import Foundation
import Cocoa

class TrainDispatcherWindowController: NSWindowController, MapViewDelegate, NSTextViewDelegate {
    var trainDispatcherDocument: TrainDispatcherDocument { document as! TrainDispatcherDocument }
    var map: Map { trainDispatcherDocument.map }
    var mapText: String { print(map) }
    var commands: [String] = [] {
        didSet {
            commandList?.stringValue = commands.map{ "$ " + $0 }.joined(separator: "\n")
        }
    }

    @IBOutlet var mapView: MapView?
    @IBOutlet var mapTextView: NSTextView?
    @IBOutlet var commandList: NSTextField?
    @IBOutlet var commandField: NSTextField?
    
    override func windowDidLoad() {
        mapView?.delegate = self
        mapTextView?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: NSFont.Weight.regular)
        mapTextView?.string = mapText
        mapTextView?.delegate = self
        commandList?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: NSFont.Weight.regular)
        commandField?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: NSFont.Weight.regular)
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(formatCode(_:)):
            return true
        default:
            return false
        }
    }
    
    @IBAction func formatCode(_ sender: Any?) {
        mapTextView?.string = mapText
    }
    
    func textDidChange(_ notification: Notification) {
        if let map: Map = parse(mapTextView!.string) {
            trainDispatcherDocument.map = map
            mapView?.needsDisplay = true
        }
    }
    
    @IBAction func enteredCommand(_ sender: Any?) {
        let command = commandField!.stringValue
        commandField!.stringValue = ""
        commands.append(command)
    }
    
}
