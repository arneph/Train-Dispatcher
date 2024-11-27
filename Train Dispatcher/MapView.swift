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

class MapView: NSView, NSMenuItemValidation, ViewContext {
    var delegate: MapViewDelegate? {
        willSet {
            if delegate !== newValue {
                delegate?.map?.groundMap.remove(observer: self)
                delegate?.map?.trackMap.observers.remove(self)
                delegate?.map?.trains.forEach { $0.remove(observer: self) }
            }
        }
        didSet {
            if oldValue !== delegate {
                delegate?.map?.groundMap.add(observer: self)
                delegate?.map?.trackMap.observers.add(self)
                delegate?.map?.trains.forEach { $0.add(observer: self) }
                needsDisplay = true
            }
        }
    }
    var map: Map? { delegate?.map }
    var changeManager: ChangeManager? { delegate?.changeManager }

    func mapChanged(oldMap: Map) {
        oldMap.groundMap.remove(observer: self)
        oldMap.trackMap.observers.remove(self)
        map?.groundMap.add(observer: self)
        map?.trackMap.observers.add(self)
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
    var mapRotation: CircleAngle { CircleAngle(Angle(mapCGRotation)) }
    @objc dynamic var mapCGRotation: CGFloat = 0.0 {
        didSet {
            while mapCGRotation < -CGFloat.pi { mapCGRotation += 2.0 * CGFloat.pi }
            while mapCGRotation >= CGFloat.pi { mapCGRotation -= 2.0 * CGFloat.pi }
            needsDisplay = true
        }
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

    @IBAction func selectCursor(_ sender: Any) {
        tool = Cursor(owner: self)
    }

    @IBAction func selectGroundBrush(_ sender: Any) {
        tool = GroundBrush(owner: self)
    }

    @IBAction func selectTreePlacer(_ sender: Any) {
        tool = TreePlacer(owner: self)
    }

    @IBAction func selectTrackPen(_ sender: Any) {
        tool = TrackPen(owner: self)
    }

    @IBAction func selectSectionCutter(_ sender: Any) {
        tool = SectionCutter(owner: self)
    }

    @IBAction func selectSectionSignalPlacer(_ sender: Any) {
        tool = SectionSignalPlacer(owner: self)
    }

    @IBAction func selectMainSignalPlacer(_ sender: Any) {
        tool = MainSignalPlacer(owner: self)
    }

    // MARK: - init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.tool = Cursor(owner: self)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tool = Cursor(owner: self)
    }

    // MARK: - NSView notifications
    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
    }

    // MARK: - Conversion (ViewContext)
    func toMapAngle(viewAngle: CGFloat) -> Angle {
        mapRotation + Angle(viewAngle)
    }

    func toMapDistance(viewDistance: CGFloat) -> Distance {
        Distance(viewDistance / mapScale)
    }

    func toMapPoint(viewPoint: CGPoint) -> Point {
        let v = Direction(
            x: Position((viewPoint.x - bounds.midX) / mapScale),
            y: Position((viewPoint.y - bounds.midY) / mapScale))
        let (a, d) = angleAndLength(of: v)
        return mapPointAtViewCenter + d ** (mapRotation + a)
    }

    func toViewAngle(_ mapAngle: Angle) -> CGFloat {
        (mapAngle - mapRotation.asAngle).withoutUnit
    }

    func toViewDistance(_ distance: Distance) -> CGFloat {
        mapScale * distance.withoutUnit
    }

    func toViewPoint(_ mapPoint: Point) -> CGPoint {
        let (a, d) = angleAndLength(of: mapPoint - mapPointAtViewCenter)
        let v = d ** (a - mapRotation.asAngle)
        return CGPoint(
            x: bounds.midX + mapScale * v.x.withoutUnit,
            y: bounds.midY + mapScale * v.y.withoutUnit)
    }

