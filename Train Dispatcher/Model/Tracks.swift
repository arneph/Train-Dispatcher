//
//  Tracks.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Foundation
import CoreGraphics

fileprivate let gauge = 1.435.m
fileprivate let railTopWidth = 0.05.m
fileprivate let railBottomWidth = 0.2.m
fileprivate let sleeperLength = gauge + 0.5.m
fileprivate let sleeperWidth = 0.25.m
fileprivate let minSleeperOffset = 0.6.m
let trackBedWidth = sleeperLength + 1.5.m

func isValid(trackPath path: SomeFinitePath) -> Bool {
    switch path {
    case .circular(let path):
        path.radius >= 100.0.m && path.length >= 5.0.m
    case .linear(let path):
        path.length >= 5.0.m
    case .compound(let path):
        path.length >= 5.0.m && path.components.allSatisfy{
            switch $0 {
            case .circular(let component):
                component.radius >= 100.0.m
            case .linear: true
            }
        }
    }
}

typealias PositionUpdateFunc = (Position) -> (Position)
typealias TrackAndPostionUpdateFunc = (Position) -> (Track, Position)

protocol TrackObserver: AnyObject {
    func pathChanged(forTrack track: Track, withPositionUpdate f: @escaping PositionUpdateFunc)
    
    func startConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?)
    func endConnectionChanged(forTrack track: Track, oldConnection: TrackConnection?)
    
    func replaced(track oldTrack: Track,
                  withTracks newTracks: [Track],
                  withUpdateFunc f: @escaping TrackAndPostionUpdateFunc)
    func removed(track oldTrack: Track)
}

extension TrackObserver {
    func pathChanged(forTrack: Track, withPositionUpdate f: @escaping PositionUpdateFunc) {}
    func startConnectionChanged(forTrack: Track, oldConnection: TrackConnection?) {}
    func endConnectionChanged(forTrack: Track, oldConnection: TrackConnection?) {}
    func replaced(track: Track,
                  withTracks: [Track],
                  withUpdateFunc: @escaping TrackAndPostionUpdateFunc) {}
    func removed(track: Track) {}
}

final class Track {
    private var observers: [TrackObserver] = []
    func add(observer: TrackObserver) { observers.append(observer) }
    func remove(observer: TrackObserver) { observers.removeAll{ $0 === observer } }
    
    private(set) var path: SomeFinitePath {
        didSet {
            leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
            rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
        }
    }
    var leftRail: SomeFinitePath
    var rightRail: SomeFinitePath
    
    var atomicPathTypeAtStart: AtomicPathType { path.forwardAtomicPathType(at: 0.0.m)! }
    var atomicPathTypeAtEnd: AtomicPathType { path.backwardAtomicPathType(at: path.length)! }
    
    fileprivate func set(path: SomeFinitePath, positionOffset xOffset: Distance) {
        self.path = path
        observers.forEach{ $0.pathChanged(forTrack: self, withPositionUpdate: { $0 + xOffset }) }
    }
    
    fileprivate(set) weak var startConnection: TrackConnection? = nil {
        didSet {
            observers.forEach{ $0.startConnectionChanged(forTrack: self, oldConnection: oldValue) }
        }
    }
    fileprivate(set) weak var endConnection: TrackConnection? = nil {
        didSet {
            observers.forEach{ $0.endConnectionChanged(forTrack: self, oldConnection: oldValue) }
        }
    }
    
    fileprivate func informObserversOfReplacement(
        by newTracks: [Track], withUpdateFunc f: @escaping TrackAndPostionUpdateFunc) {
        observers.forEach { $0.replaced(track: self, withTracks: newTracks, withUpdateFunc: f) }
    }
    
    fileprivate func informObserversOfRemoval() {
        observers.forEach { $0.removed(track: self) }
    }
    
    fileprivate init(path: SomeFinitePath) {
        self.path = path
        self.leftRail = path.offsetLeft(by: (gauge + railTopWidth) / 2.0)!
        self.rightRail = path.offsetRight(by: (gauge + railTopWidth) / 2.0)!
    }
    
