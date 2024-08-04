//
//  Units.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation

public protocol Unit {
    static func toString(_: Float64) -> String
}
public struct Radians: Unit {
    public static func toString(_ v: Float64) -> String {
        String(format: "%.1f°", v / Float64.pi * 180.0)
    }
}
public struct Seconds: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.1fs", v) }
}
public struct Seconds²: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.1fs²", v) }
}
public struct Seconds³: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.1fs³", v) }
}
public struct Meters: Unit {
    public static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fkm", v / 1000.0) : String(format: "%.2fm", v)
    }
}
public struct Meters²: Unit {
    public static func toString(_ v: Float64) -> String {
        abs(v) >= 1000000.0 ? String(format: "%.1fkm²", v / 1000000.0) : String(format: "%.2fm²", v)
    }
}
public struct Meters³: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.2fm³", v) }
}
public struct Meters⁴: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.2fm⁴", v) }
}
public struct MetersPerSecond: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.0fkm/h", v * 3.6) }
}
public struct Meters²PerSecond²: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.2fm²/s²", v) }
}
public struct MetersPerSecond²: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.2fkm/h/s", v * 3.6) }
}
public struct MetersPerSecond³: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.2fkm/h/s²", v * 3.6) }
}
public struct Seconds²PerMeter: Unit {
    public static func toString(_ v: Float64) -> String { String(format: "%.2fs²/m", v) }
}
public struct Newtons: Unit {
    public static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fkN", v / 1000.0) : String(format: "%.2fN", v)
    }
}
public struct NewtonsPerSecond: Unit {
    public static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fkN/s", v / 1000.0) : String(format: "%.2fN/s", v)
    }
}
public struct Kilograms: Unit {
    public static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fT", v / 1000.0) : String(format: "%.0fkg", v)
    }
}

public struct Quantity<T: Unit>: Equatable, Hashable, Comparable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    fileprivate let value: Float64

    public init(_ value: Int) {
        self.value = Float64(value)
    }

    public init(_ value: Float64) {
        self.value = value
    }

    public var withoutUnit: Float64 { value }

    public prefix static func + (operand: Quantity<T>) -> Quantity<T> { operand }

    public prefix static func - (operand: Quantity<T>) -> Quantity<T> {
        Quantity(-operand.value)
    }

    public static func + (lhs: Quantity<T>, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(lhs.value + rhs.value)
    }

    public static func - (lhs: Quantity<T>, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(lhs.value - rhs.value)
    }

    public static func += (lhs: inout Quantity<T>, rhs: Quantity<T>) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout Quantity<T>, rhs: Quantity<T>) {
        lhs = lhs - rhs
    }

    public static func * (lhs: Quantity<T>, rhs: Float64) -> Quantity<T> {
        Quantity<T>(lhs.value * rhs)
    }

    public static func * (lhs: Quantity<T>, rhs: Int) -> Quantity<T> {
        Quantity<T>(lhs.value * Float64(rhs))
    }

    public static func * (lhs: Float64, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(lhs * rhs.value)
    }

    public static func * (lhs: Int, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(Float64(lhs) * rhs.value)
    }

    public static func / (lhs: Quantity<T>, rhs: Quantity<T>) -> Float64 {
        lhs.value / rhs.value
    }

    public static func / (lhs: Quantity<T>, rhs: Float64) -> Quantity<T> {
        Quantity<T>(lhs.value / rhs)
    }

    public static func % (lhs: Quantity<T>, rhs: Quantity<T>) -> Float64 {
        lhs.value.truncatingRemainder(dividingBy: rhs.value)
    }

    public static func % (lhs: Quantity<T>, rhs: Float64) -> Quantity<T> {
        Quantity<T>(lhs.value.truncatingRemainder(dividingBy: rhs))
    }

    public static func == (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        abs(lhs.value - rhs.value) <= 5e-8
    }
    public static func != (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        abs(lhs.value - rhs.value) > 5e-8
    }
    public static func < (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        lhs != rhs && lhs.value < rhs.value
    }
    public static func <= (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        lhs == rhs || lhs.value <= rhs.value
    }
    public static func >= (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        lhs == rhs || lhs.value >= rhs.value
    }
    public static func > (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        lhs != rhs && lhs.value > rhs.value
    }

    public var description: String { T.toString(value) }
    public var debugDescription: String { T.toString(value) }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }
}

