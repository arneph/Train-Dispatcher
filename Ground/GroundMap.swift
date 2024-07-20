//
//  GroundMap.swift
//  Ground
//
//  Created by Arne Philipeit on 6/2/24.
//

import Base
import Foundation

public final class GroundMap {
    internal private(set) var observers: [GroundMapObserver] = []
    public func add(observer: GroundMapObserver) { observers.append(observer) }
    public func remove(observer: GroundMapObserver) { observers.removeAll { $0 === observer } }

    public var baseColor: Color = Color(red: 63, green: 127, blue: 31, alpha: 255) {
        didSet {
            observers.forEach { $0.groundChanged(forMap: self) }
        }
    }
    private(set) var chunks: [ChunkID: Chunk] = [:]

    private func chunk(at id: ChunkID) -> Chunk {
        if let chunk = chunks[id] {
            return chunk
        }
        let chunk = Chunk()
        chunks[id] = chunk
        return chunk
    }

    private func set(chunk: Chunk, at id: ChunkID) {
        chunks[id] = chunk
        observers.forEach { $0.groundChanged(forMap: self) }
    }

    func forChunks(at rect: Rect, _ f: (ChunkID, Chunk) -> Void) {
        toChunkIDs(rect).forEach { f($0, chunk(at: $0)) }
    }

    func updatePixels(in rect: Rect, _ f: (Point, Color) -> Color) {
        forChunks(at: rect) { (id, chunk) in
            let pixelRect = toPixelRect(rect)
            var pixels = chunk.pixels()
            for x in pixelRect.min.x..<pixelRect.max.x {
                for y in pixelRect.min.y..<pixelRect.max.y {
                    let pixelPoint = PixelPoint(x: x, y: y)
                    let oldColor = pixels.pixel(at: pixelPoint)
                    let newColor = f(toPoint(pixelPoint), oldColor)
                    pixels.set(pixel: newColor, at: pixelPoint)
                }
            }
            chunk.set(pixels: pixels)
        }
        observers.forEach { $0.groundChanged(forMap: self) }
    }

    public init() {}

    init(baseColor: Color, chunks: [ChunkID: Chunk]) {
        self.baseColor = baseColor
        self.chunks = chunks
    }

}
