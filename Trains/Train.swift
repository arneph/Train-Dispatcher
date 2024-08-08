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

    public func draw(_ cgContext: CGContext, _ viewContext: any ViewContext, _ dirtyRect: Rect) {
        vehicles.forEach { $0.draw(cgContext, viewContext, dirtyRect) }
    }

    public init(position: TrainPosition, vehicles: [Vehicle]) {
        self.position = position
        self.vehicles = vehicles
        updateVehiclePositions()
    }

    private enum CodingKeys: String, CodingKey {
        case position, vehicles
    }

    public required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.position = try values.decode(TrainPosition.self, forKey: .position)
        self.vehicles =
            (try values.decode(
                [EncodedVehicle].self,
                forKey: .vehicles)).map { $0.underlying }
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(position, forKey: .position)
        try values.encode(vehicles.map { EncodedVehicle($0) }, forKey: .vehicles)
    }

}