public typealias Angle = Quantity<Radians>
public typealias AngleDiff = Quantity<Radians>

public typealias Time = Quantity<Seconds>
public typealias Duration = Quantity<Seconds>

public typealias Duration² = Quantity<Seconds²>
public typealias Duration³ = Quantity<Seconds³>

public typealias Position = Quantity<Meters>
public typealias Distance = Quantity<Meters>

public typealias Distance² = Quantity<Meters²>
public typealias Distance³ = Quantity<Meters³>
public typealias Distance⁴ = Quantity<Meters⁴>

public typealias Speed = Quantity<MetersPerSecond>
public typealias SpeedDiff = Quantity<MetersPerSecond>

public typealias Speed² = Quantity<Meters²PerSecond²>

public typealias Acceleration = Quantity<MetersPerSecond²>
public typealias AccelerationDiff = Quantity<MetersPerSecond²>

public typealias Acceleration⁻¹ = Quantity<Seconds²PerMeter>

public typealias Jerk = Quantity<MetersPerSecond³>
public typealias JerkDiff = Quantity<MetersPerSecond³>

public typealias Force = Quantity<Newtons>
public typealias ForceDiff = Quantity<Newtons>

public typealias ForceChange = Quantity<NewtonsPerSecond>
public typealias ForceChangeDiff = Quantity<NewtonsPerSecond>

public typealias Mass = Quantity<Kilograms>

extension Double {
    public var deg: Angle { Angle(self / 180.0 * Float64.pi) }
    public var s: Duration { Duration(self) }
    public var h: Duration { Duration(self * 3600.0) }
    public var m: Distance { Distance(self) }
    public var km: Distance { Distance(self * 1000.0) }
    public var m²: Distance² { Distance²(self) }
    public var m³: Distance³ { Distance³(self) }
    public var m⁴: Distance⁴ { Distance⁴(self) }
    public var mps: Speed { Speed(self) }
    public var kph: Speed { Speed(self / 3.6) }
}

extension Angle {
    var isHorizontal: Bool {
        abs((self / 180.0.deg).truncatingRemainder(dividingBy: 1.0)) < 1e-9
    }
    var isVertical: Bool {
        abs(((self - 90.0.deg) / 180.0.deg).truncatingRemainder(dividingBy: 1.0)) < 1e-9
    }
}

public func abs<T>(_ q: Quantity<T>) -> Quantity<T> {
    Quantity<T>(abs(q.value))
}

public func min<T>(_ xs: Quantity<T>...) -> Quantity<T> {
    Quantity<T>(xs.map { $0.value }.reduce(xs.first!.value, min))
}

public func min<T>(_ xs: [Quantity<T>]) -> Quantity<T> {
    Quantity<T>(xs.map { $0.value }.reduce(xs.first!.value, min))
}

public func max<T>(_ xs: Quantity<T>...) -> Quantity<T> {
    Quantity<T>(xs.map { $0.value }.reduce(xs.first!.value, max))
}

public func max<T>(_ xs: [Quantity<T>]) -> Quantity<T> {
    Quantity<T>(xs.map { $0.value }.reduce(xs.first!.value, max))
}

public func cos(_ angle: Angle) -> Float64 {
    cos(angle.withoutUnit)
}

public func sin(_ angle: Angle) -> Float64 {
    sin(angle.withoutUnit)
}

public func tan(_ angle: Angle) -> Float64 {
    tan(angle.withoutUnit)
}

public func absDiff(_ a: Angle, _ b: Angle) -> AngleDiff { abs(a - b) }

public func pow²(_ d: Duration) -> Duration² {
    Duration²(pow(d.value, 2.0))
}

public func pow²(_ d: Distance) -> Distance² {
    Distance²(pow(d.value, 2.0))
}

public func pow²(_ d: Distance²) -> Distance⁴ {
    Distance⁴(pow(d.value, 2.0))
}

