//
//  TrackMap+Time.swift
//  Tracks
//
//  Created by Arne Philipeit on 9/15/24.
//

import Base
import Foundation

extension TrackMap {
    public func tick(_ delta: Duration) {
        for connection in self.connections {
            connection.tick(delta)
        }
        for signal in self.signals {
            signal.tick(delta)
        }
    }
}
