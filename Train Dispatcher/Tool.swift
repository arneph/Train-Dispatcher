//
//  Tool.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/28/24.
//

import Foundation

protocol ToolOwner: AnyObject {
    var map: Map { get }
    
    func stateChanged(tool: Tool)
}

protocol Tool: AnyObject, Drawable {
    init(owner: ToolOwner)
    
    func mouseEntered(point: Point)
    func mouseMoved(point: Point)
    func mouseExited()
    
    func mouseDown(point: Point)
    func mouseDragged(point: Point)
    func mouseUp(point: Point)
}
