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

public protocol MapObserver: AnyObject {
    func timeSimulationChanged(_ map: Map)
}

public final class Map: Codable {
    private var observers: [MapObserver] = []

    public func add(observer: MapObserver) {
        observers.append(observer)
    }

    public func remove(observer: MapObserver) {
        observers.removeAll { $0 === observer }
    }

    public let groundMap: GroundMap
    public let trackMap: TrackMap
    public var trains: [Train]
    public var containers: [Container]

    public enum TimeSimulation: Float64, Codable {
        case paused = 0.0
        case atPoint5x = 0.5
        case regular = 1.0
        case at2x = 2.0
        case at5x = 5.0
    }
    public var timeSimulation: TimeSimulation = .regular {
        didSet {
            observers.forEach { $0.timeSimulationChanged(self) }
        }
    }

    private var lastTick: Date = Date.now
    private var timer: Timer? = nil

    private func startTimer() {
        self.lastTick = Date.now
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            let currentTick = Date.now
            let delta =
                Duration(self.lastTick.distance(to: currentTick)) * self.timeSimulation.rawValue
            for train in self.trains {
                train.tick(delta)
            }
            self.lastTick = currentTick
        }
    }

    public init() {
        self.groundMap = GroundMap()
        self.trackMap = TrackMap()
        self.trains = []
        self.containers = []
        startTimer()
    }

    private enum CodingKeys: String, CodingKey {
        case ground, tracks, trains, containers, timeSimulation
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.groundMap = try values.decode(GroundMap.self, forKey: .ground)
        self.trackMap = try values.decode(TrackMap.self, forKey: .tracks)
        self.trains = try values.decode([Train].self, forKey: .trains)
        self.containers = try values.decode([Container].self, forKey: .containers)
        self.timeSimulation = try values.decode(TimeSimulation.self, forKey: .timeSimulation)
        startTimer()
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(groundMap, forKey: .ground)
        try values.encode(trackMap, forKey: .tracks)
        try values.encode(trains, forKey: .trains)
        try values.encode(containers, forKey: .containers)
        try values.encode(timeSimulation, forKey: .timeSimulation)
    }

}
