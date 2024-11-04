//
//  SignalPlacer.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/3/24.
//

import Base
import CoreGraphics
import Foundation
import Tracks

class SignalPlacer: Tool {
    var type: ToolType {
        assertionFailure("SignalPlacer.type was called.")
        exit(1)
    }

    var signalKind: Signal.Kind {
        assertionFailure("SignalPlacer.signalKind was called.")
        exit(1)
    }

    private weak var owner: ToolOwner?
    private var map: Map? { owner?.map }
    private var trackMap: TrackMap? { owner?.map?.trackMap }
    private var changeManager: ChangeManager? { owner?.changeManager }

    private struct SignalProposal {
        let position: PointAndOrientation
    }

    private enum State {
        case none
        case hovering(SignalProposal)
    }

    private var state: State = .none {
        didSet {
            owner?.stateChanged(tool: self)
        }
    }

    required init(owner: any ToolOwner) {
        self.owner = owner
    }

    func mouseEntered(point: Point) {
        state =
            if let proposal = proposal(for: point) {
                .hovering(proposal)
            } else {
                .none
            }
    }

    func mouseMoved(point: Point) {
        state =
            if let proposal = proposal(for: point) {
                .hovering(proposal)
            } else {
                .none
            }
    }

    func mouseExited() {
        state = .none
    }

    func mouseDown(point: Point) {
        switch state {
        case .none:
            break
        case .hovering(let proposal):
            guard let trackMap = trackMap else { break }
            let (_, undoHandler) = trackMap.addSignal(kind: signalKind, at: proposal.position)
            changeManager?.add(change: undoHandler, withName: "Add Signal")
        }
        state = .none
    }

    func mouseDragged(point: Point) {
        state = .none
    }

    func mouseUp(point: Point) {
        state = .none
    }

    func draw(layer: ToolDrawingLayer, ctx: DrawContext) {
        switch state {
        case .none:
            break
        case .hovering(let proposal):
            switch signalKind {
            case .section:
                drawProposedSectionSignal(at: proposal.position, ctx: ctx)
            case .main:
                drawProposedMainSignal(at: proposal.position, ctx: ctx)
            }
        }
    }

    private func proposal(for point: Point) -> SignalProposal? {
        let maxDistance = max(3.0.m, min(10.0.m, owner!.toMapDistance(viewDistance: 20.0)))
        guard let info = trackMap?.closestPointOnTrack(from: point), info.distance <= maxDistance
        else {
            return nil
        }
        let d =
            switch signalKind {
            case .section: 1.5.m
            case .main: 2.5.m
            }
        let p1 = info.point + d ** (info.orientation + 90.0.deg)
        let p2 = info.point + d ** (info.orientation - 90.0.deg)
        let position =
            if distance(point, p1) <= distance(point, p2) {
                PointAndOrientation(point: p1, orientation: info.orientation.opposite)
            } else {
                PointAndOrientation(point: p2, orientation: info.orientation)
            }
        if let trackMap = trackMap {
            guard !trackMap.signals.contains(where: { distance($0.point, position.point) < 5.0.m })
            else {
                return nil
            }
        }
        return SignalProposal(position: position)
    }

}
