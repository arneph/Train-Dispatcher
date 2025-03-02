//
//  SectionSignalPlacer.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Base
import CoreGraphics
import Foundation
import Tracks

class SectionSignalPlacer: SignalPlacer {
    override var type: ToolType { .sectionSignalPlacer }
    override var signalKind: Signal.Kind { .section }
}
