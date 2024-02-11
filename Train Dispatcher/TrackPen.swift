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
    
    private enum PenPoint {
        case freePoint(Point)
        case trackMidPoint(ClosestTrackPointInfo)
        case trackEndPoint(ClosestTrackPointInfo)
        
        var point: Point {
            switch self {
            case .freePoint(let point):
                return point
            case .trackMidPoint(let info):
                return info.point
            case .trackEndPoint(let info):
                return info.point
            }
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
            switch penPoint {
            case .freePoint: break
            default:
                cgContext.saveGState()
                cgContext.setFillColor(CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0))
                cgContext.fillEllipse(in: viewContext.toViewRect(Rect.square(around: penPoint.point,
                                                                             length: 1.0.m)))
                cgContext.restoreGState()
            }
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
            
            let diameter = max(1.0.m, viewContext.toMapDistance(viewDistance: 8.0))
            cgContext.setFillColor(CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0))
            cgContext.fillEllipse(in: 
                viewContext.toViewRect(Rect.square(around: penDrag.start.point,
                                                   length: diameter)))
            cgContext.fillEllipse(in:
                viewContext.toViewRect(Rect.square(around: penDrag.end.point,
                                                   length: diameter)))
            cgContext.restoreGState()
        }
    }
    
    private func startPointFor(point: Point) -> PenPoint {
        if let closestTrackPointInfo = map.closestPointOnTrack(from: point),
            closestTrackPointInfo.distance <= 5.0.m {
            if closestTrackPointInfo.isTrackStart || closestTrackPointInfo.isTrackEnd {
                return .trackEndPoint(closestTrackPointInfo)
            } else {
                return .trackMidPoint(closestTrackPointInfo)
            }
        }
        return .freePoint(point)
    }

    private func endPointFor(point: Point, startPoint: PenPoint) -> PenPoint {
        if let closestTrackPointInfo = map.closestPointOnTrack(from: point),
            closestTrackPointInfo.distance <= 5.0.m {
            if closestTrackPointInfo.isTrackStart || closestTrackPointInfo.isTrackEnd {
                return .trackEndPoint(closestTrackPointInfo)
            } else {
                return .trackMidPoint(closestTrackPointInfo)
            }
        }
        switch startPoint {
        case .trackEndPoint(let start):
            let p = closestPointOnLine(through: start.point,
                                       withOrientation: start.orientation.asAngle,
                                       to: point)
            if distance(point, p) <= 5.0.m {
                return .freePoint(p)
            }
            break
        default:
            break
        }
        return .freePoint(point)
    }
    
    private static func proposal(from start: PenPoint, to end: PenPoint) -> TrackProposal? {
        switch (start, end) {
        case (.freePoint(let start), .freePoint(let end)):
            guard let path = LinearPath(start: start, end: end) else { return nil }
            return TrackProposal(path: .linear(path), startConnection: .none, endConnection: .none)
        case (.freePoint(let start), .trackMidPoint(let end)):
            if let path = circularPath(fromTrackPoint: end, toFreePoint: start) {
                return TrackProposal(path: .circular(path.reverse),
                                     startConnection: .none,
                                     endConnection: .toNewConnection(end.track,
                                                                     end.trackPathPosition))
            }
            return nil
        case (.trackMidPoint(let start), .freePoint(let end)):
            if let path = circularPath(fromTrackPoint: start, toFreePoint: end) {
                return TrackProposal(path: .circular(path),
                                     startConnection: .toNewConnection(start.track,
                                                                       start.trackPathPosition),
                                     endConnection: .none)
            }
            return nil
        case (.trackEndPoint(let start), .freePoint(let end)):
            let path: SomeFinitePath
            if let p = linearPath(fromTrackPoint: start, toFreePoint: end) {
                path = .linear(p)
            } else if let p = circularPath(fromTrackPoint: start, toFreePoint: end) {
                path = .circular(p)
            } else {
                return nil
            }
            let startConnection: TrackMap.ConnectionOption
            if start.isTrackStart {
                if let connection = start.track.startConnection {
                    let direction: TrackConnection.Direction =
                        connection.directionA == start.orientation ? .a : .b
                    startConnection = .toExistingConnection(connection, direction)
                } else {
                    startConnection = .toExistingTrack(start.track, .start)
                }
            } else {
                if let connection = start.track.endConnection {
                    let direction: TrackConnection.Direction =
                        connection.directionA == start.orientation ? .b : .a
                    startConnection = .toExistingConnection(connection, direction)
                } else {
                    startConnection = .toExistingTrack(start.track, .end)
                }
            }
            return TrackProposal(path: path,
                                 startConnection: startConnection,
                                 endConnection: .none)
        default:
            return nil
        }
    }

    private static func linearPath(fromTrackPoint start: ClosestTrackPointInfo,
                                   toFreePoint end: Point) -> LinearPath? {
        guard let path = LinearPath(start: start.point, end: end),
              canConnect(start.pointAndOrientation, path.startPointAndOrientation) else {
            return nil
        }
        return path
    }

    private static func circularPath(fromTrackPoint start: ClosestTrackPointInfo,
                                     toFreePoint end: Point) -> CircularPath? {
        var orientation = start.orientation.asAngle
        var alpha = CircleAngle(angle(from: start.point, to: end) - orientation).asAngle
        if alpha < -90.0.deg {
            orientation += 180.0.deg
            alpha += 180.0.deg
        } else if alpha > 90.0.deg {
            orientation += 180.0.deg
            alpha -= 180.0.deg
        }
        let dist = distance(start.point, end)
        let radius = dist / 2.0 / sin(alpha)
        let center = start.point + (orientation + 90.0.deg) ** radius
        return CircularPath(center: center,
                            radius: abs(radius),
                            startAngle: CircleAngle(angle(from: center, to: start.point)),
                            endAngle: CircleAngle(angle(from: center, to: end)),
                            direction: alpha >= 0.0.deg ? .positive : .negative)
    }
    
}
