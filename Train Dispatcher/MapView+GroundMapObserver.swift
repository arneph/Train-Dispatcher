//
//  MapView+GroundMapObserver.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Cocoa
import Foundation
import Ground

extension MapView: GroundMapObserver {

    func groundChanged(forMap map: GroundMap) {
        needsDisplay = true
    }

}