public func pow³(_ d: Duration) -> Duration³ {
    Duration³(pow(d.value, 3.0))
}

public func pow²(_ s: Speed) -> Speed² {
    Speed²(pow(s.value, 2.0))
}

public func sqrt(_ d: Duration²) -> Duration {
    Duration(sqrt(d.value))
}

public func sqrt(_ d: Distance²) -> Distance {
    Distance(sqrt(d.value))
}

public func sqrt(_ d: Distance⁴) -> Distance² {
    Distance²(sqrt(d.value))
}

public func sqrt(_ s: Speed²) -> Speed {
    Speed(sqrt(s.value))
}

public func * (lhs: Distance, rhs: AngleDiff) -> Distance {
    Distance(lhs.value * rhs.value)
}

public func * (lhs: AngleDiff, rhs: Distance) -> Distance {
    Distance(lhs.value * rhs.value)
}

public func * (lhs: Distance, rhs: Distance) -> Distance² {
    Distance²(lhs.value * rhs.value)
}

public func * (lhs: Distance², rhs: Distance) -> Distance³ {
    Distance³(lhs.value * rhs.value)
}

public func * (lhs: Distance, rhs: Distance²) -> Distance³ {
    Distance³(lhs.value * rhs.value)
}

public func * (lhs: Distance², rhs: Distance²) -> Distance⁴ {
    Distance⁴(lhs.value * rhs.value)
}

public func * (lhs: Speed, rhs: Duration) -> Distance {
    Distance(lhs.value * rhs.value)
}

public func * (lhs: Duration, rhs: Speed) -> Distance {
    Distance(lhs.value * rhs.value)
}

public func * (lhs: Acceleration, rhs: Duration) -> Speed {
    Speed(lhs.value * rhs.value)
}

public func * (lhs: Duration, rhs: Acceleration) -> Speed {
    Speed(lhs.value * rhs.value)
}

public func * (lhs: Acceleration, rhs: Duration²) -> Distance {
    Distance(lhs.value * rhs.value)
}

public func * (lhs: Duration², rhs: Acceleration) -> Distance {
    Distance(lhs.value * rhs.value)
}

public func * (lhs: Acceleration, rhs: Distance) -> Speed² {
    Speed²(lhs.value * rhs.value)
}

public func * (lhs: Distance, rhs: Acceleration) -> Speed² {
    Speed²(lhs.value * rhs.value)
}

public func * (lhs: Acceleration⁻¹, rhs: Distance) -> Duration² {
    Duration²(lhs.value * rhs.value)
}

public func * (lhs: Distance, rhs: Acceleration⁻¹) -> Duration² {
    Duration²(lhs.value * rhs.value)
}

public func / (lhs: Duration², rhs: Duration) -> Duration {
    Duration(lhs.value / rhs.value)
}

public func / (lhs: Duration³, rhs: Duration) -> Duration² {
    Duration²(lhs.value / rhs.value)
}

public func / (lhs: Distance², rhs: Distance) -> Distance {
    Distance(lhs.value / rhs.value)
}

public func / (lhs: Distance³, rhs: Distance²) -> Distance {
    Distance(lhs.value / rhs.value)
}

public func / (lhs: Distance, rhs: Speed) -> Duration {
    Duration(lhs.value / rhs.value)
}

public func / (lhs: Speed, rhs: Acceleration) -> Duration {
    Duration(lhs.value / rhs.value)
}

public func / (lhs: Speed², rhs: Acceleration) -> Distance {
    Distance(lhs.value / rhs.value)
}

public func / (lhs: Force, rhs: Mass) -> Acceleration {
    Acceleration(lhs.value / rhs.value)
}

public func / (lhs: Force, rhs: ForceChange) -> Duration {
    Duration(lhs.value / rhs.value)
}

public func / (lhs: Force, rhs: Duration) -> ForceChange {
    ForceChange(lhs.value / rhs.value)
}

public func / (lhs: Float64, rhs: Acceleration) -> Acceleration⁻¹ {
    Acceleration⁻¹(lhs / rhs.value)
}

public func / (lhs: Duration, rhs: Acceleration⁻¹) -> Speed {
    Speed(lhs.value / rhs.value)
}
