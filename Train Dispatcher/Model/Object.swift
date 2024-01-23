//
//  Object.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Foundation

struct ObjectPosition: Codable {
    let center: Point
    let orientation: Angle
    
    var forward: Angle { orientation }
    var left: Angle { orientation + 90.0.deg }
    var right: Angle { orientation - 90.0.deg }
    var backward: Angle { orientation + 180.deg }
}

protocol Object: Codable, CodeRepresentable, Drawable {
    var objectPosition: ObjectPosition { get }
}