    deinit {
        observers = []
    }
    
}

protocol TrackConnectionObserver: AnyObject {
    func added(track newTrack: Track,
               toConnection connection: TrackConnection,
               inDirection direction: TrackConnection.Direction)
    func replaced(track oldTrack: Track,
                  withTrack newTrack: Track,
                  inConnection connection: TrackConnection,
                  inDirection direction: TrackConnection.Direction)
    func removed(track oldTrack: Track, fromConnection connection: TrackConnection)
    
    func removed(connection oldConnection: TrackConnection)
}

extension TrackConnectionObserver {
    func added(track: Track,
               toConnection: TrackConnection,
               inDirection: TrackConnection.Direction) {}
    func replaced(track: Track,
                  withTrack: Track,
                  inConnection: TrackConnection,
                  inDirection: TrackConnection.Direction) {}
    func removed(track: Track, fromConnection: TrackConnection) {}
    func removed(connection: TrackConnection) {}
}

final class TrackConnection {
    enum Direction: Int {
        case a, b
        var opposite: Direction { Direction(rawValue: 1 - self.rawValue)! }
    }
    
    private var observers: [TrackConnectionObserver] = []
    func add(observer: TrackConnectionObserver) { observers.append(observer) }
    func remove(observer: TrackConnectionObserver) { observers.removeAll{ $0 === observer } }
    
    let point: Point
    let directionA: CircleAngle
    var directionB: CircleAngle { directionA.opposite }
    var pointAndDirectionA: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionA)
    }
    var pointAndDirectionB: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionB)
    }
    
    func orientation(inDirection direction: Direction) -> Angle {
        switch direction {
        case .a: directionA.asAngle
        case .b: directionB.asAngle
        }
    }
    
    func offsetLeft(by d: Distance, alongDirection direction: Direction = .a) -> Point {
        point + d ** (orientation(inDirection: direction) + 90.0.deg)
    }
    
    func offsetRight(by d: Distance, alongDirection direction: Direction = .a) -> Point {
        offsetLeft(by: -d, alongDirection: direction)
    }
    
    fileprivate(set) var directionATracks: [Track] = []
    fileprivate(set) var directionBTracks: [Track] = []
    var allTracks: [Track] {
        directionATracks + directionBTracks.filter{ bTrack in
            !directionATracks.contains{ aTrack in
                aTrack === bTrack
            }
        }
    }
    
    func tracks(inDirection direction: Direction) -> [Track] {
        switch direction {
        case .a: directionATracks
        case .b: directionBTracks
        }
    }
    
    var directionAStraightTrack: Track? {
        directionATracks.first{
            ($0.startConnection === self && $0.atomicPathTypeAtStart == .linear) ||
            ($0.endConnection === self && $0.atomicPathTypeAtEnd == .linear)
        }
    }
    var directionBStraightTrack: Track? {
        directionBTracks.first{
            ($0.startConnection === self && $0.atomicPathTypeAtStart == .linear) ||
            ($0.endConnection === self && $0.atomicPathTypeAtEnd == .linear)
        }
    }
    
    fileprivate func add(track: Track) {
        assert(track.path.start == point || track.path.end == point)
        if track.path.startPointAndOrientation == pointAndDirectionA ||
            track.path.endPointAndOrientation == pointAndDirectionB {
            directionATracks.append(track)
            observers.forEach{ $0.added(track: track, toConnection: self, inDirection: .a) }
        }
        if track.path.startPointAndOrientation == pointAndDirectionB || 
            track.path.endPointAndOrientation == pointAndDirectionA {
            directionBTracks.append(track)
            observers.forEach{ $0.added(track: track, toConnection: self, inDirection: .b) }
        }
    }
    
    fileprivate func replace(oldTrack: Track, newTrack: Track) {
        if directionATracks.contains(where: { $0 === oldTrack }) {
            directionATracks.removeAll{ $0 === oldTrack }
            directionATracks.append(newTrack)
            observers.forEach{ $0.replaced(track: oldTrack,
                                           withTrack: newTrack,
                                           inConnection: self,
                                           inDirection: .a) }
        }
        if directionBTracks.contains(where: { $0 === oldTrack }) {
            directionBTracks.removeAll{ $0 === oldTrack }
            directionBTracks.append(newTrack)
            observers.forEach{ $0.replaced(track: oldTrack,
                                           withTrack: newTrack,
                                           inConnection: self,
                                           inDirection: .b) }
        }
    }
    
    fileprivate func remove(track: Track) {
        directionATracks.removeAll{ $0 === track }
        directionBTracks.removeAll{ $0 === track }
        observers.forEach{ $0.removed(track: track, fromConnection: self) }
    }
    
    fileprivate init(point: Point, directionA: CircleAngle) {
        self.point = point
        self.directionA = directionA
    }
    
    deinit {
        observers = []
    }
    
}

