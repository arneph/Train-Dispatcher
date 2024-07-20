//
//  Color.swift
//  Base
//
//  Created by Arne Philipeit on 4/27/24.
//

import CoreGraphics
import Foundation

public struct Color: Equatable, Hashable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    public var cgColor: CGColor {
        CGColor(
            srgbRed: Float64(red) / 255.0,
            green: Float64(green) / 255.0,
            blue: Float64(blue) / 255.0,
            alpha: Float64(alpha) / 255.0)
    }

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(from cgColor: CGColor) {
        let rgb = cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: CGColorRenderingIntent.defaultIntent,
            options: nil)!
        self.red = UInt8(rgb.components![0] * 255.0)
        self.green = UInt8(rgb.components![1] * 255.0)
        self.blue = UInt8(rgb.components![2] * 255.0)
        self.alpha = UInt8(rgb.components![3] * 255.0)
    }

    public var description: String { "(r: \(red), g: \(green), b:\(blue), a: \(alpha))" }
    public var debugDescription: String { "(r: \(red), g: \(green), b:\(blue), a: \(alpha))" }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }

    public static let white = Color(red: 255, green: 255, blue: 255, alpha: 255)
    public static let black = Color(red: 0, green: 0, blue: 0, alpha: 255)
    public static let transparent = Color(red: 255, green: 255, blue: 255, alpha: 0)
}
