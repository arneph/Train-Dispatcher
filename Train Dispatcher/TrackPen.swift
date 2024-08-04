//
//  TrackPen.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/14/24.
//

import Base
import CoreGraphics
import Foundation
import Tracks

class TrackPen: Tool {
    var type: ToolType { .trackPen }

    private weak var owner: ToolOwner?
    private var map: Map? { owner?.map }
    private var trackMap: TrackMap? { owner?.map?.trackMap }
    private var changeManager: ChangeManager? { owner?.changeManager }

    private struct PenPoint {
        enum Target {
            case free(Point)
            case bound(TrackPoint)
        }
        struct Hint {
            let base: TrackPoint
            let offset: Distance

            var distance: Distance { abs(offset) }
        }

        let target: Target
        let hint: Hint?

        var point: Point {
            switch target {
            case .free(let point): point
            case .bound(let point): point.point
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
        let valid: Bool

        init(
            path: SomeFinitePath, startConnection: TrackMap.ConnectionOption,
            endConnection: TrackMap.ConnectionOption
        ) {
            self.path = path
            self.startConnection = startConnection
            self.endConnection = endConnection
            self.valid = isValid(trackPath: path)
        }
    }

    private struct PenDrag {
        let start: PenPoint
        let end: PenPoint
        let proposal: TrackProposal?
    }

    private enum State {
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
            state = .dragging(PenDrag(start: penStartPoint, end: penEndPoint, proposal: proposal))
        }
    }

    func mouseUp(point: Point) {
        switch state {
        case .none, .hovering: break
        case .dragging(let oldPenDrag):
            guard let trackMap = trackMap else { break }
            let penStartPoint = oldPenDrag.start
            let penEndPoint = endPointFor(point: point, startPoint: penStartPoint)
            if let proposal = TrackPen.proposal(from: penStartPoint, to: penEndPoint),
                proposal.valid
            {
                let (_, undoHandler) = trackMap.addTrack(
                    withPath: proposal.path, startConnection: proposal.startConnection,
                    endConnection: proposal.endConnection)
                changeManager?.add(change: undoHandler, withName: "Draw Track")
            }
        }
        state = .none
    }

    func draw(_ cgContext: CGContext, _ viewContext: ViewContext, _ dirtyRect: Rect) {
        switch state {
        case .none: break
        case .hovering(let penPoint):
            cgContext.saveGState()
            TrackPen.draw(penPoint: penPoint, cgContext, viewContext)
            cgContext.restoreGState()
        case .dragging(let penDrag):
            cgContext.saveGState()
            if let proposal = penDrag.proposal {
                if proposal.valid {
                    cgContext.setStrokeColor(CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.5))
                } else {
                    cgContext.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5))
                }
                cgContext.setLineWidth(viewContext.toViewDistance(trackBedWidth))
                stroke(path: proposal.path, cgContext, viewContext, trackBedWidth, dirtyRect)
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

    private static func draw(
        penPoint: PenPoint, _ cgContext: CGContext, _ viewContext: ViewContext
    ) {
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
            cgContext.fillEllipse(
                in: viewContext.toViewRect(Rect.square(around: hint.base.point, length: width)))
        }
        cgContext.setFillColor(CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(Rect.square(around: penPoint.point, length: width)))
    }

