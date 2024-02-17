//
//  TrackPen.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/14/24.
//

import Foundation
import CoreGraphics

class TrackPen: Tool {
    private weak var owner: ToolOwner?
    private var map: Map { owner!.map }
    
    private struct PenPoint {
        enum Target {
            case free(Point)
            case bound(TrackPoint)
        }
        struct Hint {
            let base: TrackPoint
            let offset: Distance
            
            var distance: Distance { return abs(offset) }
        }
        
        let target: Target
        let hint: Hint?
        
        var point: Point {
            switch target {
            case .free(let point): return point
            case .bound(let point): return point.point
            }
        }
        
        init(_ target: Target) {
            self.target = target
            self.hint = nil
        }
        
        init(target: Target, hint: Hint) {
            self.target = target
            self.hint = hint
        }
    }
    
    private struct TrackProposal {
        let path: SomeFinitePath
        let startConnection: TrackMap.ConnectionOption
        let endConnection: TrackMap.ConnectionOption
    }
    
    private struct PenDrag {
        let start: PenPoint
        let end: PenPoint
        let proposal: TrackProposal?
    }
    
    private enum State{
        case none
        case hovering(PenPoint)
        case dragging(PenDrag)
    }
    
    private var state: State = .none {
        didSet {
            owner?.stateChanged(tool: self)
        }
    }
    
    required init(owner: ToolOwner) {
        self.owner = owner
    }
    
    func mouseEntered(point: Point) {
        state = .hovering(startPointFor(point: point))
    }
    
    func mouseMoved(point: Point) {
        state = .hovering(startPointFor(point: point))
    }
    
    func mouseExited() {
        state = .none
    }
    
    func mouseDown(point: Point) {
        let penPoint = startPointFor(point: point)
        state = .dragging(PenDrag(start: penPoint, end: penPoint, proposal: nil))
    }
    
    func mouseDragged(point: Point) {
        switch state {
        case .none, .hovering:
            let penPoint = startPointFor(point: point)
            state = .dragging(PenDrag(start: penPoint, end: penPoint, proposal: nil))
        case .dragging(let oldPenDrag):
            let penStartPoint = oldPenDrag.start
            let penEndPoint = endPointFor(point: point, startPoint: penStartPoint)
            let proposal = TrackPen.proposal(from: penStartPoint, to: penEndPoint)
            state = .dragging(PenDrag(start: penStartPoint,
                                      end: penEndPoint,
                                      proposal: proposal))
        }
    }
    
