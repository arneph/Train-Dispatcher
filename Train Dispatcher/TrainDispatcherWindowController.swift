//
//  TrainDispatcherWindowController.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/2/23.
//

import Foundation
import Cocoa

class TrainDispatcherWindowController: NSWindowController, MapViewDelegate {
    var trainDispatcherDocument: TrainDispatcherDocument? { document as? TrainDispatcherDocument }
    var map: Map? { trainDispatcherDocument?.map ?? nil }

    @IBOutlet var mapView: MapView?
    
    override func windowDidLoad() {
        mapView?.delegate = self
    }
        
}