    private func boundPenPointFor(point: Point) -> PenPoint? {
        guard let trackMap = trackMap else { return nil }
        let maxDistance = min(10.0.m, owner!.toMapDistance(viewDistance: 20.0))
        let penPointOffsetFunc = { (p: TrackPoint, d: Distance) -> PenPoint in
            PenPoint(target: .free(p.offsetLeft(by: d)), hint: PenPoint.Hint(base: p, offset: d))
        }
        let penPointsFunc = { (p: TrackPoint) -> [PenPoint] in
            [
                PenPoint(.bound(p)), penPointOffsetFunc(p, +5.0.m), penPointOffsetFunc(p, +10.0.m),
                penPointOffsetFunc(p, +15.0.m), penPointOffsetFunc(p, -5.0.m),
                penPointOffsetFunc(p, -10.0.m), penPointOffsetFunc(p, -15.0.m),
            ]
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
        if let closestPenPointOfInterest = trackMap.pointsOfInterest
            .flatMap(penPointsFunc)
            .filter({ distance(point, $0.point) <= maxDistance })
            .sorted(by: compareFunc)
            .first
        {
            switch closestPenPointOfInterest.target {
            case .free:
                if let closestPointInfo =
                    trackMap.closestPointOnTrack(from: closestPenPointOfInterest.point),
                    closestPointInfo.distance == 0.0.m
                {
                    return PenPoint(
                        target: .bound(closestPointInfo.asTrackPoint),
                        hint: closestPenPointOfInterest.hint!)
                }
                return closestPenPointOfInterest
            case .bound:
                return closestPenPointOfInterest
            }
        }
        if let closestPointInfo = trackMap.closestPointOnTrack(from: point) {
            if (closestPointInfo.isTrackStart || closestPointInfo.isTrackEnd)
                && closestPointInfo.distance <= maxDistance
            {
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
            let p = Line(
                base: trackPoint.point, orientation: trackPoint.directionA.asAngle
            ).closestPoint(to: point)
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
            proposal(fromFreePoint: start, toFreePoint: end)
        case (.free(let start), .bound(let end)):
            proposal(fromTrackPoint: end, toFreePoint: start)
        case (.bound(let start), .free(let end)):
            proposal(fromTrackPoint: start, toFreePoint: end)
        case (.bound(let start), .bound(let end)):
            proposal(fromTrackPoint: start, toTrackPoint: end)
        }
    }

    private static func proposal(
        fromFreePoint start: Point, toFreePoint end: Point
    ) -> TrackProposal? {
        guard let path = LinearPath(start: start, end: end) else { return nil }
        return TrackProposal(path: .linear(path), startConnection: .none, endConnection: .none)
    }

    private static func proposal(
        fromTrackPoint start: TrackPoint, toFreePoint end: Point
    ) -> TrackProposal? {
        guard let path = proposedPath(fromTrackPoint: start, toFreePoint: end) else {
            return nil
        }
        return TrackProposal(
            path: path,
            startConnection:
                connectionOption(
                    forTrackPoint: start, newTrackPathOrientation: path.startOrientation)!,
            endConnection: .none)
    }

    private static func proposedPath(
        fromTrackPoint start: TrackPoint, toFreePoint end: Point
    ) -> SomeFinitePath? {
        let linearPath = linearPath(fromTrackPoint: start, toFreePoint: end)
        let circularPath = circularPath(fromTrackPoint: start, toFreePoint: end)
        if let path = linearPath, isValid(trackPath: .linear(path)) {
            return .linear(path)
        } else if let path = circularPath, isValid(trackPath: .circular(path)) {
            return .circular(path)
        } else if let path = linearPath {
            return .linear(path)
        } else if let path = circularPath {
            return .circular(path)
        } else {
            return nil
        }
    }

    private static func linearPath(
        fromTrackPoint start: TrackPoint, toFreePoint end: Point
    ) -> LinearPath? {
        guard let path = LinearPath(start: start.point, end: end) else { return nil }
        if canConnect(start.pointAndDirectionA, path.startPointAndOrientation) {
            return path
        } else if canConnect(start.pointAndDirectionB, path.startPointAndOrientation) {
            return path
        } else {
            return nil
        }
    }

    private static func circularPath(
        fromTrackPoint start: TrackPoint, toFreePoint end: Point
    ) -> CircularPath? {
        let tangentAngle = CircleAngle(angle(from: start.point, to: end))
        let orientation: CircleAngle
        if absDiff(tangentAngle, start.directionA) < absDiff(tangentAngle, start.directionB) {
            orientation = start.directionA
        } else {
            orientation = start.directionB
        }
        let alpha = CircleAngle(tangentAngle - orientation.asAngle).asAngle
        let dist = distance(start.point, end)
        let radius = dist / 2.0 / sin(alpha)
        let center = start.point + (orientation + 90.0.deg) ** radius
        return CircularPath(
            center: center, radius: abs(radius),
            startAngle: CircleAngle(angle(from: center, to: start.point)),
            endAngle: CircleAngle(angle(from: center, to: end)),
            direction: alpha >= 0.0.deg ? .positive : .negative)
    }

    private static func proposal(
        fromTrackPoint start: TrackPoint, toTrackPoint end: TrackPoint
    ) -> TrackProposal? {
        switch (start, end) {
        case (.trackConnection(let connectionA), .trackConnection(let connectionB)):
            guard connectionA !== connectionB else { return nil }
        case (.trackConnection(let connection), .trackPoint(let track, _)):
            guard !connection.allTracks.contains(where: { $0 === track }) else { return nil }
        case (.trackPoint(let track, _), .trackConnection(let connection)):
            guard !connection.allTracks.contains(where: { $0 === track }) else { return nil }
        case (.trackPoint(let trackA, _), .trackPoint(let trackB, _)):
            guard trackA !== trackB else { return nil }
        }
        guard let path = proposedPath(fromTrackPoint: start, toTrackPoint: end) else {
            return nil
        }
        return TrackProposal(
            path: path,
            startConnection:
                connectionOption(
                    forTrackPoint: start, newTrackPathOrientation: path.startOrientation)!,
            endConnection:
                connectionOption(
                    forTrackPoint: end,
                    newTrackPathOrientation:
                        path.endOrientation.opposite)!)
    }

    private static func proposedPath(
        fromTrackPoint start: TrackPoint, toTrackPoint end: TrackPoint
    ) -> SomeFinitePath? {
        let linearPath = proposedStraightPath(fromTrackPoint: start, toTrackPoint: end)
        let oneCurvePath = proposedOneCurvePath(fromTrackPoint: start, toTrackPoint: end)
        let twoCurvePath = proposedTwoCurvePath(fromTrackPoint: start, toTrackPoint: end)
        if let path = linearPath, isValid(trackPath: .linear(path)) {
            return .linear(path)
        } else if let path = oneCurvePath, isValid(trackPath: path) {
            return path
        } else if let path = twoCurvePath, isValid(trackPath: path) {
            return path
        } else if let path = linearPath {
            return .linear(path)
        } else if let path = oneCurvePath {
            return path
        } else if let path = twoCurvePath {
            return path
        } else {
            return nil
        }
    }

    private static func proposedStraightPath(
        fromTrackPoint start: TrackPoint, toTrackPoint end: TrackPoint
    ) -> LinearPath? {
        guard let path = LinearPath(start: start.point, end: end.point) else {
            return nil
        }
        if start.directionA == path.orientation {
            guard !start.isStraighInDirectionA else { return nil }
        } else if start.directionB == path.orientation {
            guard !start.isStraightInDirectionB else { return nil }
        } else {
            return nil
        }
        if end.directionA == path.orientation {
            guard !end.isStraightInDirectionB else { return nil }
        } else if end.directionB == path.orientation {
            guard !end.isStraighInDirectionA else { return nil }
        } else {
            return nil
        }
        return path
    }

    private static func proposedOneCurvePath(
        fromTrackPoint start: TrackPoint, toTrackPoint end: TrackPoint
    ) -> SomeFinitePath? {
        let l1 = Line(base: start.point, orientation: start.directionA.asAngle)
        let l2 = Line(base: end.point, orientation: end.directionA.asAngle)
        guard let p = Line.intersection(l1, l2) else { return nil }
        let rangeAtP = CircleRange.range(from: p, between: start.point, and: end.point)
        let d1 = distance(p, start.point)
        let d2 = distance(p, end.point)
        let d = min(d1, d2)
        let h = d / cos(0.5 * rangeAtP.absDelta)
        let radius = d * tan(0.5 * rangeAtP.absDelta)
        let center = p + h ** rangeAtP.middle.asAngle
        if d1 < d2 {
            let q = p + d ** rangeAtP.endAngle
            let rangeAtCenter = CircleRange.range(from: center, between: start.point, and: q)
            guard
                let circularPath = CircularPath(
                    center: center, radius: radius, circleRange: rangeAtCenter),
                let linearPath = LinearPath(start: q, end: end.point),
                let compoundPath = CompoundPath(components: [
                    .circular(circularPath), .linear(linearPath),
                ])
            else {
                return nil
            }
            return .compound(compoundPath)
        } else if d2 < d1 {
            let q = p + d ** rangeAtP.startAngle
            let rangeAtCenter = CircleRange.range(from: center, between: q, and: end.point)
            guard let linearPath = LinearPath(start: start.point, end: q),
                let circularPath = CircularPath(
                    center: center, radius: radius, circleRange: rangeAtCenter),
                let compoundPath = CompoundPath(components: [
                    .linear(linearPath), .circular(circularPath),
                ])
            else {
                return nil
            }
            return .compound(compoundPath)
        } else {
            let rangeAtCenter = CircleRange.range(
                from: center, between: start.point, and: end.point)
            guard
                let path = CircularPath(center: center, radius: radius, circleRange: rangeAtCenter)
            else { return nil }
            return .circular(path)
        }
    }

    private static func proposedTwoCurvePath(
        fromTrackPoint start: TrackPoint, toTrackPoint end: TrackPoint
    ) -> SomeFinitePath? {
        let alphaStartToEnd = CircleAngle(angle(from: start.point, to: end.point))
        let alphaEndToStart = alphaStartToEnd.opposite
        let alpha1 =
            absDiff(CircleAngle(start.directionA + 90.0.deg), alphaStartToEnd) <= 90.0.deg
            ? start.directionA + 90.0.deg : start.directionA - 90.0.deg
        let alpha2 =
            absDiff(CircleAngle(end.directionA + 90.0.deg), alphaEndToStart) <= 90.0.deg
            ? end.directionA + 90.0.deg : end.directionA - 90.0.deg
        let v = 1.0.m ** alpha2 - 1.0.m ** alpha1
        let d = direction(from: start.point, to: end.point)
        let a = length²(v) - 4.0.m²
        let b = 2.0 * scalar(d, v)
        let c = length²(d)
        let x: Float64
        if a == 0.0.m² {
            x = -c / b
        } else {
            let discriminant = pow²(b) - 4.0 * a * c
            if discriminant < 0.0.m⁴ {
                return nil
            } else if discriminant == 0.0.m⁴ {
                x = -b / (2.0 * a)
            } else {
                let x1 = (-b + sqrt(discriminant)) / (2.0 * a)
                let x2 = (-b - sqrt(discriminant)) / (2.0 * a)
                x = max(x1, x2)
            }
        }
        if x <= 0.0 {
            return nil
        }
        let r = Distance(x)
        let c1 = start.point + r ** alpha1
        let c2 = end.point + r ** alpha2
        let range1 = CircleRange.range(from: c1, between: start.point, and: c2)
        let range2 = CircleRange.range(from: c2, between: c1, and: end.point)
        guard let circle1 = CircularPath(center: c1, radius: r, circleRange: range1),
            let circle2 = CircularPath(center: c2, radius: r, circleRange: range2)
        else {
            return nil
        }
        if let path = CompoundPath(components: [.circular(circle1), .circular(circle2)]) {
            return .compound(path)
        } else {
            return nil
        }
    }

    private static func connectionOption(
        forTrackPoint point: TrackPoint, newTrackPathOrientation orientation: CircleAngle
    ) -> TrackMap.ConnectionOption? {
        switch point {
        case .trackConnection(let connection):
            return .toExistingConnection(connection)
        case .trackPoint(let track, let x):
            if point.isTrackStart {
                if track.path.startOrientation == orientation {
                    return .toNewConnection(track, 0.0.m)
                } else if track.path.startOrientation == orientation.opposite {
                    return .toExistingTrack(track, .start)
                } else {
                    assertionFailure("Expected newTrackPathOrientation to be aligned with track.")
                    return nil
                }
            } else if point.isTrackEnd {
                if track.path.endOrientation == orientation {
                    return .toExistingTrack(track, .end)
                } else if track.path.endOrientation == orientation.opposite {
                    return .toNewConnection(track, track.path.length)
                } else {
                    assertionFailure("Expected newTrackPathOrientation to be aligned with track.")
                    return nil
                }
            } else {
                return .toNewConnection(track, x)
            }
        }
    }

}
