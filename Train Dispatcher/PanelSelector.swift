//
//  PanelSelector.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 5/12/24.
//

import Cocoa
import Foundation

@objc protocol PanelSelectorDelegate: AnyObject {
    func optionsCount(for panelSelector: PanelSelector) -> Int
    func image(forOptionAtIndex index: Int, for panelSelector: PanelSelector) -> NSImage

    func indexOfSelectedOption(for panelSelector: PanelSelector) -> Int
    func setIndexOfSelectedOption(_ index: Int, for panelSelector: PanelSelector)
}

class PanelSelector: NSView {
    @IBOutlet weak var delegate: PanelSelectorDelegate? {
        didSet {
            needsDisplay = true
        }
    }

    func optionsChanged() {
        needsDisplay = true
    }

    // MARK: - Helpers
    private struct PanelSelectionOption {
        let selected: Bool
        let image: NSImage
    }

    private var options: [PanelSelectionOption] {
        guard let delegate = delegate else { return [] }
        let selectedIndex = delegate.indexOfSelectedOption(for: self)
        return (0..<delegate.optionsCount(for: self)).map {
            PanelSelectionOption(
                selected: $0 == selectedIndex,
                image: delegate.image(forOptionAtIndex: $0, for: self))
        }
    }

    // MARK: - Positioning
    private func rect(forIndex index: Int, outOf count: Int) -> CGRect {
        let optionWidth = bounds.width / CGFloat(options.count)
        let xMin = ceil(optionWidth * CGFloat(index))
        let xMax = ceil(optionWidth * CGFloat(index + 1))
        return CGRect(x: xMin, y: 0.0, width: xMax - xMin, height: bounds.height)
    }

    // MARK: - Event Handling
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let optionsCount = delegate?.optionsCount(for: self) else { return }
        let p = convert(event.locationInWindow, from: nil)
        for index in 0..<optionsCount {
            let rect = rect(forIndex: index, outOf: options.count)
            if rect.contains(p) {
                delegate?.setIndexOfSelectedOption(index, for: self)
                return
            }
        }
    }

    // MARK: - Drawing
    var context: CGContext { NSGraphicsContext.current!.cgContext }

    override func draw(_ dirtyRect: NSRect) {
        context.saveGState()

        let options = options
        for (index, option) in options.enumerated() {
            let rect = rect(forIndex: index, outOf: options.count)
            if option.selected {
                context.setFillColor(NSColor.controlAccentColor.cgColor.copy(alpha: 0.5)!)
                context.fill(rect)
            }
            let rectRatio = rect.width / rect.height
            let imageRatio = option.image.size.width / option.image.size.height
            let imageRect: CGRect
            if rectRatio <= imageRatio {
                let imageScale = rect.width / option.image.size.width
                let imageHeight = option.image.size.height * imageScale
                let imageY = rect.minY + 0.5 * (rect.height - imageHeight)
                imageRect = CGRect(
                    x: rect.minX,
                    y: imageY,
                    width: rect.width,
                    height: imageHeight)
            } else {
                let imageScale = rect.height / option.image.size.height
                let imageWidth = option.image.size.width * imageScale
                let imageX = rect.minX + 0.5 * (rect.width - imageWidth)
                imageRect = CGRect(
                    x: imageX,
                    y: rect.minY,
                    width: imageWidth,
                    height: rect.height)
            }
            let cell = NSImageCell(imageCell: option.image)
            cell.draw(withFrame: imageRect.insetBy(dx: 3.0, dy: 3.0), in: self)
        }

        switch effectiveAppearance.name {
        case .darkAqua:
            context.setStrokeColor(CGColor.black)
        default:
            context.setStrokeColor(CGColor(gray: 0.7, alpha: 1.0))
        }
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: bounds.minX, y: bounds.minY + 0.5))
        context.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY + 0.5))
        context.strokePath()

        context.restoreGState()
    }

}
