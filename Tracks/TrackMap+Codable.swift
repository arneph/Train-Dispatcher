//
//  TrackMap+Codable.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/9/24.
//

import Base
import Foundation

extension TrackMap: Codable {
    private enum CodingKeys: String, CodingKey {
        case tracks, connections
    }

    private struct EncodedTrack: Codable {
        let id: ID<Track>
        let path: SomeFinitePath
        let startConnection: ID<TrackConnection>?
        let endConnection: ID<TrackConnection>?
    }

    private struct EncodedConnection: Codable {
        struct StateChange: Codable {
            let previous: ID<Track>
            let next: ID<Track>
            let progress: Float64
        }
        enum State: Codable {
            case fixed(ID<Track>)
            case changing(StateChange)
        }

        let id: ID<TrackConnection>
        let point: Point
        let orientation: CircleAngle
        let directionATracks: [ID<Track>]
        let directionBTracks: [ID<Track>]
        let directionAState: State?
        let directionBState: State?
    }

    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let encodedTracks = try values.decode([EncodedTrack].self, forKey: .tracks)
        let encodedConnections = try values.decode([EncodedConnection].self, forKey: .connections)
        let trackSet = IDSet<Track>(
            encodedTracks.map { (encodedTrack) in
                Track(id: encodedTrack.id, path: encodedTrack.path)
            })
        let connectionSet = IDSet<TrackConnection>(
            encodedConnections.map { (encodedConnection) in
                TrackConnection(
                    id: encodedConnection.id, point: encodedConnection.point,
                    directionA: encodedConnection.orientation)
            })
        zip(trackSet.elements, encodedTracks).forEach { (track, encodedTrack) in
            if let startID = encodedTrack.startConnection {
                track.startConnection = connectionSet[startID]
            }
            if let endID = encodedTrack.endConnection {
                track.endConnection = connectionSet[endID]
            }
        }
        zip(connectionSet.elements, encodedConnections).forEach { (connection, encodedConnection) in
            connection.directionATracks = encodedConnection.directionATracks.map { (aID) in
                trackSet[aID]!
            }
            connection.directionBTracks = encodedConnection.directionBTracks.map { (bID) in
                trackSet[bID]!
            }
            connection.directionAState = encodedConnection.directionAState.map {
                switch $0 {
                case .fixed(let trackID):
                    .fixed(trackSet[trackID]!)
                case .changing(let change):
                    .changing(
                        TrackConnection.StateChange(
                            previous: trackSet[change.previous]!,
                            next: trackSet[change.next]!,
                            progress: change.progress))
                }
            }
            connection.directionBState = encodedConnection.directionBState.map {
                switch $0 {
                case .fixed(let trackID):
                    .fixed(trackSet[trackID]!)
                case .changing(let change):
                    .changing(
                        TrackConnection.StateChange(
                            previous: trackSet[change.previous]!,
                            next: trackSet[change.next]!,
                            progress: change.progress))
                }
            }
        }
        self.init(tracks: trackSet, connections: connectionSet)
    }

    public func encode(to encoder: Encoder) throws {
        let encodedTracks = tracks.map { (track) in
            EncodedTrack(
                id: track.id, path: track.path, startConnection: track.startConnection?.id,
                endConnection: track.endConnection?.id)
        }
        let encodedConnections = connections.map { (connection) in
            EncodedConnection(
                id: connection.id, point: connection.point, orientation: connection.directionA,
                directionATracks: connection.directionATracks.map { $0.id },
                directionBTracks: connection.directionBTracks.map { $0.id },
                directionAState: connection.directionAState.map {
                    switch $0 {
                    case .fixed(let track):
                        .fixed(track.id)
                    case .changing(let change):
                        .changing(
                            EncodedConnection.StateChange(
                                previous: change.previous.id,
                                next: change.next.id,
                                progress: change.progress))
                    }
                },
                directionBState: connection.directionBState.map {
                    switch $0 {
                    case .fixed(let track):
                        .fixed(track.id)
                    case .changing(let change):
                        .changing(
                            EncodedConnection.StateChange(
                                previous: change.previous.id,
                                next: change.next.id,
                                progress: change.progress))
                    }
                })
        }
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(encodedTracks, forKey: .tracks)
        try values.encode(encodedConnections, forKey: .connections)
    }

}
