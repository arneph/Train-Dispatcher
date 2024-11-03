//
//  MapView+ToolOwner.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Foundation
import Trains

extension MapView: ToolOwner {

    func stateChanged(tool: Tool) {
        needsDisplay = true
    }

    func selectTrain(train: Train) {
        delegate?.selectedTrain(train: train)
    }

}
