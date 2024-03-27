//
//  Vehicle.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Base
import Foundation

struct VehiclePosition: Codable {
    let path: any FinitePath
    let pathPosition: Position

    var center: Point { path.point(at: pathPosition)! }
    var orientation: CircleAngle { path.orientation(at: pathPosition)! }
    var objectPosition: ObjectPosition {
        ObjectPosition(center: center, orientation: orientation)
    }

    var forward: CircleAngle { orientation }
    var left: Angle { orientation + 90.0.deg }
    var right: Angle { orientation - 90.0.deg }
    var backward: Angle { orientation + 180.deg }

    private enum CodingKeys: String, CodingKey {
        case path, pathPosition
    }

    init(path: any FinitePath, pathPosition: Position) {
        self.path = path
        self.pathPosition = pathPosition
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try values.decode(SomeFinitePath.self, forKey: .path)
        self.pathPosition = try values.decode(Position.self, forKey: .pathPosition)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(path, forKey: .path)
        try values.encode(pathPosition, forKey: .pathPosition)
    }

}

class BaseVehicle: Codable {
    var objectPosition: ObjectPosition { vehiclePosition.objectPosition }
    var vehiclePosition: VehiclePosition

    init(vehiclePosition: VehiclePosition) {
        self.vehiclePosition = vehiclePosition
    }

    var center: Point { objectPosition.center }
    var orientation: CircleAngle { objectPosition.orientation }

    var forward: Angle { objectPosition.forward }
    var left: Angle { objectPosition.left }
    var right: Angle { objectPosition.right }
    var backward: Angle { objectPosition.backward }

}

protocol Vehicle: Object {
    static var length: Distance { get }

    var vehiclePosition: VehiclePosition { get }
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
