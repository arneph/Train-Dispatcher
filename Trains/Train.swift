//
//  Train.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 7/27/24.
//

import Base
import CoreGraphics
import Foundation

public struct TrainPosition: Codable {
    public enum Direction: Codable {
        case forward, backward
    }

    public let path: SomeFinitePath
    public let position: Position
    public let direction: Direction

    public init(path: SomeFinitePath, position: Position, direction: Direction) {
        self.path = path
        self.position = position
        self.direction = direction
    }
}

public class Train: Codable, Drawable {
    private var observers: [TrainObserver] = []

    public func add(observer: TrainObserver) { observers.append(observer) }
    public func remove(observer: TrainObserver) { observers.removeAll { $0 === observer } }

    public var position: TrainPosition {
        didSet {
            updateVehiclePositions()
            observers.forEach { $0.positionChanged(self) }
        }
    }
    public private(set) var vehicles: [Vehicle]

    private func updateVehiclePositions() {
        var x = position.position
        var previousSecondOverhang = 0.0.m
        for vehicle in vehicles {
            let (firstOverhang, secondOverhang) =
                switch vehicle.direction {
                case .forward: (vehicle.frontOverhang, vehicle.backOverhang)
                case .backward: (vehicle.backOverhang, vehicle.frontOverhang)
                }
            let d = previousSecondOverhang + firstOverhang
            x =
                switch position.direction {
                case .forward: position.path.lastPointOnPath(atDistance: d, before: x)!
                case .backward: position.path.firstPointOnPath(atDistance: d, after: x)!
                }
            let firstAxle = position.path.point(at: x)!
            x =
                switch position.direction {
                case .forward:
                    position.path.lastPointOnPath(
                        atDistance: vehicle.distanceBetweenAxles,
                        before: x)!
                case .backward:
                    position.path.firstPointOnPath(
                        atDistance: vehicle.distanceBetweenAxles,
                        after: x)!
                }
            let secondAxle = position.path.point(at: x)!
            switch vehicle.direction {
            case .forward:
                vehicle.setPosition(frontAxle: firstAxle, backAxle: secondAxle)
            case .backward:
                vehicle.setPosition(frontAxle: secondAxle, backAxle: firstAxle)
            }
            previousSecondOverhang = secondOverhang
        }
    }

    public var length: Distance { vehicles.map { $0.length }.reduce(0.0.m, +) }
    public var weight: Mass { vehicles.map { $0.weight }.reduce(0.0.kg, +) }

    public var maxAccelerationForce: Force {
        vehicles.map {
            $0.maxAccelerationForce
        }.reduce(0.0.N, +)
    }
    public var maxBrakeForce: Force { vehicles.map { $0.maxBrakeForce }.reduce(0.0.N, +) }

    public var maxSpeed: Speed { min(vehicles.map { $0.maxSpeed }) }

    public enum DirectionMode: Codable {
        case forward, neutral, backward
    }
    public var direction: DirectionMode = .neutral {
        didSet {
            observers.forEach { $0.directionChanged(self) }
            if direction == .neutral {
                accelerationForce = 0.0.N
                brakeForce = maxBrakeForce
            }
        }
    }
    public var accelerationForce: Force = 0.0.N {
        didSet {
            observers.forEach { $0.accelerationForceChanged(self) }
        }
    }
    public var brakeForce: Force {
        didSet {
            observers.forEach { $0.brakeForceChanged(self) }
        }
    }

    public var acceleration: Acceleration {
        let force = accelerationForce - brakeForce
        let m =
            switch direction {
            case .forward:
                +1.0
            case .neutral:
                0.0
            case .backward:
                -1.0
            }
        return force * m / weight
    }

    public private(set) var speed: Speed = 0.0.mps {
        didSet {
            observers.forEach { $0.speedChanged(self) }
        }
    }

    public func tick(_ delta: Duration) {
        var newSpeed = speed + acceleration * delta
        switch direction {
        case .forward:
            newSpeed = max(0.0.mps, min(newSpeed, maxSpeed))
        case .neutral:
            newSpeed = 0.0.mps
        case .backward:
            newSpeed = min(0.0.mps, max(newSpeed, -maxSpeed))
        }
        speed = newSpeed
        position = TrainPosition(
            path: position.path,
            position: position.position + speed * delta,
            direction: position.direction)
    }

    public func draw(ctx: DrawContext) {
        vehicles.forEach { $0.draw(ctx: ctx) }
    }

    public init(position: TrainPosition, vehicles: [Vehicle]) {
        self.position = position
        self.vehicles = vehicles
        self.brakeForce = vehicles.map { $0.maxBrakeForce }.reduce(0.0.N, +)
        updateVehiclePositions()
    }

    private enum CodingKeys: String, CodingKey {
        case position, vehicles, direction, accelerationForce, brakeForce, speed
    }

    public required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.position = try values.decode(TrainPosition.self, forKey: .position)
        self.vehicles =
            (try values.decode(
                [EncodedVehicle].self,
                forKey: .vehicles)).map { $0.underlying }
        self.direction = try values.decode(DirectionMode.self, forKey: .direction)
        self.accelerationForce = try values.decode(Force.self, forKey: .accelerationForce)
        self.brakeForce = try values.decode(Force.self, forKey: .brakeForce)
        self.speed = try values.decode(Speed.self, forKey: .speed)
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(position, forKey: .position)
        try values.encode(vehicles.map { EncodedVehicle($0) }, forKey: .vehicles)
        try values.encode(direction, forKey: .direction)
        try values.encode(accelerationForce, forKey: .accelerationForce)
        try values.encode(brakeForce, forKey: .brakeForce)
        try values.encode(speed, forKey: .speed)
    }

}
