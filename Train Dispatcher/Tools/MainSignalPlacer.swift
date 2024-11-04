//
//  MainSignalPlacer.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Base
import CoreGraphics
import Foundation
import Tracks

class MainSignalPlacer: SignalPlacer {
    override var type: ToolType { .mainSignalPlacer }
    override var signalKind: Signal.Kind { .main }
}