    // MARK: - Event handling
    override var acceptsFirstResponder: Bool { true }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(selectCursor(_:)):
            menuItem.state = tool?.type == .cursor ? .on : .off
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
        case #selector(selectSectionCutter(_:)):
            menuItem.state = tool?.type == .sectionCutter ? .on : .off
            return true
        case #selector(selectSectionSignalPlacer(_:)):
            menuItem.state = tool?.type == .sectionSignalPlacer ? .on : .off
            return true
        case #selector(selectMainSignalPlacer(_:)):
            menuItem.state = tool?.type == .mainSignalPlacer ? .on : .off
            return true
        case #selector(toggleGrid(_:)):
            menuItem.state = showGrid ? .on : .off
            return true
        case #selector(toggleScale(_:)):
            menuItem.state = showScale ? .on : .off
            return true
        case #selector(toggleCompass(_:)):
            menuItem.state = showCompass ? .on : .off
            return true
        case #selector(zoomImageToActualSize(_:)):
            return mapScale != 10.0
        case #selector(zoomImageToFit(_:)):
            return true
        case #selector(zoomIn(_:)):
            return true
        case #selector(zoomOut(_:)):
            return true
        case #selector(orientNorth(_:)):
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

    @IBAction func toggleCompass(_ sender: NSMenuItem) {
        showCompass = !showCompass
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

    @IBAction func orientNorth(_ sender: NSMenuItem) {
        animator().mapCGRotation = 0.0
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

    private struct CompassMouseAction {
        let mouseStartAngle: CGFloat
        let rotationStart: CircleAngle
        var dragged = false
    }
    private var compassMouseAction: CompassMouseAction? = nil

    override func mouseDown(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        if showCompass {
            let center = compassCenter()
            let d = hypot(viewPoint.x - center.x, viewPoint.y - center.y)
            if d <= MapView.compassRadius {
                compassMouseAction = CompassMouseAction(
                    mouseStartAngle: atan2(viewPoint.y - center.y, viewPoint.x - center.x),
                    rotationStart: mapRotation)
                return
            }
        }
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        if let tool = tool {
            tool.mouseDown(point: mapPoint)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        if let action = compassMouseAction {
            let center = compassCenter()
            let mouseStartAngle = action.mouseStartAngle
            let mouseEndAngle = atan2(viewPoint.y - center.y, viewPoint.x - center.x)
            let rotationStart = action.rotationStart
            let rotationEnd = rotationStart + Angle(mouseEndAngle - mouseStartAngle)
            camera = .free
            mapCGRotation = rotationEnd.withoutUnit
            compassMouseAction!.dragged = true
            return
        }
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        tool?.mouseDragged(point: mapPoint)
    }

    override func mouseUp(with event: NSEvent) {
        let viewPoint = convert(event.locationInWindow, from: nil)
        if let action = compassMouseAction {
            if !action.dragged {
                camera = .free
                animator().mapCGRotation = 0.0
            } else {
                let center = compassCenter()
                let mouseStartAngle = action.mouseStartAngle
                let mouseEndAngle = atan2(viewPoint.y - center.y, viewPoint.x - center.x)
                let rotationStart = action.rotationStart
                let rotationEnd = rotationStart + Angle(mouseEndAngle - mouseStartAngle)
                camera = .free
                mapCGRotation = rotationEnd.withoutUnit
            }
            compassMouseAction = nil
            return
        }
        let mapPoint = toMapPoint(viewPoint: viewPoint)
        tool?.mouseUp(point: mapPoint)
    }

    override func scrollWheel(with event: NSEvent) {
        switch event.subtype {
        case .mouseEvent:
            if event.modifierFlags.contains(.option) {
                let r = mapRotation + 0.5.deg * event.scrollingDeltaY
                camera = .free
                mapCGRotation = r.withoutUnit
            } else if event.modifierFlags.contains(.command) {
                let delta =
                    if event.modifierFlags.contains(.control) {
                        Direction(x: Distance(event.scrollingDeltaY / mapScale), y: 0.0.m)
                    } else {
                        Direction(x: 0.0.m, y: Distance(event.scrollingDeltaY / mapScale))
                    }
                let (a, d) = angleAndLength(of: delta)
                let p = mapPointAtViewCenter + d ** (mapRotation + a)
                camera = .free
                mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            } else {
                mapScale *= 1.0 + 0.01 * event.scrollingDeltaY
            }
        default:
            let delta = Direction(
                x: Distance(-event.scrollingDeltaX / mapScale),
                y: Distance(+event.scrollingDeltaY / mapScale))
            let (a, d) = angleAndLength(of: delta)
            let p = mapPointAtViewCenter + d ** (mapRotation + a)
            camera = .free
            mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
        }
    }

    override func rotate(with event: NSEvent) {
        let rFactor = Float64(event.rotation) * -1.0.deg
        let viewRotationCenter = convert(event.locationInWindow, from: nil)
        let mapRotationCenter = toMapPoint(viewPoint: viewRotationCenter)
        let v = direction(from: mapRotationCenter, to: mapPointAtViewCenter)
        let (a, d) = angleAndLength(of: v)
        let p = mapRotationCenter + d ** (a + rFactor)
        camera = .free
        mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
        mapCGRotation = (mapRotation + rFactor).withoutUnit
    }

    override func magnify(with event: NSEvent) {
        let f = 1.0 + event.magnification
        let viewMagnificationCenter = convert(event.locationInWindow, from: nil)
        let mapMagnificationCenter = toMapPoint(viewPoint: viewMagnificationCenter)
        let v = direction(from: mapMagnificationCenter, to: mapPointAtViewCenter)
        let p = mapMagnificationCenter + v / f
        camera = .free
        mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
        mapScale *= f
    }

    override func keyDown(with event: NSEvent) {
        let hOffset = Distance(0.2 * bounds.width / mapScale)
        let vOffset = Distance(0.2 * bounds.height / mapScale)
        let rFactor = 15.0.deg
        let zFactor: CGFloat = 2.0
        var unprocessedKeys = false
        for c in event.charactersIgnoringModifiers! {
            switch c {
            case Character(UnicodeScalar(NSUpArrowFunctionKey)!), "w":
                let p = mapPointAtViewCenter + vOffset ** (mapRotation + 90.0.deg)
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSDownArrowFunctionKey)!), "s":
                let p = mapPointAtViewCenter + vOffset ** (mapRotation + 270.0.deg)
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSLeftArrowFunctionKey)!), "a":
                let p = mapPointAtViewCenter + hOffset ** (mapRotation + 180.0.deg)
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSRightArrowFunctionKey)!), "d":
                let p = mapPointAtViewCenter + hOffset ** mapRotation.asAngle
                camera = .free
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case "q":
                let r = mapRotation + rFactor
                camera = .free
                animator().mapCGRotation = r.withoutUnit
            case "e":
                let r = mapRotation - rFactor
                camera = .free
                animator().mapCGRotation = r.withoutUnit
            case "r":
                animator().mapScale = mapScale * zFactor
            case "f":
                animator().mapScale = mapScale / zFactor
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
        case "mapCGPointAtViewCenter", "mapCGRotation", "mapScale":
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
    private var showCompass = true {
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
            mapCGRotation = (vehicle.forward - 90.0.deg).withoutUnit
        }

