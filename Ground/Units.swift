//
//  Units.swift
//  Ground
//
//  Created by Arne Philipeit on 6/2/24.
//

import Base
import Foundation

private let pixelWidth = 0.2.m

struct PixelPoint {
    let x: Int
    let y: Int
}

func toPoint(_ pixelPoint: PixelPoint) -> Point {
    Point(x: pixelPoint.x * pixelWidth, y: pixelPoint.y * pixelWidth)
}

func toPixelPoint(_ point: Point) -> PixelPoint {
    PixelPoint(
        x: Int((point.x / pixelWidth).rounded(.down)),
        y: Int((point.y / pixelWidth).rounded(.down)))
}

struct PixelSize {
    let width: Int
    let height: Int
}

func toSize(_ pixelSize: PixelSize) -> Size {
    Size(width: pixelSize.width * pixelWidth, height: pixelSize.height * pixelWidth)
}

struct PixelRect {
    let origin: PixelPoint
    let size: PixelSize

    var min: PixelPoint { origin }
    var max: PixelPoint {
        PixelPoint(
            x: origin.x + size.width,
            y: origin.y + size.height)
    }
}

func toRect(_ pixelRect: PixelRect) -> Rect {
    Rect(origin: toPoint(pixelRect.origin), size: toSize(pixelRect.size))
}

func toPixelRect(_ rect: Rect) -> PixelRect {
    let min = toPixelPoint(rect.minXY)
    let max = toPixelPoint(rect.maxXY)
    return PixelRect(
        origin: min,
        size: PixelSize(
            width: max.x - min.x + 1,
            height: max.y - min.y + 1))
}

struct ChunkID: Codable, Equatable, Hashable {
    let x: Int
    let y: Int
}

private let chunkWidthBits = 12
private let chunkHeightBits = 12
let chunkSize = PixelSize(width: 1 << chunkWidthBits, height: 1 << chunkHeightBits)
let chunkPixelCount = chunkSize.width * chunkSize.height

private let chunkWidthMask = ~((1 << chunkWidthBits) - 1)
private let chunkHeightMask = ~((1 << chunkHeightBits) - 1)

func toPixelRect(_ id: ChunkID) -> PixelRect {
    PixelRect(
        origin: PixelPoint(
            x: id.x * chunkSize.width,
            y: id.y * chunkSize.height),
        size: chunkSize)
}

func toRect(_ chunkID: ChunkID) -> Rect {
    toRect(toPixelRect(chunkID))
}

func toChunkID(_ pixelPoint: PixelPoint) -> ChunkID {
    ChunkID(
        x: (pixelPoint.x & chunkWidthMask) / chunkSize.width,
        y: (pixelPoint.y & chunkHeightMask) / chunkSize.height)
}

struct ChunkIDs {
    let min: ChunkID
    let max: ChunkID

    func forEach(_ f: (ChunkID) -> Void) {
        for x in min.x...max.x {
            for y in min.y...max.y {
                f(ChunkID(x: x, y: y))
            }
        }
    }

    func map<T>(_ f: (ChunkID) -> T) -> [T] {
        var results: [T] = []
        forEach { (chunkID) in
            results.append(f(chunkID))
        }
        return results
    }

}

func toPixelRect(_ ids: ChunkIDs) -> PixelRect {
    PixelRect(
        origin: PixelPoint(
            x: ids.min.x * chunkSize.width,
            y: ids.min.y * chunkSize.height),
        size: PixelSize(
            width: (ids.max.x - ids.min.x + 1) * chunkSize.width,
            height: (ids.max.y - ids.min.y + 1) * chunkSize.height))
}

func toChunkIDs(_ pixelRect: PixelRect) -> ChunkIDs {
    ChunkIDs(min: toChunkID(pixelRect.min), max: toChunkID(pixelRect.max))
}

func toChunkIDs(_ rect: Rect) -> ChunkIDs {
    toChunkIDs(toPixelRect(rect))
}
