//
//  TreePlacer.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 4/27/24.
//

import Base
import CoreGraphics
import Foundation
import Ground

class TreePlacer: Tool {
    var type: ToolType { .treePlacer }

    private weak var owner: ToolOwner?
    private var map: Map? { owner?.map }
    private var groundMap: GroundMap? { owner?.map?.groundMap }
    private var changeManager: ChangeManager? { owner?.changeManager }
    
    required init(owner: any ToolOwner) {
        self.owner = owner
    }
    
    func mouseEntered(point: Point) {
        
    }
    
    func mouseMoved(point: Point) {
        
    }
    
    func mouseExited() {
        
    }
    
    func mouseDown(point: Point) {
        
    }
    
    func mouseDragged(point: Point) {
        
    }
    
    func mouseUp(point: Point) {
        
    }
    
    func draw(layer: ToolDrawingLayer, ctx: DrawContext) {
        
    }
}