protocol TrackMapObserver: AnyObject {
    func added(track: Track, toMap map: TrackMap)
    func replaced(track oldTrack: Track, withTracks newTracks: [Track], onMap map: TrackMap)
    func removed(track oldTrack: Track, fromMap map: TrackMap)
    
    func added(connection: TrackConnection, toMap map: TrackMap)
    func removed(connection oldConnection: TrackConnection, fromMap map: TrackMap)
    
    func trackChanged(_ track: Track, onMap map: TrackMap)
    func connectionChanged(_ connection: TrackConnection, onMap map: TrackMap)
}

extension TrackMapObserver {
    func added(track: Track, toMap: TrackMap) {}
    func replaced(track: Track, withTracks: [Track], onMap: TrackMap) {}
    func removed(track: Track, fromMap: TrackMap) {}
    
    func added(connection: TrackConnection, toMap: TrackMap) {}
    func removed(connection: TrackConnection, fromMap: TrackMap) {}
    
    func trackChanged(_: Track, onMap: TrackMap) {}
    func connectionChanged(_: TrackConnection, onMap: TrackMap) {}
}

final class TrackMap: Codable {
    private var observers: [TrackMapObserver] = []
    func add(observer: TrackMapObserver) { observers.append(observer) }
    func remove(observer: TrackMapObserver) { observers.removeAll{ $0 === observer } }
    
    private(set) var tracks: [Track] = []
    private(set) var connections: [TrackConnection] = []
    
    enum ConnectionOption {
        case none
        case toExistingTrack(Track, PathExtremity)
        case toExistingConnection(TrackConnection)
        case toNewConnection(Track, Position)
    }
    
    private enum NonMergingConnectionOption {
        case none
        case toExistingConnection(TrackConnection)
        case toNewConnection(Track, Position)
        
        init?(_ connectionOption: ConnectionOption) {
            switch connectionOption {
            case .none: self = .none
            case .toExistingTrack: return nil
            case .toExistingConnection(let connection):
                self = .toExistingConnection(connection)
            case .toNewConnection(let track, let x):
                self = .toNewConnection(track, x)
            }
        }
    }
    
    func addTrack(withPath path: SomeFinitePath,
                  startConnection: ConnectionOption,
                  endConnection: ConnectionOption) -> Track {
        switch (startConnection, endConnection) {
        case (.toExistingTrack(let trackA, let extremityA),
              .toExistingTrack(let trackB, let extremityB)):
            return merge(trackA: trackA, 
                         trackAExtremity: extremityA,
                         trackB: trackB, 
                         trackBExtremity: extremityB,
                         viaPath: path)
        case (.toExistingTrack(let existingTrack, let existingTrackExtremity), _):
            extend(track: existingTrack, 
                   at: existingTrackExtremity,
                   withPath: path,
                   at: .start)
            make(endConnection: NonMergingConnectionOption(endConnection)!,
                 ofTrack: existingTrack)
            return existingTrack
        case (_, .toExistingTrack(let existingTrack, let existingTrackExtremity)):
            extend(track: existingTrack, 
                   at: existingTrackExtremity,
                   withPath: path,
                   at: .end)
            make(startConnection: NonMergingConnectionOption(startConnection)!,
                 ofTrack: existingTrack)
            return existingTrack
        default:
            let newTrack = Track(path: path)
            make(startConnection: NonMergingConnectionOption(startConnection)!, 
                 ofTrack: newTrack)
            make(endConnection: NonMergingConnectionOption(endConnection)!, 
                 ofTrack: newTrack)
            tracks.append(newTrack)
            observers.forEach{ $0.added(track: newTrack, toMap: self) }
            return newTrack
        }
    }
    
