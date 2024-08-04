//
//  Vehicle.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Base
import Foundation

struct VehiclePosition: Codable {
    enum Direction: Codable, Equatable {
        case forward
        case backward
    }

    let path: any FinitePath
    let pathPosition: Position
    let direction: Direction

    var center: Point { path.point(at: pathPosition)! }
    var orientation: CircleAngle { path.orientation(at: pathPosition)! }
    var objectPosition: ObjectPosition {
        ObjectPosition(center: center, orientation: forward)
    }

    var forward: CircleAngle {
        switch direction {
        case .forward:
            orientation
        case .backward:
            orientation.opposite
        }
    }
    var left: Angle { forward + 90.0.deg }
    var right: Angle { forward - 90.0.deg }
    var backward: Angle { forward + 180.deg }

    private enum CodingKeys: String, CodingKey {
        case path, pathPosition, direction
    }

    init(path: any FinitePath, pathPosition: Position, direction: Direction) {
        self.path = path
        self.pathPosition = pathPosition
        self.direction = direction
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try values.decode(SomeFinitePath.self, forKey: .path)
        self.pathPosition = try values.decode(Position.self, forKey: .pathPosition)
        self.direction = try values.decode(Direction.self, forKey: .direction)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(path, forKey: .path)
        try values.encode(pathPosition, forKey: .pathPosition)
        try values.encode(direction, forKey: .direction)
    }

}

class BaseVehicle: Codable {
    private var observers: [VehicleObserver] = []

    func add(observer: VehicleObserver) { observers.append(observer) }
    func remove(observer: VehicleObserver) { observers.removeAll { $0 === observer } }

    var objectPosition: ObjectPosition { vehiclePosition.objectPosition }
    var vehiclePosition: VehiclePosition {
        didSet {
            observers.forEach { $0.positionChanged(self as! Vehicle) }
        }
    }

    var center: Point { objectPosition.center }
    var orientation: CircleAngle { objectPosition.orientation }
    var direction: VehiclePosition.Direction { vehiclePosition.direction }

    var forward: Angle { objectPosition.forward }
    var left: Angle { objectPosition.left }
    var right: Angle { objectPosition.right }
    var backward: Angle { objectPosition.backward }

    init(vehiclePosition: VehiclePosition) {
        self.vehiclePosition = vehiclePosition
    }

    private enum CodingKeys: String, CodingKey {
        case position
    }

    required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.vehiclePosition = try values.decode(VehiclePosition.self, forKey: .position)
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(vehiclePosition, forKey: .position)
    }

}

protocol VehicleObserver: AnyObject {
    func positionChanged(_ vehicle: Vehicle)
}

extension VehicleObserver {
    func positionChanged(_ vehicle: Vehicle) {}
}

protocol Vehicle: Object {
    func add(observer: VehicleObserver)
    func remove(observer: VehicleObserver)

    var length: Distance { get }

    var vehiclePosition: VehiclePosition { get set }
}

enum EncodedVehicle: Codable {
    case container(ContainerWagon)

    var underlying: Vehicle {
        switch self {
        case .container(let vehicle): vehicle
        }
    }

    init(_ underlying: Vehicle) {
        if let vehicle = underlying as? ContainerWagon {
            self = .container(vehicle)
        } else {
            fatalError("Unexpected Vehicle type")
        }
    }

}
