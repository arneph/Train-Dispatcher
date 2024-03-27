//
//  TrainDispatcherWindowController.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/2/23.
//

import Base
import Cocoa
import Foundation

class TrainDispatcherWindowController: NSWindowController, MapViewDelegate {
    var trainDispatcherDocument: TrainDispatcherDocument? { document as? TrainDispatcherDocument }
    var map: Map? { trainDispatcherDocument?.map ?? nil }
    var changeManager: ChangeManager? { trainDispatcherDocument?.changeManager }

    @IBOutlet var mapView: MapView?

    override func windowDidLoad() {
        mapView?.delegate = self
    }

}