    private func merge(trackA: Track,
                       trackAExtremity: PathExtremity,
                       trackB: Track,
                       trackBExtremity: PathExtremity,
                       viaPath middlePath: SomeFinitePath) -> Track {
        let (x, y, z) = (trackA.path.length, middlePath.length, trackB.path.length)
        let combinedPath: SomeFinitePath
        let trackAUpdate: PositionUpdateFunc
        let trackBUpdate: PositionUpdateFunc
        let startConnection: TrackConnection?
        let endConnection: TrackConnection?
        switch (trackAExtremity, trackBExtremity) {
        case (.start, .start):
            combinedPath = SomeFinitePath.combine([trackA.path.reverse, middlePath, trackB.path])!
            trackAUpdate = { x - $0 }
            trackBUpdate = { x + y + $0 }
            startConnection = trackA.endConnection
            endConnection = trackB.endConnection
        case (.start, .end):
            combinedPath = SomeFinitePath.combine([trackA.path.reverse, middlePath, trackB.path.reverse])!
            trackAUpdate = { x - $0 }
            trackBUpdate = { x + y + z - $0 }
            startConnection = trackA.endConnection
            endConnection = trackB.startConnection
        case (.end, .start):
            combinedPath = SomeFinitePath.combine([trackA.path, middlePath, trackB.path])!
            trackAUpdate = { $0 }
            trackBUpdate = { x + y + $0 }
            startConnection = trackA.startConnection
            endConnection = trackB.endConnection
        case (.end, .end):
            combinedPath = SomeFinitePath.combine([trackA.path, middlePath, trackB.path.reverse])!
            trackAUpdate = { $0 }
            trackBUpdate = { x + y + z - $0 }
            startConnection = trackA.startConnection
            endConnection = trackB.startConnection
        }
        let newTrack = Track(path: combinedPath)
        newTrack.startConnection = startConnection
        newTrack.endConnection = endConnection
        tracks.append(newTrack)
        tracks.removeAll{ $0 === trackA }
        tracks.removeAll{ $0 === trackB }
        if let startConnection = startConnection {
            startConnection.replace(oldTrack: trackA, newTrack: newTrack)
            observers.forEach{ $0.connectionChanged(startConnection, onMap: self) }
        }
        if let endConnection = endConnection {
            endConnection.replace(oldTrack: trackB, newTrack: newTrack)
            observers.forEach{ $0.connectionChanged(endConnection, onMap: self) }
        }
        trackA.informObserversOfReplacement(by: [newTrack], 
                                            withUpdateFunc: { (newTrack, trackAUpdate($0)) })
        trackB.informObserversOfReplacement(by: [newTrack],
                                            withUpdateFunc: { (newTrack, trackBUpdate($0)) })
        observers.forEach{ $0.replaced(track: trackA, withTracks: [newTrack], onMap: self) }
        observers.forEach{ $0.replaced(track: trackB, withTracks: [newTrack], onMap: self) }
        return newTrack
    }
    
