//
//  Track.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Foundation
import CoreGraphics

fileprivate let gauge = 1.435.m
fileprivate let railTopWidth = 0.05.m
fileprivate let railBottomWidth = 0.2.m
fileprivate let sleeperLength = gauge + 0.5.m
fileprivate let sleeperWidth = 0.25.m
fileprivate let minSleeperOffset = 0.6.m
let trackBedWidth = sleeperLength + 1.5.m

final class Track: Codable, CodeRepresentable {
    let path: SomeFinitePath
    let leftRail: SomeFinitePath
    let rightRail: SomeFinitePath
    
    init(path: SomeFinitePath) {
        self.path = path
        self.leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
        self.rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
    }
    
    private enum CodingKeys: String, CodingKey {
        case path
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try values.decode(SomeFinitePath.self, forKey: .path)
        self.leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
        self.rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(path, forKey: .path)
    }
    
    private static let name = "Track"
    private static let pathLabel = "path"
    
    static func parseCode(with scanner: Scanner) -> Track? {
        parseStruct(name: name, scanner: scanner) {
            guard let path: SomeFinitePath = parseArgument(label: pathLabel,
                                                           scanner: scanner) else {
                return nil
            }
            return Track(path: path)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: Track.name, printer: printer) {
            print(label: Track.pathLabel, argument: path, printer: printer)
        }
    }
    
}

extension Array: Drawable where Element: Track {
    
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext) {
        cgContext.saveGState()
        if viewContext.mapScale < 5.0 {
            for track in self {
                drawWithLowDetail(track, cgContext, viewContext)
            }
        } else {
            for drawFunc in [drawBedFoundations, drawBed, drawSleepers, drawRails] {
                for track in self {
                    drawFunc(track, cgContext, viewContext)
                }
            }
        }
        cgContext.restoreGState()
    }
    
}

fileprivate func drawWithLowDetail(_ track: Track,
                               _ cgContext: CGContext,
                               _ viewContext: ViewContext) {
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

fileprivate func drawBedFoundations(_ track: Track,
                                    _ cgContext: CGContext,
                                    _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.7, blue: 0.65, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(trackBedWidth))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

fileprivate func drawBed(_ track: Track,
                         _ cgContext: CGContext,
                         _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperLength + 0.6.m))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

fileprivate func drawSleepers(_ track: Track,
                              _ cgContext: CGContext,
                              _ viewContext: ViewContext) {
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

fileprivate func drawRails(_ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(gray: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(railBottomWidth))
    for rail in [track.leftRail, track.rightRail] {
        trace(path: rail, cgContext, viewContext)
        cgContext.drawPath(using: .stroke)
    }
}
