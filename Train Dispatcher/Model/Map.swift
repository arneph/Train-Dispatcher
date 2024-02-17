//
//  Map.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Foundation

final class Map: Codable {
    let trackMap: TrackMap
    var vehicles: [Vehicle] = [
        ContainerWagon(vehiclePosition:
                        VehiclePosition(path: LinearPath(start: Point(x: -50.0.m, y: 0.0.m),
                                                         end: Point(x: 0.0.m, y: 0.0.m))!,
                                        pathPosition: 10.0.m)),
        ContainerWagon(vehiclePosition:
                        VehiclePosition(path: LinearPath(start: Point(x: -50.0.m, y: 0.0.m),
                                                         end: Point(x: 0.0.m, y: 0.0.m))!,
                                        pathPosition: 10.0.m + ContainerWagon.length)),
        ContainerWagon(vehiclePosition:
                        VehiclePosition(path: LinearPath(start: Point(x: -50.0.m, y: 0.0.m),
                                                         end: Point(x: 0.0.m, y: 0.0.m))!,
                                        pathPosition: 10.0.m + ContainerWagon.length * 2.0)),
        ContainerWagon(vehiclePosition:
                        VehiclePosition(path: CircularPath(center: Point(x: 0.0.m, y: 120.0.m),
                                                           radius: 120.0.m,
                                                           startAngle: CircleAngle(-90.0.deg),
                                                           endAngle: CircleAngle(0.0.deg),
                                                           direction: .positive)!,
                                        pathPosition: 30.0.m))]
    var containers: [Container] = [Container(center: Point(x: 0.0.m, y: 10.0.m),
                                             orientation: CircleAngle(60.0.deg))]
    
    init() {
        self.trackMap = TrackMap()
        let _ = self.trackMap.addTrack(withPath: .compound(CompoundPath(components: [
            .linear(LinearPath(start: Point(x: -50.0.m, y: 0.0.m),
                               end: Point(x: 0.0.m, y: 0.0.m))!),
            .circular(CircularPath(center: Point(x: 0.0.m, y: 120.0.m), 
                                   radius: 120.0.m,
                                   startAngle: CircleAngle(-90.0.deg),
                                   endAngle: CircleAngle(0.0.deg),
                                   direction: .positive)!),
        ])!),
                                       startConnection: .none,
                                       endConnection: .none)
    }
    
    private enum CodingKeys: String, CodingKey {
        case tracks, vehicles, containers
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.trackMap = try values.decode(TrackMap.self, forKey: .tracks)
        self.vehicles = try values.decode([EncodedVehicle].self,
                                          forKey: .vehicles).map{ $0.underlying }
        self.containers = try values.decode([Container].self, forKey: .containers)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(trackMap, forKey: .tracks)
        try values.encode(vehicles.map{ EncodedVehicle($0) }, forKey: .vehicles)
        try values.encode(containers, forKey: .containers)
    }
    
}