    private func extend(track existingTrack: Track,
                        at existingTrackExtremity: PathExtremity,
                        withPath newPath: SomeFinitePath,
                        at newPathExtremity: PathExtremity) {
        let combinedPath: SomeFinitePath
        let xOffset: Distance
        switch (existingTrackExtremity, newPathExtremity) {
        case (.end, .start):
            combinedPath = SomeFinitePath.combine(existingTrack.path, newPath)!
            xOffset = 0.0.m
        case (.end, .end):
            combinedPath = SomeFinitePath.combine(existingTrack.path, newPath.reverse)!
            xOffset = 0.0.m
        case (.start, .start):
            combinedPath = SomeFinitePath.combine(newPath.reverse, existingTrack.path)!
            xOffset = newPath.length
        case (.start, .end):
            combinedPath = SomeFinitePath.combine(newPath, existingTrack.path)!
            xOffset = newPath.length
        }
        existingTrack.set(path: combinedPath, positionOffset: xOffset)
        observers.forEach{ $0.trackChanged(existingTrack, onMap: self) }
    }
    
    private func make(startConnection: NonMergingConnectionOption, ofTrack track: Track) {
        switch startConnection {
        case .none:
            break
        case .toExistingConnection(let connection):
            track.startConnection = connection
            connection.add(track: track)
            observers.forEach{ $0.connectionChanged(connection, onMap: self) }
        case .toNewConnection(let existingTrack, let x):
            let newConnection: TrackConnection
            if x == 0.0.m {
                newConnection = TrackConnection(point: existingTrack.path.start,
                                                directionA: existingTrack.path.startOrientation)
                newConnection.add(track: existingTrack)
                existingTrack.startConnection = newConnection
                connections.append(newConnection)
                observers.forEach{ $0.added(connection: newConnection, toMap: self) }
            } else if x == existingTrack.path.length {
                newConnection = TrackConnection(point: existingTrack.path.end,
                                                directionA: existingTrack.path.endOrientation)
                newConnection.add(track: existingTrack)
                existingTrack.endConnection = newConnection
                connections.append(newConnection)
                observers.forEach{ $0.added(connection: newConnection, toMap: self) }
            } else {
                newConnection = split(oldTrack: existingTrack, at: x)
            }
            track.startConnection = newConnection
            newConnection.add(track: track)
        }
    }
    
    private func make(endConnection: NonMergingConnectionOption, ofTrack track: Track) {
        switch endConnection {
        case .none:
            break
        case .toExistingConnection(let connection):
            track.endConnection = connection
            connection.add(track: track)
            observers.forEach{ $0.connectionChanged(connection, onMap: self) }
        case .toNewConnection(let existingTrack, let x):
            let newConnection: TrackConnection
            if x == 0.0.m {
                newConnection = TrackConnection(point: existingTrack.path.start,
                                                directionA: existingTrack.path.startOrientation)
                newConnection.add(track: existingTrack)
                existingTrack.startConnection = newConnection
                connections.append(newConnection)
                observers.forEach{ $0.added(connection: newConnection, toMap: self) }
            } else if x == existingTrack.path.length {
                newConnection = TrackConnection(point: existingTrack.path.end,
                                                directionA: existingTrack.path.endOrientation)
                newConnection.add(track: existingTrack)
                existingTrack.endConnection = newConnection
                connections.append(newConnection)
                observers.forEach{ $0.added(connection: newConnection, toMap: self) }
            } else {
                newConnection = split(oldTrack: existingTrack, at: x)
            }
            track.endConnection = newConnection
            newConnection.add(track: track)
        }
    }
    
