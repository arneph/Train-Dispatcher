//
//  Container.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Base
import CoreGraphics
import Foundation

public protocol ContainerOwner {
    func position(for: Container) -> ObjectPosition
}

public final class Container: Object {
    public static let length = 12.192.m
    public static let width = 2.438.m
    public static let weight = 26.68.T

    private enum Positioning {
        case freely(ObjectPosition)
        case byOwner(ContainerOwner)
    }
    private var positioning: Positioning

    public var objectPosition: ObjectPosition {
        switch positioning {
        case .freely(let position):
            position
        case .byOwner(let owner):
            owner.position(for: self)
        }
    }
    public var center: Point { objectPosition.center }
    public var orientation: CircleAngle { objectPosition.orientation }

    public func set(owner: ContainerOwner) {
        positioning = .byOwner(owner)
    }
    public func removeOwner() {
        switch positioning {
        case .freely:
            break
        case .byOwner(let owner):
            positioning = .freely(owner.position(for: self))
        }
    }

    public var forward: Angle { orientation.asAngle }
    public var left: Angle { orientation + 90.0.deg }
    public var right: Angle { orientation - 90.0.deg }
    public var backward: Angle { orientation + 180.deg }

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
    public var color: CGColor { Container.colors[colorIndex] }

    public convenience init(center: Point, orientation: CircleAngle) {
        self.init(objectPosition: ObjectPosition(center: center, orientation: orientation))
    }

    public convenience init(center: Point, orientation: CircleAngle, colorIndex: Int) {
        self.init(
            objectPosition: ObjectPosition(center: center, orientation: orientation),
            colorIndex: colorIndex)
    }

    public convenience init(objectPosition: ObjectPosition) {
        self.init(
            objectPosition: objectPosition, colorIndex: Container.colors.indices.randomElement()!)
    }

    public init(objectPosition: ObjectPosition, colorIndex: Int) {
        self.positioning = .freely(objectPosition)
        self.colorIndex = colorIndex
    }

    public convenience init(owner: ContainerOwner) {
        self.init(owner: owner, colorIndex: Container.colors.indices.randomElement()!)
    }

    public init(owner: ContainerOwner, colorIndex: Int) {
        self.positioning = .byOwner(owner)
        self.colorIndex = colorIndex
    }

    enum CodingKeys: String, CodingKey {
        case position
        case colorIndex
    }

    public required init(from decoder: Decoder) throws {
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

    public func encode(to encoder: Encoder) throws {
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
    public func draw(ctx: DrawContext) {
        ctx.saveGState()

        let p1 = center + 0.5 * Container.length ** forward + 0.5 * Container.width ** left
        let p2 = center + 0.5 * Container.length ** backward + 0.5 * Container.width ** left
        let p3 = center + 0.5 * Container.length ** backward + 0.5 * Container.width ** right
        let p4 = center + 0.5 * Container.length ** forward + 0.5 * Container.width ** right

        ctx.move(to: p1)
        ctx.addLine(to: p2)
        ctx.addLine(to: p3)
        ctx.addLine(to: p4)
        ctx.closePath()

        ctx.setFillColor(color)
        ctx.setStrokeColor(CGColor.init(gray: 0.2, alpha: 1.0))
        ctx.drawPath(using: .fillStroke)

        if ctx.mapScale >= 5.0 {
            let lineCount = 15
            ctx.setLineWidth(Container.length / Float64(lineCount) * 0.25)
            ctx.setStrokeColor(CGColor.init(gray: 0.6, alpha: 1.0))
            ctx.setFillColor(CGColor.init(gray: 0.6, alpha: 1.0))

            for i in 0...lineCount {
                let lengthDist = Container.length * (-0.5 + Float64(1 + i) / Float64(lineCount + 2))
                let q1 = center + lengthDist ** forward + 0.4 * Container.width ** left
                let q2 = center + lengthDist ** forward + 0.4 * Container.width ** right

                ctx.move(to: q1)
                ctx.addLine(to: q2)
                ctx.strokePath()
            }
        }

        ctx.restoreGState()
    }

}
