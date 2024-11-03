//
//  SectionCutter.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Base
import CoreGraphics
import Foundation
import Tracks

class SectionCutter: Tool {
    var type: ToolType { .sectionCutter }

    private weak var owner: ToolOwner?
    private var map: Map? { owner?.map }
    private var trackMap: TrackMap? { owner?.map?.trackMap }
    private var changeManager: ChangeManager? { owner?.changeManager }

    required init(owner: any ToolOwner) {
        self.owner = owner
    }

    func mouseEntered(point: Base.Point) {

    }

    func mouseMoved(point: Base.Point) {

    }

    func mouseExited() {

    }

    func mouseDown(point: Base.Point) {

    }

    func mouseDragged(point: Base.Point) {

    }

    func mouseUp(point: Base.Point) {

    }

    func draw(layer: ToolDrawingLayer, ctx: Base.DrawContext) {

    }
}
