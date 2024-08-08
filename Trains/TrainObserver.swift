//
//  TrainObserver.swift
//  Trains
//
//  Created by Arne Philipeit on 8/4/24.
//

import Foundation

public protocol TrainObserver: AnyObject {
    func positionChanged(_ train: Train)
}

extension TrainObserver {
    public func positionChanged(_ train: Train) {}
}
