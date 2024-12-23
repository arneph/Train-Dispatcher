//
//  GroundBrush.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 4/27/24.
//

import Base
import CoreGraphics
import Foundation
import Ground

class GroundBrush: Tool {
    var type: ToolType { .groundBrush }

    private weak var owner: ToolOwner?
    private var map: Map? { owner?.map }
    private var groundMap: GroundMap? { owner?.map?.groundMap }
    private var changeManager: ChangeManager? { owner?.changeManager }

    private enum State {
        case none
        case hovering(Point)
        case painting(Point)
    }
    private var state: State = .none {
        didSet {
            owner?.stateChanged(tool: self)
        }
    }

    var color: Color = Color(red: 0, green: 127, blue: 255, alpha: 255) {
        didSet {
            owner?.stateChanged(tool: self)
        }
    }

    var diameter: Distance = 3.0.m {
        didSet {
            owner?.stateChanged(tool: self)
        }
    }

    required init(owner: any ToolOwner) {
        self.owner = owner
    }

    func mouseEntered(point: Point) {
        state = .hovering(point)
    }

    func mouseMoved(point: Point) {
        state = .hovering(point)
    }

    func mouseExited() {
        state = .none
    }

    func mouseDown(point: Point) {
        state = .painting(point)
        groundMap?.paintCircle(at: point, withDiameter: diameter, inColor: color)
    }

    func mouseDragged(point: Point) {
        let oldPoint: Point?
        switch state {
        case .none, .hovering(_):
            oldPoint = nil
        case .painting(let point):
            oldPoint = point
        }
        state = .painting(point)
        if let oldPoint = oldPoint {
            if oldPoint == point {
                return
            }
            groundMap?.paintLine(from: oldPoint, to: point, withWidth: diameter, inColor: color)
        }
        groundMap?.paintCircle(at: point, withDiameter: diameter, inColor: color)
    }

    func mouseUp(point: Point) {
        state = .hovering(point)
    }

    func draw(layer: ToolDrawingLayer, ctx: DrawContext) {
        guard layer == .aboveGroundMap else { return }
        switch state {
        case .none:
            break
        case .hovering(let point):
            ctx.saveGState()
            ctx.setLineDash(phase: 0.0.m, lengths: [diameter / 5.0])
            ctx.setLineWidth(diameter / 20.0)
            ctx.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
            ctx.strokeCircle(at: point, radius: 0.5 * diameter)
            ctx.restoreGState()
        case .painting(let point):
            ctx.saveGState()
            ctx.setLineWidth(diameter / 20.0)
            ctx.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
            ctx.strokeCircle(at: point, radius: 0.5 * diameter)
            ctx.restoreGState()
        }
    }

}
