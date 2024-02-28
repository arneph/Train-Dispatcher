//
//  MapView.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation
import Cocoa
import CoreGraphics
import CoreText

protocol MapViewDelegate: AnyObject {
    var map: Map? { get }
}

class MapView: NSView, ToolOwner, ViewContext {
    var delegate: MapViewDelegate? {
        didSet {
            if oldValue !== delegate {
                needsDisplay = true
            }
        }
    }
    var map: Map { delegate?.map ?? Map() }
    
    // MARK: - Display State
    static let maxMapScale = 100.0
    static let minMapScale = 0.01
    
    var mapPointAtViewCenter: Point { Point(x: Position(mapCGPointAtViewCenter.x),
                                            y: Position(mapCGPointAtViewCenter.y)) }
    @objc dynamic var mapCGPointAtViewCenter: CGPoint = CGPoint(x: 0.0, y: 0.0) {
        didSet { needsDisplay = true }
    }
    @objc dynamic var mapScale: CGFloat = 10.0 {
        didSet {
            if (mapScale < MapView.minMapScale) {
                mapScale = MapView.minMapScale
            }
            if (mapScale > MapView.maxMapScale) {
                mapScale = MapView.maxMapScale
            }
            needsDisplay = true
        }
    }
    
    // MARK: - Tool
    private var tool: Tool? {
        didSet { needsDisplay = true }
    }
    
    func stateChanged(tool: Tool) {
        needsDisplay = true
    }
    
    // MARK: - init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        tool = TrackPen(owner: self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tool = TrackPen(owner: self)
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
        mapPointAtViewCenter + Point(x: Position((viewPoint.x - bounds.midX) / mapScale),
                                     y: Position((viewPoint.y - bounds.midY) / mapScale))
    }
    
    func toMapSize(viewSize: CGSize) -> Size {
        Size(width: Distance(viewSize.width / mapScale),
             height: Distance(viewSize.height / mapScale))
    }
    
    func toMapRect(viewRect: CGRect) -> Rect {
        Rect(orign: toMapPoint(viewPoint: viewRect.origin),
             size: toMapSize(viewSize: viewRect.size))
    }
    
    func toViewAngle(_ angle: Angle) -> CGFloat { angle.withoutUnit }
    
    func toViewDistance(_ distance: Distance) -> CGFloat {
        mapScale * distance.withoutUnit
    }
    
    func toViewPoint(_ mapPoint: Point) -> CGPoint {
        CGPoint(x: bounds.midX + mapScale * (mapPoint - mapPointAtViewCenter).x.withoutUnit,
                y: bounds.midY + mapScale * (mapPoint - mapPointAtViewCenter).y.withoutUnit)
    }
    
    func toViewSize(_ mapSize: Size) -> CGSize {
        CGSize(width: mapScale * mapSize.width.withoutUnit,
               height: mapScale * mapSize.height.withoutUnit)
    }
    
    func toViewRect(_ mapRect: Rect) -> CGRect {
        CGRect(origin: toViewPoint(mapRect.origin),
               size: toViewSize(mapRect.size))
    }
    
    // MARK: - Event handling
    override var acceptsFirstResponder: Bool { return true }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(toggleGrid(_:)):
            menuItem.state = showGrid ? .on : .off
            return true
        case #selector(toggleScale(_:)):
            menuItem.state = showScale ? .on : .off
            return true
        case #selector(zoomImageToActualSize(_:)):
            return true
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
        tool?.mouseDown(point: mapPoint)
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
            let delta = Direction(x: Distance(+event.scrollingDeltaX / mapScale),
                                  y: Distance(-event.scrollingDeltaY / mapScale))
            if event.modifierFlags.contains(.option) {
                let p = mapPointAtViewCenter + delta
                mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            } else {
                let p = mapPointAtViewCenter - delta
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
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSDownArrowFunctionKey)!), "s":
                let p = mapPointAtViewCenter - Direction(x: Distance(0.0), y: vOffset)
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSLeftArrowFunctionKey)!), "a":
                let p = mapPointAtViewCenter - Direction(x: hOffset, y: Distance(0.0))
                animator().mapCGPointAtViewCenter = CGPoint(x: p.x.withoutUnit, y: p.y.withoutUnit)
            case Character(UnicodeScalar(NSRightArrowFunctionKey)!), "d":
                let p = mapPointAtViewCenter + Direction(x: hOffset, y: Distance(0.0))
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
        let mapRect = toMapRect(viewRect: viewRect)
        
        if showGrid {
            drawGrid(mapRect)
        }
        
        map.trackMap.tracks.draw(context, self)
        map.vehicles.forEach{ $0.draw(context, self) }
        map.containers.forEach{ $0.draw(context, self) }
        tool?.draw(context, self)
        
        if showScale {
            drawScale()
        }
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
        let attributes: [NSAttributedString.Key : Any] = [.font: font, 
                                                          .foregroundColor: foregroundColor]
        let length = NSAttributedString(string: String(Int(gridScale)) + "m",
                                        attributes: attributes)
        let line = CTLineCreateWithAttributedString(length)
        let lengthWidth = CTLineGetImageBounds(line, context).width
        let measurementWidth = gridScale * mapScale
        let totalWidth = lengthWidth + measurementWidth + 12.0
        let totalHeight = 16.0
        
        context.setFillColor(backgroundColor)
        context.move(to: CGPoint(x: bounds.maxX - totalWidth, y: 0.0))
        context.addLine(to: CGPoint(x: bounds.maxX - totalWidth, y: totalHeight - 4.0))
        context.addArc(center: CGPoint(x: bounds.maxX - totalWidth + 4.0, y: totalHeight - 4.0),
                       radius: 4.0,
                       startAngle: CGFloat.pi,
                       endAngle: 0.5 * CGFloat.pi,
                       clockwise: true)
        context.addLine(to: CGPoint(x: bounds.maxX, y: totalHeight))
        context.addLine(to: CGPoint(x: bounds.maxX, y: 0.0))
        context.closePath()
        context.fillPath()
        
        context.textPosition = CGPoint(x: bounds.maxX - lengthWidth - measurementWidth - 8,
                                       y: bounds.minY + 4)
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
    
}
