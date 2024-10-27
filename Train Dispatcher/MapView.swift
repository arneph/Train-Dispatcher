//
//  MapView.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Base
import Cocoa
import CoreGraphics
import CoreText
import Foundation
import Ground
import Tracks
import Trains

protocol MapViewDelegate: AnyObject {
    var map: Map? { get }
    var changeManager: ChangeManager? { get }

    func cameraChanged()

    func toolChanged()
    func selectedTrain(train: Train)
}

class MapView: NSView,
    NSMenuItemValidation,
    GroundMapObserver,
    TrackMapObserver,
    TrainObserver,
    ToolOwner,
    ViewContext
{
    var delegate: MapViewDelegate? {
        willSet {
            if delegate !== newValue {
                delegate?.map?.groundMap.remove(observer: self)
                delegate?.map?.trackMap.remove(observer: self)
                delegate?.map?.trains.forEach { $0.remove(observer: self) }
            }
        }
        didSet {
            if oldValue !== delegate {
                delegate?.map?.groundMap.add(observer: self)
                delegate?.map?.trackMap.add(observer: self)
                delegate?.map?.trains.forEach { $0.add(observer: self) }
                needsDisplay = true
            }
        }
    }
    var map: Map? { delegate?.map }
    var changeManager: ChangeManager? { delegate?.changeManager }

    func mapChanged(oldMap: Map) {
        oldMap.groundMap.remove(observer: self)
        oldMap.trackMap.remove(observer: self)
        map?.groundMap.add(observer: self)
        map?.trackMap.add(observer: self)
        needsDisplay = true
    }

    // MARK: - GroundMapObserver
    func groundChanged(forMap map: GroundMap) {
        needsDisplay = true
    }

    // MARK: - TrackMapObserver
    func added(track: Track, toMap map: TrackMap) {
        needsDisplay = true
    }

    func replaced(track oldTrack: Track, withTracks newTracks: [Track], onMap map: TrackMap) {
        needsDisplay = true
    }

    func removed(track oldTrack: Track, fromMap map: TrackMap) {
        needsDisplay = true
    }

    func added(connection: TrackConnection, toMap map: TrackMap) {
        needsDisplay = true
    }

    func removed(connection oldConnection: TrackConnection, fromMap map: TrackMap) {
        needsDisplay = true
    }

    func added(signal: Tracks.Signal, toMap map: Tracks.TrackMap) {
        needsDisplay = true
    }

    func removed(signal oldSignal: Tracks.Signal, fromMap map: Tracks.TrackMap) {
        needsDisplay = true
    }

    func trackChanged(_ track: Track, onMap map: TrackMap) {
        needsDisplay = true
    }

    func connectionChanged(_ connection: TrackConnection, onMap map: TrackMap) {
        needsDisplay = true
    }

    // MARK: - TrainObserver
    func positionChanged(_ train: Train) {
        needsDisplay = true
    }

    // MARK: - Display State
    static let maxMapScale = 100.0
    static let minMapScale = 0.01

    var mapPointAtViewCenter: Point {
        Point(x: Position(mapCGPointAtViewCenter.x), y: Position(mapCGPointAtViewCenter.y))
    }
    @objc dynamic var mapCGPointAtViewCenter: CGPoint = CGPoint(x: 0.0, y: 0.0) {
        didSet { needsDisplay = true }
    }
    @objc dynamic var mapScale: CGFloat = 10.0 {
        didSet {
            if mapScale < MapView.minMapScale {
                mapScale = MapView.minMapScale
            }
            if mapScale > MapView.maxMapScale {
                mapScale = MapView.maxMapScale
            }
            needsDisplay = true
        }
    }

    enum Camera {
        case free
        case trackingTrain(Train)
    }
    var camera: Camera = .free {
        didSet {
            delegate?.cameraChanged()
            needsDisplay = true
        }
    }

    // MARK: - Tool
    public var tool: Tool? {
        didSet {
            needsDisplay = true
            delegate?.toolChanged()
        }
    }

    func stateChanged(tool: Tool) {
        needsDisplay = true
    }

    @IBAction func selectCursor(_ sender: Any) {
        tool = nil
    }

    @IBAction func selectGroundBrush(_ sender: Any) {
        tool = GroundBrush(owner: self)
    }

    @IBAction func selectTreePlacer(_ sender: Any) {
        tool = nil
    }

    @IBAction func selectTrackPen(_ sender: Any) {
        tool = TrackPen(owner: self)
    }

    // MARK: - init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - NSView notifications
    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
    }

    // MARK: - Conversion (ViewContext)
    func toMapDistance(viewDistance: CGFloat) -> Distance {
        Distance(viewDistance / mapScale)
    }

    func toMapPoint(viewPoint: CGPoint) -> Point {
        mapPointAtViewCenter
            + Point(
                x: Position((viewPoint.x - bounds.midX) / mapScale),
                y: Position((viewPoint.y - bounds.midY) / mapScale))
    }

    func toMapSize(viewSize: CGSize) -> Size {
        Size(
            width: Distance(viewSize.width / mapScale), height: Distance(viewSize.height / mapScale)
        )
    }

    func toMapRect(viewRect: CGRect) -> Rect {
        Rect(
            origin: toMapPoint(viewPoint: viewRect.origin),
            size: toMapSize(viewSize: viewRect.size))
    }

    func toViewAngle(_ angle: Angle) -> CGFloat { angle.withoutUnit }

    func toViewDistance(_ distance: Distance) -> CGFloat {
        mapScale * distance.withoutUnit
    }

    func toViewPoint(_ mapPoint: Point) -> CGPoint {
        CGPoint(
            x: bounds.midX + mapScale * (mapPoint - mapPointAtViewCenter).x.withoutUnit,
            y: bounds.midY + mapScale * (mapPoint - mapPointAtViewCenter).y.withoutUnit)
    }

    func toViewSize(_ mapSize: Size) -> CGSize {
        CGSize(
            width: mapScale * mapSize.width.withoutUnit,
            height: mapScale * mapSize.height.withoutUnit)
    }

    func toViewRect(_ mapRect: Rect) -> CGRect {
        CGRect(origin: toViewPoint(mapRect.origin), size: toViewSize(mapRect.size))
    }

    // MARK: - Event handling
    override var acceptsFirstResponder: Bool { true }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(selectCursor(_:)):
            menuItem.state = tool == nil ? .on : .off
            return true
        case #selector(selectGroundBrush(_:)):
            menuItem.state = tool?.type == .groundBrush ? .on : .off
            return true
        case #selector(selectTreePlacer(_:)):
            menuItem.state = tool?.type == .treePlacer ? .on : .off
            return true
        case #selector(selectTrackPen(_:)):
            menuItem.state = tool?.type == .trackPen ? .on : .off
            return true
        case #selector(toggleGrid(_:)):
            menuItem.state = showGrid ? .on : .off
            return true
        case #selector(toggleScale(_:)):
            menuItem.state = showScale ? .on : .off
            return true
        case #selector(zoomImageToActualSize(_:)):
            return mapScale != 10.0
        case #selector(zoomImageToFit(_:)):
            return true
        case #selector(zoomIn(_:)):
            return true
        case #selector(zoomOut(_:)):
            return true
        default:
            return false
        }
    }

    @IBAction func toggleGrid(_ sender: NSMenuItem) {
        showGrid = !showGrid
    }

    @IBAction func toggleScale(_ sender: NSMenuItem) {
        showScale = !showScale
    }

    @IBAction func zoomImageToActualSize(_ sender: NSMenuItem) {
        animator().mapScale = 10.0
    }

    @IBAction func zoomImageToFit(_ sender: NSMenuItem) {

    }

    @IBAction func zoomIn(_ sender: NSMenuItem) {
        animator().mapScale = mapScale * 2.0
    }

    @IBAction func zoomOut(_ sender: NSMenuItem) {
        animator().mapScale = mapScale / 2.0
    }

    override func mouseEntered(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        tool?.mouseEntered(point: mapPoint)
    }

    override func mouseMoved(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        tool?.mouseMoved(point: mapPoint)
    }

    override func mouseExited(with event: NSEvent) {
        tool?.mouseExited()
    }

    override func mouseDown(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        if let tool = tool {
            tool.mouseDown(point: mapPoint)
        } else if let map = map {
            for train in map.trains {
                for vehicle in train.vehicles {
                    let l1 = Line(base: vehicle.center, orientation: vehicle.forward)
                    let l2 = Line(base: vehicle.center, orientation: vehicle.left)
                    let d1 = distance(mapPoint, l1.closestPoint(to: mapPoint))
                    let d2 = distance(mapPoint, l2.closestPoint(to: mapPoint))
                    if d1 <= 0.5 * vehicle.width && d2 <= 0.5 * vehicle.length {
                        delegate?.selectedTrain(train: train)
                        return
                    }
                }
            }
            for signal in map.trackMap.signals {
                guard distance(mapPoint, signal.point) <= 5.0.m else { continue }
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
            for connection in map.trackMap.connections {
                guard distance(mapPoint, connection.point) <= 50.0.m else { continue }
                for direction in [TrackConnection.Direction.a, .b] {
                    guard connection.hasSwitch(inDirection: direction) else { continue }
                    for track in connection.tracks(inDirection: direction) {
                        let path = connection.switchPath(for: track)
                        let d = path.closestPointOnPath(from: mapPoint).distance
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
    }

    override func mouseDragged(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        tool?.mouseDragged(point: mapPoint)
    }

    override func mouseUp(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        tool?.mouseUp(point: mapPoint)
    }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.shift) {
            let delta = Direction(
                x: Distance(+event.scrollingDeltaX / mapScale),
                y: Distance(-event.scrollingDeltaY / mapScale))
            if event.modifierFlags.contains(.option) {
                let p = mapPointAtViewCenter + delta
                camera = .free
                mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            } else {
                let p = mapPointAtViewCenter - delta
                camera = .free
                mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            }
        } else {
            mapScale *= 1.0 + 0.01 * event.scrollingDeltaY
        }
    }

    override func magnify(with event: NSEvent) {
        let f = 1.0 + event.magnification
        let viewMagnificationCenter = convert(event.locationInWindow, from: nil)
        let mapMagnificationCenter = toMapPoint(viewPoint: viewMagnificationCenter)
        let mapOldDelta = mapPointAtViewCenter - mapMagnificationCenter
        let mapNewDelta = mapOldDelta / f
        let p = mapPointAtViewCenter + mapNewDelta
        mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
        mapScale *= f
    }

    override func keyDown(with event: NSEvent) {
        let hOffset = Distance(0.2 * bounds.width / mapScale)
        let vOffset = Distance(0.2 * bounds.height / mapScale)
        let zFactor: CGFloat = 2.0
        var unprocessedKeys = false
        for c in event.charactersIgnoringModifiers! {
            switch c {
            case Character(UnicodeScalar(NSUpArrowFunctionKey)!), "w":
                let p = mapPointAtViewCenter + Direction(x: Distance(0.0), y: vOffset)
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSDownArrowFunctionKey)!), "s":
                let p = mapPointAtViewCenter - Direction(x: Distance(0.0), y: vOffset)
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSLeftArrowFunctionKey)!), "a":
                let p = mapPointAtViewCenter - Direction(x: hOffset, y: Distance(0.0))
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSRightArrowFunctionKey)!), "d":
                let p = mapPointAtViewCenter + Direction(x: hOffset, y: Distance(0.0))
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case "q":
                animator().mapScale = mapScale / zFactor
            case "e":
                animator().mapScale = mapScale * zFactor
            default:
                unprocessedKeys = true
                continue
            }
        }
        if unprocessedKeys {
            super.keyDown(with: event)
        }
    }

    // MARK: - Animation
    override static func defaultAnimation(forKey key: NSAnimatablePropertyKey) -> Any? {
        switch key {
        case "mapCGPointAtViewCenter", "mapScale":
            CABasicAnimation()
        default:
            super.defaultAnimation(forKey: key)
        }
    }

    // MARK: - Drawing
    var context: CGContext { NSGraphicsContext.current!.cgContext }
    var style: Style {
        switch effectiveAppearance.name {
        case .darkAqua:
            .dark
        default:
            .light
        }
    }

    private var showGrid = true {
        didSet { needsDisplay = true }
    }
    private var showScale = true {
        didSet { needsDisplay = true }
    }

    override func draw(_ viewRect: CGRect) {
        switch camera {
        case .free:
            break
        case .trackingTrain(let train):
            let vehicle = train.vehicles.first!
            mapCGPointAtViewCenter = CGPoint(
                x: vehicle.center.x.withoutUnit,
                y: vehicle.center.y.withoutUnit)
        }

        let t = Date.now
        let mapRect = toMapRect(viewRect: viewRect)

        if let map = map {
            map.groundMap.draw(context, self, mapRect)
        }

        if showGrid {
            drawGrid(mapRect)
        }

        if let map = map {
            Tracks.draw(trackMap: map.trackMap, context, self, mapRect)
            for signal in map.trackMap.signals {
                Tracks.draw(signal: signal, context, self, mapRect)
            }
            map.trains.forEach { $0.draw(context, self, mapRect) }
            map.containers.forEach { $0.draw(context, self, mapRect) }
        }
        tool?.draw(context, self, mapRect)

        if showScale {
            drawScale()
        }

        let d = Date.now.timeIntervalSince(t)
        drawFPS(Int(1.0 / d))
    }

    private var gridScale: Float64 {
        if mapScale >= 20.0 {
            1.0
        } else if mapScale >= 10.0 {
            2.0
        } else if mapScale >= 2.0 {
            10.0
        } else if mapScale >= 1.0 {
            20.0
        } else if mapScale >= 0.2 {
            100.0
        } else if mapScale >= 0.1 {
            200.0
        } else {
            1000.0
        }
    }

    private func drawGrid(_ rect: Rect) {
        context.saveGState()

        switch style {
        case .light:
            context.setStrokeColor(CGColor.init(gray: 0.2, alpha: 1.0))
        case .dark:
            context.setStrokeColor(CGColor.init(gray: 0.8, alpha: 1.0))
        }

        let minX = Int(floor(rect.minX.withoutUnit / gridScale) * gridScale)
        let minY = Int(floor(rect.minY.withoutUnit / gridScale) * gridScale)
        let maxX = Int(ceil(rect.maxX.withoutUnit / gridScale) * gridScale)
        let maxY = Int(ceil(rect.maxY.withoutUnit / gridScale) * gridScale)
        for x in stride(from: minX, through: maxX, by: Int(gridScale)) {
            let start = toViewPoint(Point(x: Position(x), y: Position(minY)))
            let end = toViewPoint(Point(x: Position(x), y: Position(maxY)))
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }
        for y in stride(from: minY, through: maxY, by: Int(gridScale)) {
            let start = toViewPoint(Point(x: Position(minX), y: Position(y)))
            let end = toViewPoint(Point(x: Position(maxX), y: Position(y)))
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }

        context.restoreGState()
    }

    private func drawScale() {
        context.saveGState()

        let foregroundColor: CGColor
        let backgroundColor: CGColor
        switch style {
        case .light:
            foregroundColor = CGColor.black
            backgroundColor = CGColor.white
        case .dark:
            foregroundColor = CGColor.white
            backgroundColor = CGColor.black
        }

        let font = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: foregroundColor,
        ]
        let length = NSAttributedString(
            string: String(Int(gridScale)) + "m", attributes: attributes)
        let line = CTLineCreateWithAttributedString(length)
        let lengthWidth = CTLineGetImageBounds(line, context).width
        let measurementWidth = gridScale * mapScale
        let totalWidth = lengthWidth + measurementWidth + 12.0
        let totalHeight = 16.0

        context.setFillColor(backgroundColor)
        context.move(to: CGPoint(x: bounds.maxX - totalWidth, y: 0.0))
        context.addLine(to: CGPoint(x: bounds.maxX - totalWidth, y: totalHeight - 4.0))
        context.addArc(
            center: CGPoint(x: bounds.maxX - totalWidth + 4.0, y: totalHeight - 4.0), radius: 4.0,
            startAngle: CGFloat.pi, endAngle: 0.5 * CGFloat.pi, clockwise: true)
        context.addLine(to: CGPoint(x: bounds.maxX, y: totalHeight))
        context.addLine(to: CGPoint(x: bounds.maxX, y: 0.0))
        context.closePath()
        context.fillPath()

        context.textPosition = CGPoint(
            x: bounds.maxX - lengthWidth - measurementWidth - 8, y: bounds.minY + 4)
        CTLineDraw(line, context)

        context.setStrokeColor(foregroundColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: bounds.maxX - 4, y: bounds.minY + 12))
        context.addLine(to: CGPoint(x: bounds.maxX - 4, y: bounds.minY + 4))
        context.addLine(to: CGPoint(x: bounds.maxX - measurementWidth - 4, y: bounds.minY + 4))
        context.addLine(to: CGPoint(x: bounds.maxX - measurementWidth - 4, y: bounds.minY + 12))
        context.strokePath()

        context.restoreGState()
    }

    private func drawFPS(_ fps: Int) {
        context.saveGState()

        let font = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
        ]
        let length = NSAttributedString(string: "FPS: \(fps)", attributes: attributes)
        let line = CTLineCreateWithAttributedString(length)

        context.textPosition = CGPoint(x: bounds.minX + 4, y: bounds.minY + 4)
        CTLineDraw(line, context)

        context.restoreGState()
    }

}