    func mouseUp(point: Point) {
        switch state {
        case .none, .hovering: break
        case .dragging(let oldPenDrag):
            let penStartPoint = oldPenDrag.start
            let penEndPoint = endPointFor(point: point, startPoint: penStartPoint)
            if let proposal = TrackPen.proposal(from: penStartPoint, to: penEndPoint) {
                let _ = map.trackMap.addTrack(withPath: proposal.path,
                                              startConnection: proposal.startConnection,
                                              endConnection: proposal.endConnection)
            }
        }
        state = .none
    }
    
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext) {
        switch state {
        case .none: break
        case .hovering(let penPoint):
            cgContext.saveGState()
            TrackPen.draw(penPoint: penPoint, cgContext, viewContext)
            cgContext.restoreGState()
        case .dragging(let penDrag):
            cgContext.saveGState()
            if let path = penDrag.proposal?.path {
                trace(path: path, cgContext, viewContext)
                cgContext.setLineWidth(max(viewContext.toViewDistance(trackBedWidth), 3.0))
                cgContext.setStrokeColor(CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.5))
                cgContext.strokePath()
            } else {
                cgContext.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
                cgContext.setLineWidth(max(viewContext.toViewDistance(trackBedWidth / 4.0), 3.0))
                cgContext.setLineDash(phase: 0.0, lengths: [20.0, 20.0])
                cgContext.move(to: viewContext.toViewPoint(penDrag.start.point))
                cgContext.addLine(to: viewContext.toViewPoint(penDrag.end.point))
                cgContext.strokePath()
            }
            TrackPen.draw(penPoint: penDrag.start, cgContext, viewContext)
            TrackPen.draw(penPoint: penDrag.end, cgContext, viewContext)
            cgContext.restoreGState()
        }
    }
    
    private static func draw(penPoint: PenPoint, 
                             _ cgContext: CGContext,
                             _ viewContext: ViewContext) {
        let width = max(1.0.m, viewContext.toMapDistance(viewDistance: 8.0))
        if let hint = penPoint.hint {
            let hintColor: CGColor
            switch penPoint.target {
            case .free: hintColor = CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            case .bound: hintColor = CGColor.init(gray: 0.5, alpha: 1.0)
            }
            cgContext.setStrokeColor(hintColor)
            cgContext.setLineWidth(viewContext.toViewDistance(width / 4.0))
            cgContext.setLineDash(phase: 0.0, lengths: [5.0, 5.0])
            cgContext.move(to: viewContext.toViewPoint(hint.base.point))
            cgContext.addLine(to: viewContext.toViewPoint(penPoint.point))
            cgContext.strokePath()
            cgContext.setFillColor(hintColor)
            cgContext.fillEllipse(in: viewContext.toViewRect(Rect.square(around: hint.base.point,
                                                                         length: width)))
        }
        cgContext.setFillColor(CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0))
        cgContext.fillEllipse(in: viewContext.toViewRect(Rect.square(around: penPoint.point,
                                                                     length: width)))
    }
        
    private func boundPenPointFor(point: Point) -> PenPoint? {
        let penPointOffsetFunc = { (p: TrackPoint, d: Distance) -> PenPoint in
            PenPoint(target: .free(p.offsetLeft(by: d)), hint: PenPoint.Hint(base: p, offset: d))
        }
        let penPointsFunc = { (p: TrackPoint) -> [PenPoint] in
            [PenPoint(.bound(p)),
             penPointOffsetFunc(p,  +5.0.m),
             penPointOffsetFunc(p, +10.0.m),
             penPointOffsetFunc(p, +15.0.m),
             penPointOffsetFunc(p,  -5.0.m),
             penPointOffsetFunc(p, -10.0.m),
             penPointOffsetFunc(p, -15.0.m)]
        }
        let compareFunc = { (a: PenPoint, b: PenPoint) -> Bool in
            let da = distance(point, a.point)
            let db = distance(point, b.point)
            if da < db {
                return true
            } else if da > db {
                return false
            } else {
                return a.hint == nil && b.hint != nil
            }
        }
        if let closestPenPointOfInterest = map.trackMap.pointsOfInterest
            .flatMap(penPointsFunc)
            .filter({ distance(point, $0.point) <= 10.0.m })
            .sorted(by: compareFunc)
            .first {
            switch closestPenPointOfInterest.target {
            case .free:
                if let closestPointInfo =
                    map.trackMap.closestPointOnTrack(from: closestPenPointOfInterest.point),
                   closestPointInfo.distance == 0.0.m {
                    return PenPoint(target: .bound(closestPointInfo.asTrackPoint),
                                    hint: closestPenPointOfInterest.hint!)
                }
                return closestPenPointOfInterest
            case .bound:
                return closestPenPointOfInterest
            }
        }
        if let closestPointInfo = map.trackMap.closestPointOnTrack(from: point) {
            if (closestPointInfo.isTrackStart || closestPointInfo.isTrackEnd) &&
                closestPointInfo.distance <= 10.0.m {
                return PenPoint(.bound(closestPointInfo.asTrackPoint))
            } else if closestPointInfo.distance <= trackBedWidth {
                return PenPoint(.bound(closestPointInfo.asTrackPoint))
            }
        }
        return nil
    }
    
    private func startPointFor(point: Point) -> PenPoint {
        if let boundPenPoint = boundPenPointFor(point: point) {
            return boundPenPoint
        }
        return PenPoint(.free(point))
    }

    private func endPointFor(point: Point, startPoint: PenPoint) -> PenPoint {
        if let boundPenPoint = boundPenPointFor(point: point) {
            return boundPenPoint
        }
        switch startPoint.target {
        case .bound(let trackPoint):
            guard trackPoint.isTrackStart || trackPoint.isTrackEnd else { break }
            let p = closestPointOnLine(through: trackPoint.point,
                                       withOrientation: trackPoint.directionA.asAngle,
                                       to: point)
            if distance(point, p) <= 5.0.m {
                return PenPoint(.free(p))
            }
            break
        default:
            break
        }
        return PenPoint(.free(point))
    }
    
    private static func proposal(from start: PenPoint, to end: PenPoint) -> TrackProposal? {
        switch (start.target, end.target) {
        case (.free(let start), .free(let end)):
            return proposal(from: start, to: end)
        case (.free(let start), .bound(let end)):
            return proposal(from: end, to: start)
        case (.bound(let start), .free(let end)):
            return proposal(from: start, to: end)
        case (.bound(_), .bound(_)):
            return nil
        }
    }

    private static func proposal(from start: Point, to end: Point) -> TrackProposal? {
        guard let path = LinearPath(start: start, end: end) else { return nil }
        return TrackProposal(path: .linear(path), startConnection: .none, endConnection: .none)
    }
    
    private static func proposal(from start: TrackPoint, to end: Point) -> TrackProposal? {
        guard let (path, direction) = proposedPath(fromTrackPoint: start, toFreePoint: end) else {
            return nil
        }
        let connectionOption: TrackMap.ConnectionOption
        switch start {
        case .trackConnection(let connection):
            connectionOption = .toExistingConnection(connection, direction)
        case .trackPoint(let track, let x):
            if start.isTrackStart {
                connectionOption = .toExistingTrack(track, .start)
            } else if start.isTrackEnd {
                connectionOption = .toExistingTrack(track, .end)
            } else {
                connectionOption = .toNewConnection(track, x)
            }
        }
        return TrackProposal(path: path, startConnection: connectionOption, endConnection: .none)
    }
    
    private static func proposedPath(fromTrackPoint start: TrackPoint,
                                     toFreePoint end: Point) -> (SomeFinitePath,
                                                                 TrackConnection.Direction)? {
        if let (path, direction) = linearPath(fromTrackPoint: start, toFreePoint: end) {
            return (.linear(path), direction)
        } else if let (path, direction) = circularPath(fromTrackPoint: start, toFreePoint: end) {
            return (.circular(path), direction)
        } else {
            return nil
        }
    }
    
    private static func linearPath(fromTrackPoint start: TrackPoint,
                                   toFreePoint end: Point) -> (LinearPath,
                                                               TrackConnection.Direction)? {
        guard let path = LinearPath(start: start.point, end: end) else { return nil }
        if canConnect(start.pointAndDirectionA, path.startPointAndOrientation) {
            return (path, .a)
        } else if canConnect(start.pointAndDirectionB, path.startPointAndOrientation) {
            return (path, .b)
        } else {
            return nil
        }
    }

    private static func circularPath(fromTrackPoint start: TrackPoint,
                                     toFreePoint end: Point) -> (CircularPath,
                                                                 TrackConnection.Direction)? {
        let tangentAngle = CircleAngle(angle(from: start.point, to: end))
        let direction: TrackConnection.Direction
        let orientation: CircleAngle
        if absDiff(tangentAngle, start.directionA) < absDiff(tangentAngle, start.directionB) {
            direction = .a
            orientation = start.directionA
        } else {
            direction = .b
            orientation = start.directionB
        }
        let alpha = CircleAngle(tangentAngle - orientation.asAngle).asAngle
        let dist = distance(start.point, end)
        let radius = dist / 2.0 / sin(alpha)
        let center = start.point + (orientation + 90.0.deg) ** radius
        if let path = CircularPath(center: center,
                                   radius: abs(radius),
                                   startAngle: CircleAngle(angle(from: center, to: start.point)),
                                   endAngle: CircleAngle(angle(from: center, to: end)),
                                   direction: alpha >= 0.0.deg ? .positive : .negative) {
            return (path, direction)
        } else {
            return nil
        }
    }
    
}
