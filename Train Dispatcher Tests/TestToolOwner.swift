//
//  TestToolOwner.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 3/26/24.
//

import Base
import Foundation
import Trains

@testable import Train_Dispatcher

final class TestToolOwner: TestViewContext, ToolOwner {
    enum Call: Equatable {
        case stateChanged(Tool)
        case selectTrain(Train)

        static func == (lhs: TestToolOwner.Call, rhs: TestToolOwner.Call) -> Bool {
            switch (lhs, rhs) {
            case (.stateChanged(let lt), .stateChanged(let rt)):
                lt === rt
            case (.selectTrain(let lt), .stateChanged(let rt)):
                lt === rt
            default:
                false
            }
        }
    }
    var calls: [Call] = []
    let map: Map?
    let changeManager: ChangeManager?

    init(mapPointAtViewCenter: Point, mapScale: CGFloat, map: Map, changeManager: ChangeManager) {
        self.map = map
        self.changeManager = changeManager
        super.init(mapPointAtViewCenter: mapPointAtViewCenter, mapScale: mapScale)
    }

    func stateChanged(tool: Tool) {
        calls.append(.stateChanged(tool))
    }

    func selectTrain(train: Train) {
        calls.append(.selectTrain(train))
    }
}
