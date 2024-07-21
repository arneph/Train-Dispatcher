//
//  GroundMap+Drawable.swift
//  Ground
//
//  Created by Arne Philipeit on 6/4/24.
//

import Base
import CoreGraphics
import Foundation

extension GroundMap: Drawable {

    public func draw(
        _ cgContext: CGContext,
        _ viewContext: any Base.ViewContext,
        _ dirtyRect: Rect
    ) {
        cgContext.saveGState()

        cgContext.setFillColor(baseColor.cgColor)
        cgContext.fill(viewContext.toViewRect(dirtyRect))

        forChunks(at: dirtyRect) { (id, chunk) in
            if !chunk.isEmptyImage {
                cgContext.draw(
                    chunk.image,
                    in: viewContext.toViewRect(toRect(id)),
                    byTiling: false)
            }
        }

        cgContext.restoreGState()
    }

}
