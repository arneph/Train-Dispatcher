//
//  Train.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 7/27/24.
//

import Base
import CoreGraphics
import Foundation

protocol TrainObserver: AnyObject {
    func positionChanged(_ train: Train)
}

extension TrainObserver {
    func positionChanged(_ train: Train) {}
}

class Train: Codable, Drawable {
    private var observers: [TrainObserver] = []

    func add(observer: TrainObserver) { observers.append(observer) }
    func remove(observer: TrainObserver) { observers.removeAll { $0 === observer } }

    private(set) var vehicles: [any Vehicle]

    var position: VehiclePosition { vehicles.first!.vehiclePosition }
    var path: any FinitePath { position.path }
    var pathPosition: Position { position.pathPosition }

    func set(position: VehiclePosition) {
        var l = 0.0.m
        for i in vehicles.indices {
            var vehicle = vehicles[i]
            if i > 0 {
                l -= vehicles[i - 1].length / 2.0
                l -= vehicle.length / 2.0
            }
            vehicle.vehiclePosition = VehiclePosition(
                path: position.path,
                pathPosition: position.pathPosition + l,
                direction: vehicle.vehiclePosition.direction)
        }
        observers.forEach { $0.positionChanged(self) }
    }

    func draw(_ cgContext: CGContext, _ viewContext: any ViewContext, _ dirtyRect: Rect) {
        vehicles.forEach { $0.draw(cgContext, viewContext, dirtyRect) }
    }

    init(vehicles: [any Vehicle]) {
        self.vehicles = vehicles
    }

    private enum CodingKeys: String, CodingKey {
        case vehicles
    }

    required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.vehicles =
            (try values.decode(
                [EncodedVehicle].self,
                forKey: .vehicles)).map { $0.underlying }
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(vehicles.map { EncodedVehicle($0) }, forKey: .vehicles)
    }

}
