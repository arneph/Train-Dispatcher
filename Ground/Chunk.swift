//
//  Chunk.swift
//  Ground
//
//  Created by Arne Philipeit on 6/2/24.
//

import Base
import CoreGraphics
import CoreImage
import Foundation
import ImageIO

extension PixelPoint {
    fileprivate var index: Int { self.x + self.y * chunkSize.width }
}

class Chunk: Codable {
    struct Pixels {
        private var pixels: [Color]

        func pixel(at point: PixelPoint) -> Color {
            pixels[point.index]
        }

        mutating func set(pixel: Color, at point: PixelPoint) {
            pixels[point.index] = pixel
        }

        fileprivate init(pixels: [Color]) {
            self.pixels = pixels
        }

        fileprivate static func from(image: CGImage) -> Pixels {
            let data = image.dataProvider!.data! as Data
            return Pixels(
                pixels: (0..<chunkPixelCount).map { (i) in
                    Color(
                        red: data[i * 4],
                        green: data[i * 4 + 1],
                        blue: data[i * 4 + 2],
                        alpha: data[i * 4 + 3])
                })
        }

        fileprivate func toImage() -> CGImage {
            let data = Data(pixels.flatMap { (c) in [c.red, c.green, c.blue, c.alpha] })
            let bitmapInfo = CGBitmapInfo(
                rawValue: CGImageAlphaInfo.last.rawValue | CGBitmapInfo.byteOrderDefault.rawValue)
            return CGImage(
                width: chunkSize.width,
                height: chunkSize.height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: 4 * chunkSize.width,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: bitmapInfo,
                provider: CGDataProvider(data: data as CFData)!,
                decode: nil,
                shouldInterpolate: false,
                intent: CGColorRenderingIntent.defaultIntent)!
        }
    }

    private(set) var image: CGImage

    func pixels() -> Pixels {
        Pixels.from(image: image)
    }

    func set(pixels: Pixels) {
        image = pixels.toImage()
    }

    init() {
        image = Pixels(
            pixels: [Color].init(
                repeating: Color.transparent,
                count: chunkPixelCount)
        ).toImage()
    }

    private enum CodingKeys: String, CodingKey {
        case imageData
    }

    required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try values.decode(Data.self, forKey: .imageData)
        self.image = CGImage(
            pngDataProviderSource: CGDataProvider(data: imageData as CFData)!,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent)!
    }

    func encode(to encoder: any Encoder) throws {
        let imageData = CFDataCreateMutable(nil, 0)!
        let destination = CGImageDestinationCreateWithData(
            imageData, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)

        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(imageData as Data, forKey: .imageData)
    }

}
