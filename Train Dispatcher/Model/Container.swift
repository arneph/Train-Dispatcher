//
//  Container.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Base
import CoreGraphics
import Foundation

protocol ContainerOwner {
    func position(for: Container) -> ObjectPosition
}

final class Container: Object {
    static let length = 12.192.m
    static let width = 2.438.m

    private enum Positioning {
        case freely(ObjectPosition)
        case byOwner(ContainerOwner)
    }
    private var positioning: Positioning

    var objectPosition: ObjectPosition {
        switch positioning {
        case .freely(let position):
            position
        case .byOwner(let owner):
            owner.position(for: self)
        }
    }
    var center: Point { objectPosition.center }
    var orientation: CircleAngle { objectPosition.orientation }

    func set(owner: ContainerOwner) {
        positioning = .byOwner(owner)
    }
    func removeOwner() {
        switch positioning {
        case .freely:
            break
        case .byOwner(let owner):
            positioning = .freely(owner.position(for: self))
        }
    }

    var forward: Angle { orientation.asAngle }
    var left: Angle { orientation + 90.0.deg }
    var right: Angle { orientation - 90.0.deg }
    var backward: Angle { orientation + 180.deg }

    private static let colors =
        [
            CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            CGColor.init(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0),
            CGColor.init(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
            CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            CGColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
            CGColor.init(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0),
            CGColor.init(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),
            CGColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0),
            CGColor.init(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
        ]
    private let colorIndex: Int
    var color: CGColor { Container.colors[colorIndex] }

    convenience init(center: Point, orientation: CircleAngle) {
        self.init(objectPosition: ObjectPosition(center: center, orientation: orientation))
    }

    convenience init(center: Point, orientation: CircleAngle, colorIndex: Int) {
        self.init(
            objectPosition: ObjectPosition(center: center, orientation: orientation),
            colorIndex: colorIndex)
    }

    convenience init(objectPosition: ObjectPosition) {
        self.init(
            objectPosition: objectPosition, colorIndex: Container.colors.indices.randomElement()!)
    }

    init(objectPosition: ObjectPosition, colorIndex: Int) {
        self.positioning = .freely(objectPosition)
        self.colorIndex = colorIndex
    }

    convenience init(owner: ContainerOwner) {
        self.init(owner: owner, colorIndex: Container.colors.indices.randomElement()!)
    }

    init(owner: ContainerOwner, colorIndex: Int) {
        self.positioning = .byOwner(owner)
        self.colorIndex = colorIndex
    }

    enum CodingKeys: String, CodingKey {
        case position
        case colorIndex
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let position = try values.decode(ObjectPosition?.self, forKey: .position) {
            self.positioning = .freely(position)
        } else {
            self.positioning = .freely(
                ObjectPosition(
                    center: Point.init(x: 0.0.m, y: 0.0.m), orientation: CircleAngle(0.0.deg)))
        }
        colorIndex = try values.decode(Int.self, forKey: .colorIndex)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        switch positioning {
        case .freely(let position):
            try values.encode(position, forKey: CodingKeys.position)
        case .byOwner:
            try values.encode((Position?)(nil), forKey: CodingKeys.position)
        }
        try values.encode(colorIndex, forKey: CodingKeys.colorIndex)
    }

    // MARK: -  Drawing
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext, _: Rect) {
        cgContext.saveGState()

        let p1 = center + 0.5 * Container.length ** forward + 0.5 * Container.width ** left
        let p2 = center + 0.5 * Container.length ** backward + 0.5 * Container.width ** left
        let p3 = center + 0.5 * Container.length ** backward + 0.5 * Container.width ** right
        let p4 = center + 0.5 * Container.length ** forward + 0.5 * Container.width ** right

        cgContext.move(to: viewContext.toViewPoint(p1))
        cgContext.addLine(to: viewContext.toViewPoint(p2))
        cgContext.addLine(to: viewContext.toViewPoint(p3))
        cgContext.addLine(to: viewContext.toViewPoint(p4))
        cgContext.closePath()

        cgContext.setFillColor(color)
        cgContext.setStrokeColor(CGColor.init(gray: 0.2, alpha: 1.0))
        cgContext.drawPath(using: .fillStroke)

        if viewContext.mapScale >= 5.0 {
            let lineCount = 15
            cgContext.setLineWidth(
                viewContext.toViewDistance(Container.length / Float64(lineCount) * 0.25))
            cgContext.setStrokeColor(CGColor.init(gray: 0.6, alpha: 1.0))
            cgContext.setFillColor(CGColor.init(gray: 0.6, alpha: 1.0))

            for i in 0...lineCount {
                let lengthDist = Container.length * (-0.5 + Float64(1 + i) / Float64(lineCount + 2))
                let q1 = center + lengthDist ** forward + 0.4 * Container.width ** left
                let q2 = center + lengthDist ** forward + 0.4 * Container.width ** right

                cgContext.move(to: viewContext.toViewPoint(q1))
                cgContext.addLine(to: viewContext.toViewPoint(q2))
                cgContext.strokePath()
            }
        }

        cgContext.restoreGState()
    }

}
