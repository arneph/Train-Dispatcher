//
//  Tool.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/28/24.
//

import Base
import Foundation

protocol ToolOwner: AnyObject, ViewContext {
    var map: Map? { get }
    var changeManager: ChangeManager? { get }

    func stateChanged(tool: Tool)
}

enum ToolType {
    case groundBrush, treePlacer, trackPen
}

protocol Tool: AnyObject, Drawable {
    var type: ToolType { get }

    init(owner: ToolOwner)

    func mouseEntered(point: Point)
    func mouseMoved(point: Point)
    func mouseExited()

    func mouseDown(point: Point)
    func mouseDragged(point: Point)
    func mouseUp(point: Point)
}
