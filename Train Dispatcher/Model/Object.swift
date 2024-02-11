//
//  Object.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Foundation

struct ObjectPosition: Codable {
    let center: Point
    let orientation: CircleAngle
    
    var forward: Angle { orientation.asAngle }
    var left: Angle { orientation + 90.0.deg }
    var right: Angle { orientation - 90.0.deg }
    var backward: Angle { orientation + 180.deg }
}

protocol Object: Codable, Drawable {
    var objectPosition: ObjectPosition { get }
}
