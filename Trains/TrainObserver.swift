//
//  TrainObserver.swift
//  Trains
//
//  Created by Arne Philipeit on 8/4/24.
//

import Foundation

public protocol TrainObserver: AnyObject {
    func positionChanged(_ train: Train)
    func speedChanged(_ train: Train)
    func directionChanged(_ train: Train)
    func accelerationForceChanged(_ train: Train)
    func brakeForceChanged(_ train: Train)
}
