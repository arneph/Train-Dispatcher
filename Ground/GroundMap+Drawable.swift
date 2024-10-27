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

    public func draw(ctx: DrawContext) {
        ctx.saveGState()

        ctx.setFillColor(baseColor)
        ctx.fill(ctx.dirtyRect)

        forChunks(at: ctx.dirtyRect) { (id, chunk) in
            if !chunk.isEmptyImage {
                ctx.draw(chunk.image, in: toRect(id), byTiling: false)
            }
        }

        ctx.restoreGState()
    }

}
