//
//  Map.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Base
import Foundation
import Tracks

final class Map: Codable {
    let trackMap: TrackMap
    var vehicles: [Vehicle] = []
    var containers: [Container] = []

    init() {
        self.trackMap = TrackMap()
    }

    private enum CodingKeys: String, CodingKey {
        case tracks, vehicles, containers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.trackMap = try values.decode(TrackMap.self, forKey: .tracks)
        self.vehicles = try values.decode(
            [EncodedVehicle].self, forKey: .vehicles
        ).map { $0.underlying }
        self.containers = try values.decode([Container].self, forKey: .containers)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(trackMap, forKey: .tracks)
        try values.encode(vehicles.map { EncodedVehicle($0) }, forKey: .vehicles)
        try values.encode(containers, forKey: .containers)
    }

}
