//
//  Cursor.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 10/26/24.
//

import Base
import CoreGraphics
import Foundation
import Tracks
import Trains

class Cursor: Tool {
    var type: ToolType { .cursor }

    private weak var owner: ToolOwner?
    private var map: Map? { owner?.map }
    private var trackMap: TrackMap? { owner?.map?.trackMap }
    private var trains: [Train] { owner?.map?.trains ?? [] }
    private var changeManager: ChangeManager? { owner?.changeManager }

    required init(owner: ToolOwner) {
        self.owner = owner
    }

    func mouseEntered(point: Point) {

    }

    func mouseMoved(point: Point) {

    }

    func mouseExited() {

    }

    func mouseDown(point: Point) {
        for train in trains {
            for vehicle in train.vehicles {
                let l1 = Line(base: vehicle.center, orientation: vehicle.forward)
                let l2 = Line(base: vehicle.center, orientation: vehicle.left)
                let d1 = distance(point, l1.closestPoint(to: point))
                let d2 = distance(point, l2.closestPoint(to: point))
                if d1 <= 0.5 * vehicle.width && d2 <= 0.5 * vehicle.length {
                    owner?.selectTrain(train: train)
                    return
                }
            }
        }
        for signal in trackMap?.signals ?? [] {
            guard distance(point, signal.point) <= 5.0.m else { continue }
            let nextState: Signal.BaseState =
                switch signal.activeState {
                case .blocked: .go
                case .go: .blocked
                }
            signal.changeState(to: nextState)
            return
        }
        var closestSwitch: (TrackConnection, TrackConnection.Direction)? = nil
        var minDistance: Distance? = nil
        for connection in trackMap?.connections ?? [] {
            guard distance(point, connection.point) <= 50.0.m else { continue }
            for direction in [TrackConnection.Direction.a, .b] {
                guard connection.hasSwitch(inDirection: direction) else { continue }
                for track in connection.tracks(inDirection: direction) {
                    let path = connection.switchPath(for: track)
                    let d = path.closestPointOnPath(from: point).distance
                    if let minDistance = minDistance, minDistance < d {
                        continue
                    }
                    closestSwitch = (connection, direction)
                    minDistance = d
                }
            }
        }
        if let (connection, direction) = closestSwitch {
            let tracks = connection.tracks(inDirection: direction)
            guard let currentTrack = connection.activeTrack(inDirection: direction) else {
                return
            }
            let currentIndex = tracks.firstIndex { $0 === currentTrack }!
            let nextIndex = (currentIndex + 1) % tracks.count
            let nextTrack = tracks[nextIndex]
            connection.switchDirection(direction, to: nextTrack)
        }
    }

    func mouseDragged(point: Point) {}

    func mouseUp(point: Point) {}

    func draw(layer: ToolDrawingLayer, ctx: DrawContext) {}

}
