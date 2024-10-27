//
//  ContainerWagon.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Base
import CoreGraphics
import Foundation

public final class ContainerWagon: Vehicle, ContainerOwner {
    static let length = 2.0 * bufferLength + platformLength
    static let bufferLength = 0.25.m
    static let platformLength = Container.length + 0.40.m
    static let width = Container.width + 0.54.m

    public override var length: Distance { ContainerWagon.length }
    public override var frontOverhang: Distance { 3.0.m }
    public override var backOverhang: Distance { 3.0.m }
    public override var width: Distance { ContainerWagon.width }
    public override var weight: Mass {
        16.0.T + (container != nil ? Container.weight : 0.0.kg)
    }
    public override var maxAccelerationForce: Force { 0.0.N }
    public override var maxBrakeForce: Force { 20_000.N }
    public override var maxSpeed: Speed { 120.0.kph }

    var container: Container? {
        didSet {
            if oldValue === container {
                return
            }
            oldValue?.removeOwner()
            container?.set(owner: self)
        }
    }

    public func position(for container: Container) -> ObjectPosition { objectPosition }

    public override init(direction: Vehicle.Direction) {
        super.init(direction: direction)
        self.container = Container(owner: self)
    }

    public init(direction: Vehicle.Direction, container: Container) {
        super.init(direction: direction)
        self.container = container
    }

    private enum CodingKeys: String, CodingKey {
        case container
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.container = try values.decode(Container?.self, forKey: .container)
        try super.init(from: values.superDecoder())
        self.container?.set(owner: self)
    }

    public override func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(container, forKey: .container)
        try super.encode(to: values.superEncoder())
    }

    // MARK: -  Drawing
    public override func draw(ctx: DrawContext) {
        if !Rect.intersect(
            ctx.dirtyRect, Rect.square(around: center, length: ContainerWagon.length))
        {
            return
        }
        ctx.saveGState()

        let p1 =
            center + 0.5 * ContainerWagon.platformLength ** forward
            + 0.5 * ContainerWagon.width ** left
        let p2 =
            center + 0.5 * ContainerWagon.platformLength ** backward
            + 0.5 * ContainerWagon.width ** left
        let p3 =
            center + 0.5 * ContainerWagon.platformLength ** backward
            + 0.5 * ContainerWagon.width ** right
        let p4 =
            center + 0.5 * ContainerWagon.platformLength ** forward
            + 0.5 * ContainerWagon.width ** right

        ctx.move(to: p1)
        ctx.addLine(to: p2)
        ctx.addLine(to: p3)
        ctx.addLine(to: p4)
        ctx.closePath()

        ctx.setFillColor(CGColor(red: 0.47, green: 0.42, blue: 0.36, alpha: 1.0))
        ctx.fillPath()

        container?.draw(ctx: ctx)

        ctx.restoreGState()
    }

}
