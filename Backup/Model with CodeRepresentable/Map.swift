//
//  Map.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Foundation

struct ClosestTrackPointInfo {
    let distance: Distance
    let track: Track
    var trackPath: SomeFinitePath { track.path }
    let trackPathPosition: Position

    let atomicPath: AtomicFinitePath
    let atomicPathPosition: Position
    
    let point: Point
    let orientation: Angle
    var pointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: point, orientation: orientation)
    }
    
    var isTrackStart: Bool { trackPathPosition == 0.0.m }
    var isTrackEnd: Bool { trackPathPosition == track.path.length }
    
    init(distance: Distance, track: Track, trackPathPosition: Position) {
        self.distance = distance
        self.track = track
        self.trackPathPosition = trackPathPosition
        
        switch self.track.path {
        case .linear(let path):
            self.atomicPath = .linear(path)
            self.atomicPathPosition = self.trackPathPosition
        case .circular(let path):
            self.atomicPath = .circular(path)
            self.atomicPathPosition = self.trackPathPosition
        case .compound(let path):
            (self.atomicPath, self.atomicPathPosition) = path.component(at: self.trackPathPosition)!
        }
        self.point = atomicPath.point(at: atomicPathPosition)!
        self.orientation = atomicPath.orientation(at: atomicPathPosition)!
    }
}

final class Map: Codable, CodeRepresentable {
    var tracks: [Track] = [Track(path: .compound(CompoundPath(components: [
            .linear(LinearPath(start: Point(x: -50.0.m, y: 0.0.m),
                               end: Point(x: 0.0.m, y: 0.0.m))!),
            .circular(CircularPath(center: Point(x: 0.0.m, y: 120.0.m), radius: 120.0.m,
                                   startAngle: 270.0.deg, endAngle: 360.0.deg, clockwise: false)!),
        ])!))]
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
                                                           startAngle: 270.0.deg,
                                                           endAngle: 360.0.deg,
                                                           clockwise: false)!,
                                        pathPosition: 30.0.m))]
    var containers: [Container] = [Container(center: Point(x: 0.0.m, y: 10.0.m),
                                             orientation: 60.0.deg)]
    
    func closestPointOnTrack(from point: Point) -> ClosestTrackPointInfo? {
        var closest: ClosestTrackPointInfo?
        for track in tracks {
            let candidate = track.path.closestPointOnPath(from: point)
            if closest?.distance ?? Float64.infinity.m <= candidate.distance {
                continue
            }
            closest = ClosestTrackPointInfo(distance: candidate.distance,
                                            track: track,
                                            trackPathPosition: candidate.x)
        }
        return closest
    }
    
    init() {}
    
    init(tracks: [Track], vehicles: [Vehicle], containers: [Container]) {
        self.tracks = tracks
        self.vehicles = vehicles
        self.containers = containers
    }
    
    private enum CodingKeys: String, CodingKey {
        case tracks, vehicles, containers
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.tracks = try values.decode([Track].self, forKey: .tracks)
        self.vehicles = try values.decode([EncodedVehicle].self,
                                          forKey: .vehicles).map{ $0.underlying }
        self.containers = try values.decode([Container].self, forKey: .containers)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(tracks, forKey: .tracks)
        try values.encode(vehicles.map{ EncodedVehicle($0) }, forKey: .vehicles)
        try values.encode(containers, forKey: .containers)
    }
    
    private static let name = "Map"
    private static let labels = [tracksLabel, vehiclesLabel, containersLabel]
    private static let tracksLabel = "tracks"
    private static let vehiclesLabel = "vehicles"
    private static let containersLabel = "containers"
    
    static func parseCode(with scanner: Scanner) -> Map? {
        parseStruct(name: name, scanner: scanner) {
            guard let (tracks, containers, vehicles): ([Track], [Container], [EncodedVehicle]) =
                    parseArguments(labels: labels, scanner: scanner) else {
                return nil
            }
            return Map(tracks: tracks,
                       vehicles: vehicles.map{ $0.underlying },
                       containers: containers)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: Map.name, printer: printer) {
            print(labelsAndArguments: [(Map.tracksLabel, tracks),
                                       (Map.vehiclesLabel, vehicles.map{ EncodedVehicle($0) }),
                                       (Map.containersLabel, containers)],
                  printer: printer)
        }
    }
    
}
