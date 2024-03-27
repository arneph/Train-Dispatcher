//
//  Drawing.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/9/24.
//

import Base
import CoreGraphics
import Foundation

public func draw(tracks: some Sequence<Track>, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.saveGState()
    if viewContext.mapScale < 5.0 {
        for track in tracks {
            drawWithLowDetail(track, cgContext, viewContext)
        }
    } else {
        for drawFunc in [drawBedFoundations, drawBed, drawSleepers, drawRails] {
            for track in tracks {
                drawFunc(track, cgContext, viewContext)
            }
        }
    }
    cgContext.restoreGState()
}

private func drawWithLowDetail(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext
) {
    switch viewContext.style {
    case .light:
        cgContext.setStrokeColor(CGColor.init(gray: 0.35, alpha: 1.0))
    case .dark:
        cgContext.setStrokeColor(CGColor.init(gray: 0.7, alpha: 1.0))
    }
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperLength))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

private func drawBedFoundations(_ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext)
{
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.7, blue: 0.65, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(trackBedWidth))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

private func drawBed(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext
) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperLength + 0.6.m))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

private func drawSleepers(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext
) {
    cgContext.setStrokeColor(CGColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperWidth))
    let startS = sleeperWidth
    let endS = track.path.length - sleeperWidth
    let deltaS = endS - startS
    let stepS = deltaS / floor(deltaS / minSleeperOffset)
    for s in stride(from: startS.withoutUnit, through: endS.withoutUnit, by: stepS.withoutUnit) {
        let center = track.path.point(at: Distance(s))!
        let orientation = track.path.orientation(at: Distance(s))!
        let left = center + 0.5 * sleeperLength ** (orientation + 90.0.deg)
        let right = center + 0.5 * sleeperLength ** (orientation - 90.0.deg)
        cgContext.move(to: viewContext.toViewPoint(left))
        cgContext.addLine(to: viewContext.toViewPoint(right))
        cgContext.drawPath(using: .stroke)
    }
}

private func drawRails(_ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(gray: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(railBottomWidth))
    for rail in [track.leftRail, track.rightRail] {
        trace(path: rail, cgContext, viewContext)
        cgContext.drawPath(using: .stroke)
    }
}
