//
//  TrainDispatcherWindowController.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/2/23.
//

import Base
import Cocoa
import Foundation
import Trains

class TrainDispatcherWindowController: NSWindowController,
    NSSplitViewDelegate,
    MapViewDelegate,
    PanelSelectorDelegate,
    TrainObserver
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
    private enum MapPanelAndTrainPanelSelectionState {
        case mapPanel, statsPanel, controlsPanel
    }
    private enum OptionPanelsState: Equatable {
        case mapPanelOnly
        case mapPanelAndToolPanel(ToolPanel, MapPanelAndToolPanelSelectionState)
        case mapPanelAndTrainPanel(Train, MapPanelAndTrainPanelSelectionState)

        static func == (lhs: OptionPanelsState, rhs: OptionPanelsState) -> Bool {
            switch (lhs, rhs) {
            case (.mapPanelOnly, .mapPanelOnly):
                true
            case (.mapPanelAndToolPanel(let lp, let ls), .mapPanelAndToolPanel(let rp, let rs)):
                lp == rp && ls == rs
            case (.mapPanelAndTrainPanel(let lt, let ls), .mapPanelAndTrainPanel(let rt, let rs)):
                lt === rt && ls == rs
            default:
                false
            }
        }
    }
    private var optionPanelsState: OptionPanelsState = .mapPanelOnly {
        willSet {
            switch optionPanelsState {
            case .mapPanelOnly:
                break
            case .mapPanelAndToolPanel(_, _):
                break
            case .mapPanelAndTrainPanel(let train, _):
                train.remove(observer: self)
            }
        }
        didSet {
            guard oldValue != optionPanelsState else { return }
            optionsPanelSelector?.optionsChanged()
            switch optionPanelsState {
            case .mapPanelOnly:
                selectedOptionsPanel = mapOptionsPanel
            case .mapPanelAndToolPanel(let toolPanel, let selection):
                selectedOptionsPanel =
                    switch (toolPanel, selection) {
                    case (_, .mapPanel):
                        mapOptionsPanel
                    case (.groundBrush, .toolPanel):
                        groundBrushOptionsPanel
                    }
            case .mapPanelAndTrainPanel(let train, let selection):
                train.add(observer: self)
                updateTrainStats()
                updateTrainControls()
                selectedOptionsPanel =
                    switch selection {
                    case .mapPanel:
                        mapOptionsPanel
                    case .statsPanel:
                        trainStatsPanel
                    case .controlsPanel:
                        trainControlsPanel
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

    // MARK: Train Stats Panel
    @IBOutlet var trainStatsPanel: NSView?
    @IBOutlet var trainStatsCameraTrackingButton: NSButton?
    @IBOutlet var trainLengthLabel: NSTextField?
    @IBOutlet var trainWagonsLabel: NSTextField?
    @IBOutlet var trainWeightLabel: NSTextField?
    @IBOutlet var trainAccelerationForceLabel: NSTextField?
    @IBOutlet var trainBrakeForceLabel: NSTextField?
    @IBOutlet var trainMaxSpeedLabel: NSTextField?

    private func updateTrainStats() {
        switch optionPanelsState {
        case .mapPanelAndTrainPanel(let train, _):
            trainStatsCameraTrackingButton?.state =
                switch mapView?.camera {
                case .trackingTrain(let trackedTrain):
                    train === trackedTrain ? .on : .off
                default:
                    .off
                }
            trainLengthLabel?.stringValue = train.length.description
            trainWagonsLabel?.stringValue = train.vehicles.count.description
            trainWeightLabel?.stringValue = train.weight.description
            trainAccelerationForceLabel?.stringValue = train.maxAccelerationForce.description
            trainBrakeForceLabel?.stringValue = train.maxBrakeForce.description
            trainMaxSpeedLabel?.stringValue = train.maxSpeed.description
        default:
            break
        }
    }

    @IBAction func trainCameraTrackingButtonChanged(_ sender: AnyObject) {
        guard
            let train: Train =
                switch optionPanelsState {
                case .mapPanelOnly: nil
                case .mapPanelAndToolPanel(_, _): nil
                case .mapPanelAndTrainPanel(let train, _): train
                }
        else { return }
        if (sender as? NSButton)?.state == .on {
            mapView?.camera = .trackingTrain(train)
        } else {
            mapView?.camera = .free
        }
    }

    // MARK: - Train Controls Panel
    @IBOutlet var trainControlsPanel: NSView?
    @IBOutlet var trainControlsCameraTrackingButton: NSButton?
    @IBOutlet var trainDirectionModeSegmentedControl: NSSegmentedControl?
    @IBOutlet var trainSpeedLabel: NSTextField?
    @IBOutlet var trainAcceleratorSlider: NSSlider?
    @IBOutlet var trainBrakeSlider: NSSlider?

    private func updateTrainControls() {
        switch optionPanelsState {
        case .mapPanelAndTrainPanel(let train, _):
            trainSpeedLabel?.stringValue = abs(train.speed).description
            trainDirectionModeSegmentedControl?.isEnabled = train.speed == 0.0.mps
            trainDirectionModeSegmentedControl?.selectedSegment =
                switch train.direction {
                case .forward:
                    2
                case .neutral:
                    1
                case .backward:
                    0
                }
            trainAcceleratorSlider?.isEnabled = train.direction != .neutral
            trainAcceleratorSlider?.doubleValue =
                train.accelerationForce / train.maxAccelerationForce * 100.0
            trainBrakeSlider?.isEnabled = train.direction != .neutral
            trainBrakeSlider?.doubleValue = train.brakeForce / train.maxBrakeForce * 100.0
        default:
            break
        }
    }

    @IBAction private func trainDirectionModeSegmentedControlChanged(_ sender: AnyObject) {
        guard
            let train: Train =
                switch optionPanelsState {
                case .mapPanelOnly: nil
                case .mapPanelAndToolPanel(_, _): nil
                case .mapPanelAndTrainPanel(let train, _): train
                }
        else { return }
        if trainDirectionModeSegmentedControl?.selectedSegment == 0 {
            train.direction = .backward
        } else if trainDirectionModeSegmentedControl?.selectedSegment == 1 {
            train.direction = .neutral
        } else if trainDirectionModeSegmentedControl?.selectedSegment == 2 {
            train.direction = .forward
        } else {
            assertionFailure("unexpected train direction segmented control index")
        }
    }

    @IBAction private func trainAcceleratorSliderChanged(_ sender: AnyObject) {
        guard
            let train: Train =
                switch optionPanelsState {
                case .mapPanelOnly: nil
                case .mapPanelAndToolPanel(_, _): nil
                case .mapPanelAndTrainPanel(let train, _): train
                }
        else { return }
        if let p = trainAcceleratorSlider?.doubleValue {
            train.accelerationForce = train.maxAccelerationForce * p / 100.0
        }
    }

    @IBAction private func trainBrakeSliderChanged(_ sender: AnyObject) {
        guard
            let train: Train =
                switch optionPanelsState {
                case .mapPanelOnly: nil
                case .mapPanelAndToolPanel(_, _): nil
                case .mapPanelAndTrainPanel(let train, _): train
                }
        else { return }
        if let p = trainBrakeSlider?.doubleValue {
            train.brakeForce = train.maxBrakeForce * p / 100.0
        }
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
    func cameraChanged() {
        switch optionPanelsState {
        case .mapPanelAndTrainPanel(let train, _):
            let state: NSControl.StateValue =
                switch mapView?.camera {
                case .trackingTrain(let trackedTrain):
                    train === trackedTrain ? .on : .off
                default:
                    .off
                }
            trainStatsCameraTrackingButton?.state = state
            trainControlsCameraTrackingButton?.state = state
        default:
            break
        }
    }

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

    func selectedTrain(train: Train) {
        optionPanelsState = .mapPanelAndTrainPanel(train, .controlsPanel)
    }

    // MARK: - PanelSelectorDelegate
    func optionsCount(for panelSelector: PanelSelector) -> Int {
        switch optionPanelsState {
        case .mapPanelOnly: 1
        case .mapPanelAndToolPanel(_, _): 2
        case .mapPanelAndTrainPanel(_, _): 3
        }
    }

    func image(forOptionAtIndex index: Int, for panelSelector: PanelSelector) -> NSImage {
        let image =
            switch optionPanelsState {
            case .mapPanelOnly:
                NSImage(
                    systemSymbolName: "map.fill", variableValue: 0.0, accessibilityDescription: nil)!
            case .mapPanelAndToolPanel(let toolPanel, _):
                switch (toolPanel, index) {
                case (.groundBrush, 1):
                    NSImage(systemSymbolName: "paintbrush.fill", accessibilityDescription: nil)!
                case (_, _):
                    NSImage(systemSymbolName: "map.fill", accessibilityDescription: nil)!
                }
            case .mapPanelAndTrainPanel(_, _):
                if index == 1 {
                    NSImage(
                        systemSymbolName: "list.bullet.clipboard.fill",
                        accessibilityDescription: nil)!
                } else if index == 2 {
                    NSImage(
                        systemSymbolName: "arcade.stick.and.arrow.up.and.arrow.down",
                        accessibilityDescription: nil)!
                } else {
                    NSImage(systemSymbolName: "map.fill", accessibilityDescription: nil)!
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
        case .mapPanelAndTrainPanel(_, let selection):
            switch selection {
            case .mapPanel: 0
            case .statsPanel: 1
            case .controlsPanel: 2
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
        case .mapPanelAndTrainPanel(let train, _):
            if index == 0 {
                optionPanelsState = .mapPanelAndTrainPanel(train, .mapPanel)
            } else if index == 1 {
                optionPanelsState = .mapPanelAndTrainPanel(train, .statsPanel)
            } else if index == 2 {
                optionPanelsState = .mapPanelAndTrainPanel(train, .controlsPanel)
            } else {
                assertionFailure("Unexpected selected panel index.")
            }
        }
    }

    // MARK: - TrainObserver
    func speedChanged(_ train: Train) {
        updateTrainControls()
    }

    func directionChanged(_ train: Train) {
        updateTrainControls()
    }

    func accelerationForceChanged(_ train: Train) {
        updateTrainControls()
    }

    func brakeForceChanged(_ train: Train) {
        updateTrainControls()
    }

}
