//
//  Tool.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/28/24.
//

import Base
import CoreGraphics
import Foundation
import Trains

protocol ToolOwner: AnyObject, ViewContext {
    var map: Map? { get }
    var changeManager: ChangeManager? { get }

    func stateChanged(tool: Tool)
    func selectTrain(train: Train)
}

enum ToolType {
    case cursor, groundBrush, treePlacer, trackPen, sectionCutter, sectionSignalPlacer,
        mainSignalPlacer
}

enum ToolDrawingLayer {
    case aboveGroundMap, aboveTrackMap, aboveTrains
}

protocol Tool: AnyObject {
    var type: ToolType { get }

    init(owner: ToolOwner)

    func mouseEntered(point: Point)
    func mouseMoved(point: Point)
    func mouseExited()

    func mouseDown(point: Point)
    func mouseDragged(point: Point)
    func mouseUp(point: Point)

    func draw(layer: ToolDrawingLayer, ctx: DrawContext)
}