    private func split(oldTrack: Track, at x: Position) -> TrackConnection {
        assert(tracks.contains{ $0 === oldTrack })
        assert(0.0.m < x && x < oldTrack.path.length)
        let point = oldTrack.path.point(at: x)!
        let directionA = oldTrack.path.orientation(at: x)!
        let (splitPathA, splitPathB) = oldTrack.path.split(at: x)!
        let splitTrackA = Track(path: splitPathA)
        let splitTrackB = Track(path: splitPathB)
        if let connectionA = oldTrack.startConnection {
            splitTrackA.startConnection = connectionA
            connectionA.replace(oldTrack: oldTrack, newTrack: splitTrackA)
        }
        if let connectionB = oldTrack.endConnection {
            splitTrackB.endConnection = connectionB
            connectionB.replace(oldTrack: oldTrack, newTrack: splitTrackB)
        }
        let newConnection = TrackConnection(point: point, directionA: directionA)
        splitTrackA.endConnection = newConnection
        splitTrackB.startConnection = newConnection
        newConnection.add(track: splitTrackA)
        newConnection.add(track: splitTrackB)
        tracks.removeAll{ $0 === oldTrack }
        tracks.append(splitTrackA)
        tracks.append(splitTrackB)
        connections.append(newConnection)
        oldTrack.informObserversOfReplacement(by: [splitTrackA, splitTrackB],
                                              withUpdateFunc: { (y) in
            (y < x) ? (splitTrackA, y) : (splitTrackB, y - x)
        })
        observers.forEach{ $0.replaced(track: oldTrack,
                                       withTracks: [splitTrackA, splitTrackB],
                                       onMap: self) }
        observers.forEach{ $0.added(connection: newConnection, toMap: self) }
        return newConnection
    }
    
    func remove(oldTrack: Track) {
        tracks.removeAll{ $0 === oldTrack }
        if let startConnection = oldTrack.startConnection {
            startConnection.remove(track: oldTrack)
            mergeIfNecessary(oldConnection: startConnection)
        }
        if let endConnection = oldTrack.endConnection {
            endConnection.remove(track: oldTrack)
            mergeIfNecessary(oldConnection: endConnection)
        }
        oldTrack.informObserversOfRemoval()
        observers.forEach{ $0.removed(track: oldTrack, fromMap: self) }
    }
    
    private func mergeIfNecessary(oldConnection: TrackConnection) {
        guard oldConnection.directionATracks.count == 1,
              oldConnection.directionBTracks.count == 1 else {
            return
        }
        let oldTrackA = oldConnection.directionATracks.first!
        let oldPathA: SomeFinitePath
        let startConnection: TrackConnection?
        if oldTrackA.endConnection === oldConnection {
            oldPathA = oldTrackA.path
            startConnection = oldTrackA.startConnection
        } else {
            oldPathA = oldTrackA.path.reverse
            startConnection = oldTrackA.endConnection
        }
        let oldTrackB = oldConnection.directionBTracks.first!
        let oldPathB: SomeFinitePath
        let endConnection: TrackConnection?
        if oldTrackB.startConnection === oldConnection {
            oldPathB = oldTrackB.path
            endConnection = oldTrackB.endConnection
        } else {
            oldPathB = oldTrackB.path.reverse
            endConnection = oldTrackB.startConnection
        }
        let combinedPath = SomeFinitePath.combine(oldPathA, oldPathB)!
        let combinedTrack = Track(path: combinedPath)
        combinedTrack.startConnection = startConnection
        combinedTrack.endConnection = endConnection
        tracks.removeAll{ $0 === oldTrackA }
        tracks.removeAll{ $0 === oldTrackB }
        tracks.append(combinedTrack)
        connections.removeAll{ $0 === oldConnection }
    }
    
    private enum CodingKeys: String, CodingKey {
        case tracks, connections
    }
    private struct EncodedTrack: Codable {
        let path: SomeFinitePath
        let startConnectionIndex: Int?
        let endConnectionIndex: Int?
    }
    private struct EncodedConnection: Codable {
        let point: Point
        let orientation: CircleAngle
        let directionATrackIndices: [Int]
        let directionBTrackIndices: [Int]
    }
    
    init() {}
    
