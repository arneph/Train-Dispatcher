//
//  DrawContext+Paths.swift
//  Base
//
//  Created by Arne Philipeit on 10/26/24.
//

import Foundation

extension DrawContext {
    private func stroke(visiblePath path: LinearPath, _ width: Distance) {
        move(to: path.start)
        addLine(to: path.end)
        drawPath(using: .stroke)
    }

    public func stroke(path: LinearPath, _ width: Distance) {
        for segment in path.segments(inRect: dirtyRect.insetBy(dx: -width, dy: -width)) {
            move(to: path.point(at: segment.lowerBound)!)
            addLine(to: path.point(at: segment.upperBound)!)
            drawPath(using: .stroke)
        }
    }

    private func stroke(visiblePath path: CircularPath, _ width: Distance) {
        move(to: path.start)
        addArc(
            center: path.center,
            radius: path.radius,
            startAngle: path.circleRange.startAngle,
            endAngle: path.circleRange.startAngle + path.circleRange.delta,
            clockwise: path.circleRange.direction == .negative)
        drawPath(using: .stroke)
    }

    public func stroke(path: CircularPath, _ width: Distance) {
        for segment in path.segments(inRect: dirtyRect.insetBy(dx: -width, dy: -width)) {
            move(to: path.point(at: segment.lowerBound)!)
            addArc(
                center: path.center,
                radius: path.radius,
                startAngle: path.toCircleAngle(segment.lowerBound).asAngle,
                endAngle: path.toCircleAngle(segment.upperBound).asAngle,
                clockwise: path.circleRange.direction == .negative)
            drawPath(using: .stroke)
        }
    }

    private func stroke(visiblePath path: CompoundPath, _ width: Distance) {
        for component in path.components {
            move(to: component.start)
            switch component {
            case .linear(let component):
                addLine(to: component.end)
            case .circular(let component):
                addArc(
                    center: component.center,
                    radius: component.radius,
                    startAngle: component.circleRange.startAngle,
                    endAngle: component.circleRange.startAngle + component.circleRange.delta,
                    clockwise: component.circleRange.direction == .negative)
            }
            drawPath(using: .stroke)
        }
    }

    public func stroke(path: CompoundPath, _ width: Distance) {
        for segment in path.segments(
            inRect: dirtyRect.insetBy(
                dx: -width,
                dy: -width))
        {
            guard let visiblePath = path.subPath(from: segment.lowerBound, to: segment.upperBound)
            else {
                continue
            }
            stroke(visiblePath: visiblePath, width)
        }
    }

    public func stroke(path: AtomicFinitePath, _ width: Distance) {
        switch path {
        case .linear(let path):
            stroke(path: path, width)
        case .circular(let path):
            stroke(path: path, width)
        }
    }

    private func stroke(visiblePath path: SomeFinitePath, _ width: Distance) {
        switch path {
        case .linear(let path):
            stroke(visiblePath: path, width)
        case .circular(let path):
            stroke(visiblePath: path, width)
        case .compound(let path):
            stroke(visiblePath: path, width)
        }
    }

    public func stroke(path: SomeFinitePath, _ width: Distance) {
        switch path {
        case .linear(let path):
            stroke(path: path, width)
        case .circular(let path):
            stroke(path: path, width)
        case .compound(let path):
            stroke(path: path, width)
        }
    }

    public func stroke(loop: Loop, width: Distance) {
        stroke(path: loop.underlying, width)
    }
}
