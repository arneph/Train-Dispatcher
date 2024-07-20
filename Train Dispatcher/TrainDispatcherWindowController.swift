//
//  TrainDispatcherWindowController.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/2/23.
//

import Base
import Cocoa
import Foundation

class TrainDispatcherWindowController: NSWindowController,
    NSSplitViewDelegate,
    MapViewDelegate,
    PanelSelectorDelegate
{
    var trainDispatcherDocument: TrainDispatcherDocument? { document as? TrainDispatcherDocument }
    var map: Map? { trainDispatcherDocument?.map ?? nil }
    var changeManager: ChangeManager? { trainDispatcherDocument?.changeManager }

    // MARK: - Tools Pane
    @IBOutlet var cursorButton: NSButton?
    @IBOutlet var groundBrushButton: NSButton?
    @IBOutlet var treePlacerButton: NSButton?
    @IBOutlet var trackPenButton: NSButton?

    // MARK: - Map View Pane
    @IBOutlet var mapView: MapView?

    // MARK: - Options Pane
    @IBOutlet var optionsPane: NSView?
    @IBOutlet var optionsPanelSelector: PanelSelector?

    private enum ToolPanel {
        case groundBrush
    }
    private enum MapPanelAndToolPanelSelectionState {
        case mapPanel, toolPanel
    }
    private enum OptionPanelsState: Equatable {
        case mapPanelOnly
        case mapPanelAndToolPanel(ToolPanel, MapPanelAndToolPanelSelectionState)
    }
    private var optionPanelsState: OptionPanelsState = .mapPanelOnly {
        didSet {
            guard oldValue != optionPanelsState else { return }
            optionsPanelSelector?.optionsChanged()
            switch optionPanelsState {
            case .mapPanelOnly:
                selectedOptionsPanel = mapOptionsPanel
            case .mapPanelAndToolPanel(let toolPanel, let selection):
                switch (toolPanel, selection) {
                case (_, .mapPanel):
                    selectedOptionsPanel = mapOptionsPanel
                case (.groundBrush, .toolPanel):
                    selectedOptionsPanel = groundBrushOptionsPanel
                }
            }
        }
    }

    private var selectedOptionsPanel: NSView? {
        didSet {
            guard oldValue !== selectedOptionsPanel else { return }
            if let oldOptionsPanel = oldValue {
                oldOptionsPanel.removeFromSuperview()
            }
            if let newOptionsPanel = selectedOptionsPanel {
                newOptionsPanel.setFrameOrigin(CGPoint(x: 0.0, y: 0.0))
                newOptionsPanel.setFrameSize(
                    CGSize(
                        width: optionsPane!.bounds.size.width,
                        height: optionsPane!.bounds.size.height - optionsPanelSelector!.frame.height
                    ))
                newOptionsPanel.autoresizingMask =
                    NSView.AutoresizingMask(
                        rawValue: NSView.AutoresizingMask.width.rawValue
                            | NSView.AutoresizingMask.height.rawValue)
                optionsPane!.addSubview(newOptionsPanel)
            }
        }
    }

    // MARK: Map Options Panel
    @IBOutlet var mapOptionsPanel: NSView?
    @IBOutlet var baseColorWell: NSColorWell?

    @IBAction func baseColorChanged(_ sender: AnyObject) {
        map?.groundMap.baseColor = Color(from: baseColorWell!.color.cgColor)
    }

    // MARK: Ground Brush Options Panel
    @IBOutlet var groundBrushOptionsPanel: NSView?
    @IBOutlet var groundBrushColorWell: NSColorWell?
    @IBOutlet var groundBrushSizeField: NSTextField?
    @IBOutlet var groundBrushSizeStepper: NSStepper?

    @IBAction func groundBrushColorChanged(_ sender: AnyObject) {
        guard let groundBrush = mapView?.tool as? GroundBrush else { return }
        groundBrush.color = Color(from: groundBrushColorWell!.color.cgColor)
    }

    @IBAction func groundBrushSizeTextChanged(_ sender: AnyObject) {
        guard let groundBrush = mapView?.tool as? GroundBrush else { return }
        var text = groundBrushSizeField!.stringValue
        text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if text.hasSuffix("m") {
            text = String(text.dropLast())
            text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        if let number = Float64(text) {
            groundBrush.diameter = Distance(number)
        }
        groundBrushSizeField?.stringValue = groundBrush.diameter.description
        groundBrushSizeStepper?.doubleValue = groundBrush.diameter.withoutUnit
    }

    @IBAction func groundBrushSizeStepperChanged(_ sender: AnyObject) {
        guard let groundBrush = mapView?.tool as? GroundBrush else { return }
        groundBrush.diameter = Distance(groundBrushSizeStepper!.doubleValue)
        groundBrushSizeField?.stringValue = groundBrush.diameter.description
        groundBrushSizeStepper?.doubleValue = groundBrush.diameter.withoutUnit
    }

    // MARK: - NSWindowController subclass
    override func windowDidLoad() {
        mapView?.delegate = self
        selectedOptionsPanel = mapOptionsPanel
        if let map = map {
            baseColorWell?.color = NSColor(cgColor: map.groundMap.baseColor.cgColor)!
        }
    }

    // MARK: - NSSplitViewController
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        if subview === mapView {
            false
        } else if subview === optionsPane {
            true
        } else {
            false
        }
    }

    func splitView(
        _ splitView: NSSplitView,
        constrainSplitPosition proposedPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        if proposedPosition > splitView.bounds.width - 196.0 - splitView.dividerThickness {
            splitView.bounds.width - 196.0 - splitView.dividerThickness
        } else if proposedPosition < splitView.bounds.width - 300.0 - splitView.dividerThickness {
            splitView.bounds.width - 300.0 - splitView.dividerThickness
        } else if proposedPosition < 400.0 {
            400.0
        } else {
            proposedPosition
        }
    }

    func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        let deltaWidth = splitView.bounds.width - oldSize.width
        mapView!.setFrameOrigin(CGPoint(x: 0.0, y: 0.0))
        mapView!.setFrameSize(
            CGSize(
                width: mapView!.frame.width + deltaWidth,
                height: splitView.bounds.height))
        optionsPane!.setFrameOrigin(
            CGPoint(
                x: splitView.bounds.width - optionsPane!.frame.width,
                y: 0.0))
        optionsPane!.setFrameSize(
            CGSize(
                width: optionsPane!.frame.width,
                height: splitView.bounds.height))
    }

    // MARK: - MapViewDelegate
    func toolChanged() {
        let toolType = mapView?.tool?.type
        cursorButton?.state = toolType == .none ? .on : .off
        groundBrushButton?.state = toolType == .groundBrush ? .on : .off
        treePlacerButton?.state = toolType == .treePlacer ? .on : .off
        trackPenButton?.state = toolType == .trackPen ? .on : .off
        switch mapView?.tool?.type {
        case .none, .treePlacer, .trackPen:
            optionPanelsState = .mapPanelOnly
        case .groundBrush:
            optionPanelsState = .mapPanelAndToolPanel(.groundBrush, .toolPanel)
            let groundBrush = mapView!.tool as! GroundBrush
            groundBrushColorWell?.color = NSColor(cgColor: groundBrush.color.cgColor)!
            groundBrushSizeField?.stringValue = groundBrush.diameter.description
            groundBrushSizeStepper?.doubleValue = groundBrush.diameter.withoutUnit
        }
    }

    // MARK: - PanelSelectorDelegate
    func optionsCount(for panelSelector: PanelSelector) -> Int {
        switch optionPanelsState {
        case .mapPanelOnly: 1
        case .mapPanelAndToolPanel(_, _): 2
        }
    }

    func image(forOptionAtIndex index: Int, for panelSelector: PanelSelector) -> NSImage {
        let image =
            switch optionPanelsState {
            case .mapPanelOnly:
                NSImage(
                    systemSymbolName: "doc.fill", variableValue: 0.0, accessibilityDescription: nil)!
            case .mapPanelAndToolPanel(let toolPanel, _):
                switch (toolPanel, index) {
                case (.groundBrush, 1):
                    NSImage(systemSymbolName: "paintbrush.fill", accessibilityDescription: nil)!
                case (_, _):
                    NSImage(systemSymbolName: "doc.fill", accessibilityDescription: nil)!
                }
            }
        image.isTemplate = true
        return image
    }

    func indexOfSelectedOption(for panelSelector: PanelSelector) -> Int {
        switch optionPanelsState {
        case .mapPanelOnly:
            0
        case .mapPanelAndToolPanel(_, let selection):
            switch selection {
            case .mapPanel: 0
            case .toolPanel: 1
            }
        }
    }

    func setIndexOfSelectedOption(_ index: Int, for panelSelector: PanelSelector) {
        switch optionPanelsState {
        case .mapPanelOnly:
            return
        case .mapPanelAndToolPanel(let toolPanel, _):
            if index == 0 {
                optionPanelsState = .mapPanelAndToolPanel(toolPanel, .mapPanel)
            } else if index == 1 {
                optionPanelsState = .mapPanelAndToolPanel(toolPanel, .toolPanel)
            } else {
                assertionFailure("Unexpected selected panel index.")
            }
        }
    }

}
