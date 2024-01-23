//
//  Vehicle.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Foundation

struct VehiclePosition: Codable {
    let path: any FinitePath
    let pathPosition: Position
    
    var center: Point { path.point(at: pathPosition)! }
    var orientation: Angle { path.orientation(at: pathPosition)! }
    var objectPosition: ObjectPosition {
        ObjectPosition(center: center, orientation: orientation)
    }
    
    var forward: Angle { orientation }
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
        
    private static let pathLabel = "path"
    private static let pathPositionLabel = "pathPosition"
    
    static func parseLabelsAndArgs(with scanner: Scanner) -> VehiclePosition? {
        guard let (path, pathPosition): (SomeFinitePath, Position) =
                parseArguments(labels: [pathLabel, pathPositionLabel], scanner: scanner) else {
            return nil
        }
        return VehiclePosition(path: path, pathPosition: pathPosition)
    }
    
    func printLabelsAndArgs(with printer: Printer) {
        print(labelsAndArguments: 
                [(BaseVehicle.pathLabel, vehiclePosition.path),
                 (BaseVehicle.pathPositionLabel, vehiclePosition.pathPosition)],
              printer: printer)
    }
    
    var center: Point { objectPosition.center }
    var orientation: Angle { objectPosition.orientation }
    
    var forward: Angle { objectPosition.forward }
    var left: Angle { objectPosition.left }
    var right: Angle { objectPosition.right }
    var backward: Angle { objectPosition.backward }
    
}

protocol Vehicle: Object {
    static var length: Distance { get }
    
    var vehiclePosition: VehiclePosition { get }
}

enum EncodedVehicle: Codable, CodeRepresentable {
    case container(ContainerWagon)
    
    var underlying: Vehicle {
        switch self {
        case .container(let vehicle): return vehicle
        }
    }
    
    init(_ underlying: Vehicle) {
        if let vehicle = underlying as? ContainerWagon {
            self = .container(vehicle)
        } else {
            fatalError("Unexpected Vehicle type")
        }
    }
    
    static func parseCode(with scanner: Scanner) -> EncodedVehicle? {
        switch scanner.peek() {
        case .identifier(ContainerWagon.name):
            guard let vehicle = ContainerWagon.parseCode(with: scanner) else {
                return nil
            }
            return EncodedVehicle(vehicle)
        default:
            return nil
        }
    }
    
    func printCode(with printer: Printer) {
        underlying.printCode(with: printer)
    }
    
}