        let t = Date.now
        let p1 = toMapPoint(viewPoint: CGPoint(x: viewRect.minX, y: viewRect.minY))
        let p2 = toMapPoint(viewPoint: CGPoint(x: viewRect.minX, y: viewRect.maxY))
        let p3 = toMapPoint(viewPoint: CGPoint(x: viewRect.maxX, y: viewRect.minY))
        let p4 = toMapPoint(viewPoint: CGPoint(x: viewRect.maxX, y: viewRect.maxY))
        let mapRect = Rect(
            p1: Point(
                x: min(p1.x, p2.x, p3.x, p4.x),
                y: min(p1.y, p2.y, p3.y, p4.y)),
            p2: Point(
                x: max(p1.x, p2.x, p3.x, p4.x),
                y: max(p1.y, p2.y, p3.y, p4.y)))
        let mapContext = DrawContext(cgContext: context, viewContext: self, dirtyRect: mapRect)

        if let map = map {
            map.groundMap.draw(ctx: mapContext)
        }
        tool?.draw(layer: .aboveGroundMap, ctx: mapContext)

        if showGrid {
            drawGrid(mapRect)
        }

        if let map = map {
            Tracks.draw(trackMap: map.trackMap, ctx: mapContext)
            for signal in map.trackMap.signals {
                Tracks.draw(signal: signal, ctx: mapContext)
            }
        }
        tool?.draw(layer: .aboveTrackMap, ctx: mapContext)

