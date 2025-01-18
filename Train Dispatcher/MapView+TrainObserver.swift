//
//  MapView+TrainObserver.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Cocoa
import Foundation
import Trains

extension MapView: TrainObserver {

    func positionChanged(_ train: Train) {
        needsDisplay = true
    }

    func speedChanged(_ train: Trains.Train) {}

    func directionChanged(_ train: Trains.Train) {}

    func accelerationForceChanged(_ train: Trains.Train) {}

    func brakeForceChanged(_ train: Trains.Train) {}

}
