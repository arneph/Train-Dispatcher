//
//  GroundMapObserver.swift
//  Ground
//
//  Created by Arne Philipeit on 6/2/24.
//

import Foundation

public protocol GroundMapObserver: AnyObject {
    func groundChanged(forMap map: GroundMap)
}

extension GroundMapObserver {
    func groundChanged(forMap map: GroundMap) {}
}
