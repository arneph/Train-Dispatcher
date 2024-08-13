//
//  Vehicle.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Base
import CoreGraphics
import Foundation

public class Vehicle: Object {
    public enum Direction: Codable {
        case forward, backward
    }

    public internal(set) var direction: Direction
    public private(set) var frontAxle: Point
    public private(set) var backAxle: Point
    public private(set) var objectPosition: ObjectPosition

    func setPosition(frontAxle: Point, backAxle: Point) {
        self.frontAxle = frontAxle
        self.backAxle = backAxle
        let orientation = angle(from: backAxle, to: frontAxle)
        let p1 = frontAxle + frontOverhang ** orientation
        let p2 = backAxle - backOverhang ** orientation
        let center = Point(
            x: 0.5 * (p1.x + p2.x),
            y: 0.5 * (p1.y + p2.y))
        self.objectPosition = ObjectPosition(center: center, orientation: CircleAngle(orientation))
    }

    public var length: Distance {
        assertionFailure("Vehicle.length was not overwritten")
        return 0.0.m
    }
    public var frontOverhang: Distance {
        assertionFailure("Vehicle.frontOverhang was not overwritten")
        return 0.0.m
    }
    public var backOverhang: Distance {
        assertionFailure("Vehicle.backOverhang was not overwritten")
        return 0.0.m
    }
    public var distanceBetweenAxles: Distance { length - frontOverhang - backOverhang }
    public var width: Distance {
        assertionFailure("Vehicle.width was not overwritten")
        return 0.0.m
    }

    public var weight: Mass {
        assertionFailure("Vehicle.weight was not overwritten")
        return 0.0.kg
    }

    public var maxAccelerationForce: Force {
        assertionFailure("Vehicle.accelerationForce was not overwritten")
        return 0.0.N
    }
    public var maxBrakeForce: Force {
        assertionFailure("Vehicle.brakeForce was not overwritten")
        return 0.0.N
    }

    public var maxSpeed: Speed {
        assertionFailure("Vehicle.maxSpeed was not overwritten")
        return 0.0.mps
    }

    public var center: Point { objectPosition.center }
    public var orientation: CircleAngle { objectPosition.orientation }

    public var forward: Angle { objectPosition.forward }
    public var left: Angle { objectPosition.left }
    public var right: Angle { objectPosition.right }
    public var backward: Angle { objectPosition.backward }

    public func draw(_: CGContext, _: any Base.ViewContext, _: Base.Rect) {
        assertionFailure("Vehicle.draw was not overwritten")
    }

    public init(direction: Direction) {
        self.direction = direction
        self.backAxle = Point(x: 0.0.m, y: 0.0.m)
        self.frontAxle = Point(x: 0.0.m, y: 0.0.m)
        self.objectPosition = ObjectPosition(
            center: Point(x: 0.0.m, y: 0.0.m),
            orientation: CircleAngle(0.0.deg))
        // Set actual values after all members have been initialized.
        self.setPosition(
            frontAxle: Point(x: 0.0.m, y: 0.0.m),
            backAxle: Point(x: distanceBetweenAxles, y: 0.0.m))
    }

    private enum CodingKeys: String, CodingKey {
        case direction, frontAxle, backAxle
    }

    public required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.direction = try values.decode(Direction.self, forKey: .direction)
        self.frontAxle = try values.decode(Point.self, forKey: .frontAxle)
        self.backAxle = try values.decode(Point.self, forKey: .backAxle)
        self.objectPosition = ObjectPosition(
            center: Point(x: 0.0.m, y: 0.0.m),
            orientation: CircleAngle(0.0.deg))
        self.setPosition(frontAxle: frontAxle, backAxle: backAxle)
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(direction, forKey: .direction)
        try values.encode(frontAxle, forKey: .frontAxle)
        try values.encode(backAxle, forKey: .backAxle)
    }

}

enum EncodedVehicle: Codable {
    case container(ContainerWagon)
    case br186(BR186)
    case ice3Head(ICE3Head)
    case ice3Wagon(ICE3Wagon)

    var underlying: Vehicle {
        switch self {
        case .container(let vehicle): vehicle
        case .br186(let vehicle): vehicle
        case .ice3Head(let vehicle): vehicle
        case .ice3Wagon(let vehicle): vehicle
        }
    }

    init(_ underlying: Vehicle) {
        if let vehicle = underlying as? ContainerWagon {
            self = .container(vehicle)
        } else if let vehicle = underlying as? BR186 {
            self = .br186(vehicle)
        } else if let vehicle = underlying as? ICE3Head {
            self = .ice3Head(vehicle)
        } else if let vehicle = underlying as? ICE3Wagon {
            self = .ice3Wagon(vehicle)
        } else {
            fatalError("Unexpected Vehicle type")
        }
    }

}
