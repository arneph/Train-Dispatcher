//
//  Object.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Foundation

public struct ObjectPosition: Codable {
    public let center: Point
    public let orientation: CircleAngle

    public var forward: Angle { orientation.asAngle }
    public var left: Angle { orientation + 90.0.deg }
    public var right: Angle { orientation - 90.0.deg }
    public var backward: Angle { orientation + 180.deg }

    public init(center: Point, orientation: CircleAngle) {
        self.center = center
        self.orientation = orientation
    }
}

public protocol Object: Codable, Drawable {
    var objectPosition: ObjectPosition { get }
}