    deinit {
        observers = []
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let encodedTracks = try values.decode([EncodedTrack].self, forKey: .tracks)
        let encodedConnections = try values.decode([EncodedConnection].self, forKey: .connections)
        self.tracks = encodedTracks.map{ (encodedTrack) in
            Track(path: encodedTrack.path)
        }
        self.connections = encodedConnections.map{ (encodedConnections) in
            TrackConnection(point: encodedConnections.point,
                            directionA: encodedConnections.orientation)
        }
        zip(self.tracks, encodedTracks).forEach{ (track, encodedTrack) in
            if let startIndex = encodedTrack.startConnectionIndex {
                track.startConnection = self.connections[startIndex]
            }
            if let endIndex = encodedTrack.endConnectionIndex {
                track.endConnection = self.connections[endIndex]
            }
        }
        zip(self.connections, encodedConnections).forEach{ (connection, encodedConnection) in
            connection.directionATracks = encodedConnection.directionATrackIndices.map{ (aIndex) in
                self.tracks[aIndex]
            }
            connection.directionBTracks = encodedConnection.directionBTrackIndices.map{ (bIndex) in
                self.tracks[bIndex]
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        let encodedTracks = tracks.map{ (track) in
            let startIndex = connections.firstIndex{ $0 === track.startConnection }
            let endIndex = connections.firstIndex{ $0 === track.endConnection }
            return EncodedTrack(path: track.path,
                                startConnectionIndex: startIndex,
                                endConnectionIndex: endIndex)
        }
        let encodedConnections = connections.map{ (connection) in
            let aIndices = connection.directionATracks.map{ (track) in
                tracks.firstIndex{ $0 === track }!
            }
            let bIndices = connection.directionBTracks.map{ (track) in
                tracks.firstIndex{ $0 === track }!
            }
            return EncodedConnection(point: connection.point,
                                     orientation: connection.directionA,
                                     directionATrackIndices: aIndices,
                                     directionBTrackIndices: bIndices)
        }
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(encodedTracks, forKey: .tracks)
        try values.encode(encodedConnections, forKey: .connections)
    }
    
}

extension Array: Drawable where Element: Track {
    
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext) {
        cgContext.saveGState()
        if viewContext.mapScale < 5.0 {
            for track in self {
                drawWithLowDetail(track, cgContext, viewContext)
            }
        } else {
            for drawFunc in [drawBedFoundations, drawBed, drawSleepers, drawRails] {
                for track in self {
                    drawFunc(track, cgContext, viewContext)
                }
            }
        }
        cgContext.restoreGState()
    }
    
}

fileprivate func drawWithLowDetail(_ track: Track,
                               _ cgContext: CGContext,
                               _ viewContext: ViewContext) {
    switch viewContext.style {
    case .light:
        cgContext.setStrokeColor(CGColor.init(gray: 0.35, alpha: 1.0))
    case .dark:
        cgContext.setStrokeColor(CGColor.init(gray: 0.7, alpha: 1.0))
    }
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperLength))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

fileprivate func drawBedFoundations(_ track: Track,
                                    _ cgContext: CGContext,
                                    _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.7, blue: 0.65, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(trackBedWidth))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

fileprivate func drawBed(_ track: Track,
                         _ cgContext: CGContext,
                         _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperLength + 0.6.m))
    trace(path: track.path, cgContext, viewContext)
    cgContext.drawPath(using: .stroke)
}

fileprivate func drawSleepers(_ track: Track,
                              _ cgContext: CGContext,
                              _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperWidth))
    let startS = sleeperWidth
    let endS = track.path.length - sleeperWidth
    let deltaS = endS - startS
    let stepS = deltaS / floor(deltaS / minSleeperOffset)
    for s in stride(from: startS.withoutUnit, through: endS.withoutUnit, by: stepS.withoutUnit) {
        let center = track.path.point(at: Distance(s))!
        let orientation = track.path.orientation(at: Distance(s))!
        let left = center + 0.5 * sleeperLength ** (orientation + 90.0.deg)
        let right = center + 0.5 * sleeperLength ** (orientation - 90.0.deg)
        cgContext.move(to: viewContext.toViewPoint(left))
        cgContext.addLine(to: viewContext.toViewPoint(right))
        cgContext.drawPath(using: .stroke)
    }
}

fileprivate func drawRails(_ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.setStrokeColor(CGColor.init(gray: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(railBottomWidth))
    for rail in [track.leftRail, track.rightRail] {
        trace(path: rail, cgContext, viewContext)
        cgContext.drawPath(using: .stroke)
    }
}