        if let map = map {
            map.trains.forEach { $0.draw(ctx: mapContext) }
            map.containers.forEach { $0.draw(ctx: mapContext) }
        }
        tool?.draw(layer: .aboveTrains, ctx: mapContext)

        if showScale {
            drawScale()
        }
        if showCompass {
            drawCompass()
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

    private static let scaleHeight = 16.0

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

        context.setFillColor(backgroundColor)
        context.move(to: CGPoint(x: bounds.maxX - totalWidth, y: 0.0))
        context.addLine(to: CGPoint(x: bounds.maxX - totalWidth, y: MapView.scaleHeight - 4.0))
        context.addArc(
            center: CGPoint(x: bounds.maxX - totalWidth + 4.0, y: MapView.scaleHeight - 4.0),
            radius: 4.0,
            startAngle: CGFloat.pi,
            endAngle: 0.5 * CGFloat.pi,
            clockwise: true)
        context.addLine(to: CGPoint(x: bounds.maxX, y: MapView.scaleHeight))
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

    private static let compassRadius = 20.0

    private func compassCenter() -> CGPoint {
        CGPoint(
            x: bounds.maxX - MapView.compassRadius - 4.0,
            y: bounds.minY + MapView.compassRadius + 4.0 + (showScale ? MapView.scaleHeight : 0.0))
    }

    private func drawCompass() {
        context.saveGState()

        let northColor: CGColor
        let southColor: CGColor
        let tickColor: CGColor
        let backgroundColor: CGColor
        switch style {
        case .light:
            northColor = CGColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            southColor = CGColor(gray: 0.7, alpha: 1.0)
            tickColor = CGColor.black
            backgroundColor = CGColor.white
        case .dark:
            northColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            southColor = CGColor(gray: 0.8, alpha: 1.0)
            tickColor = CGColor.white
            backgroundColor = CGColor.black
        }

        let center = compassCenter()

        context.setFillColor(backgroundColor)
        context.fillEllipse(
            in: CGRect(
                x: center.x - MapView.compassRadius,
                y: center.y - MapView.compassRadius,
                width: 2.0 * MapView.compassRadius,
                height: 2.0 * MapView.compassRadius))

        context.setStrokeColor(tickColor)
        context.setLineWidth(0.5)
        let totalTicks = 12
        for i in 1..<totalTicks {
            let a =
                mapCGRotation + 0.5 * CGFloat.pi + CGFloat(i) * 2.0 * CGFloat.pi
                / CGFloat(totalTicks)
            let p1 = CGPoint(
                x: center.x + cos(a) * 0.5 * MapView.compassRadius,
                y: center.y + sin(a) * 0.5 * MapView.compassRadius)
            let p2 = CGPoint(
                x: center.x + cos(a) * 0.9 * MapView.compassRadius,
                y: center.y + sin(a) * 0.9 * MapView.compassRadius)
            context.move(to: p1)
            context.addLine(to: p2)
            context.strokePath()
        }

        let p1 = CGPoint(
            x: center.x + cos(mapCGRotation + 0.5 * CGFloat.pi) * 0.95 * MapView.compassRadius,
            y: center.y + sin(mapCGRotation + 0.5 * CGFloat.pi) * 0.95 * MapView.compassRadius)
        let p2 = CGPoint(
            x: center.x + cos(mapCGRotation) * 0.2 * MapView.compassRadius,
            y: center.y + sin(mapCGRotation) * 0.2 * MapView.compassRadius)
        let p3 = CGPoint(
            x: center.x + cos(mapCGRotation + CGFloat.pi) * 0.2 * MapView.compassRadius,
            y: center.y + sin(mapCGRotation + CGFloat.pi) * 0.2 * MapView.compassRadius)
        let p4 = CGPoint(
            x: center.x + cos(mapCGRotation + 1.5 * CGFloat.pi) * 0.95 * MapView.compassRadius,
            y: center.y + sin(mapCGRotation + 1.5 * CGFloat.pi) * 0.95 * MapView.compassRadius)

        context.setFillColor(northColor)
        context.move(to: p1)
        context.addLine(to: p2)
        context.addLine(to: p3)
        context.fillPath()

        context.setFillColor(southColor)
        context.move(to: p4)
        context.addLine(to: p2)
        context.addLine(to: p3)
        context.fillPath()

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
