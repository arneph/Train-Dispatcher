//
//  Map.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Base
import Foundation
import Ground
import Tracks
import Trains

final class Map: Codable {
    let groundMap: GroundMap
    let trackMap: TrackMap
    var trains: [Train] = []
    var containers: [Container] = []

    var lastTick: Date = Date.now
    var timer: Timer? = nil

    init() {
        self.groundMap = GroundMap()
        self.trackMap = TrackMap()
        self.lastTick = Date.now
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            let currentTick = Date.now
            let delta = Duration(self.lastTick.distance(to: currentTick))
            for train in self.trains {
                train.tick(delta)
            }
            self.lastTick = currentTick
        }
    }

    private enum CodingKeys: String, CodingKey {
        case ground, tracks, trains, containers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.groundMap = try values.decode(GroundMap.self, forKey: .ground)
        self.trackMap = try values.decode(TrackMap.self, forKey: .tracks)
        self.trains = try values.decode([Train].self, forKey: .trains)
        self.containers = try values.decode([Container].self, forKey: .containers)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(groundMap, forKey: .ground)
        try values.encode(trackMap, forKey: .tracks)
        try values.encode(trains, forKey: .trains)
        try values.encode(containers, forKey: .containers)
    }

}
