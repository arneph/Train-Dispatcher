//
//  Units.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation

protocol Unit {
    static func toString(_: Float64) -> String
}
struct Radians: Unit {
    static func toString(_ v: Float64) -> String {
        String(format: "%.1f°", v / Float64.pi * 180.0)
    }
}
struct Seconds: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.1fs", v) }
}
struct Seconds²: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.1fs²", v) }
}
struct Seconds³: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.1fs³", v) }
}
struct Meters: Unit {
    static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fkm", v / 1000.0) : String(format: "%.2fm", v)
    }
}
struct Meters² : Unit {
    static func toString(_ v: Float64) -> String {
        abs(v) >= 1000000.0 ? String(format: "%.1fkm²", v / 1000000.0) : String(format: "%.2fm²", v)
    }
}
struct Meters³: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.2fm³", v) }
}
struct Meters⁴: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.2fm⁴", v) }
}
struct MetersPerSecond: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.0fkm/h", v * 3.6) }
}
struct Meters²PerSecond²: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.2fm²/s²", v) }
}
struct MetersPerSecond²: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.2fkm/h/s", v * 3.6) }
}
struct MetersPerSecond³: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.2fkm/h/s²", v * 3.6) }
}
struct Seconds²PerMeter: Unit {
    static func toString(_ v: Float64) -> String { String(format: "%.2fs²/m", v) }
}
struct Newtons: Unit {
    static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fkN", v / 1000.0) : String(format: "%.2fN", v)
    }
}
struct NewtonsPerSecond: Unit {
    static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fkN/s", v / 1000.0) : String(format: "%.2fN/s", v)
    }
}
struct Kilograms: Unit {
    static func toString(_ v: Float64) -> String {
        abs(v) >= 1000.0 ? String(format: "%.1fT", v / 1000.0) : String(format: "%.0fkg", v)
    }
}

struct Quantity<T: Unit> : Equatable,
                           Hashable,
                           Comparable,
                           Codable,
                           CustomStringConvertible,
                           CustomDebugStringConvertible {
    fileprivate let value: Float64
    
    init(_ value: Int) {
        self.value = Float64(value)
    }
    
    init(_ value: Float64) {
        self.value = value
    }
    
    var withoutUnit: Float64 { value }
    
    prefix static func + (operand: Quantity<T>) -> Quantity<T> { operand }

    prefix static func - (operand: Quantity<T>) -> Quantity<T> {
        Quantity(-operand.value)
    }
    
    static func + (lhs: Quantity<T>, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(lhs.value + rhs.value)
    }
    
    static func - (lhs: Quantity<T>, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(lhs.value - rhs.value)
    }
    
    static func += (lhs: inout Quantity<T>, rhs: Quantity<T>) {
        lhs = lhs + rhs
    }
    
    static func -= (lhs: inout Quantity<T>, rhs: Quantity<T>) {
        lhs = lhs - rhs
    }
    
    static func * (lhs: Quantity<T>, rhs: Float64) -> Quantity<T> {
        Quantity<T>(lhs.value * rhs)
    }
    
    static func * (lhs: Quantity<T>, rhs: Int) -> Quantity<T> {
        Quantity<T>(lhs.value * Float64(rhs))
    }
    
    static func * (lhs: Float64, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(lhs * rhs.value)
    }
    
    static func * (lhs: Int, rhs: Quantity<T>) -> Quantity<T> {
        Quantity<T>(Float64(lhs) * rhs.value)
    }
    
    static func / (lhs: Quantity<T>, rhs: Quantity<T>) -> Float64 {
        lhs.value / rhs.value
    }
    
    static func / (lhs: Quantity<T>, rhs: Float64) -> Quantity<T> {
        Quantity<T>(lhs.value / rhs)
    }
    
    static func == (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        abs(lhs.value - rhs.value) <= 1e-9
    }
    static func != (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool {
        abs(lhs.value - rhs.value) > 1e-9
    }
    static func < (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool { lhs != rhs && lhs.value < rhs.value }
    static func <= (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool { lhs == rhs || lhs.value <= rhs.value }
    static func >= (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool { lhs == rhs || lhs.value >= rhs.value }
    static func > (lhs: Quantity<T>, rhs: Quantity<T>) -> Bool { lhs != rhs && lhs.value > rhs.value }
        
    var description: String { T.toString(value) }
    var debugDescription: String { T.toString(value) }
}

typealias Angle = Quantity<Radians>
typealias AngleDiff = Quantity<Radians>

typealias Time = Quantity<Seconds>
typealias Duration = Quantity<Seconds>

typealias Duration² = Quantity<Seconds²>
typealias Duration³ = Quantity<Seconds³>

typealias Position = Quantity<Meters>
typealias Distance = Quantity<Meters>

typealias Distance² = Quantity<Meters²>
typealias Distance³ = Quantity<Meters³>
typealias Distance⁴ = Quantity<Meters⁴>

typealias Speed = Quantity<MetersPerSecond>
typealias SpeedDiff = Quantity<MetersPerSecond>

typealias Speed² = Quantity<Meters²PerSecond²>

typealias Acceleration = Quantity<MetersPerSecond²>
typealias AccelerationDiff = Quantity<MetersPerSecond²>

typealias Acceleration⁻¹ = Quantity<Seconds²PerMeter>

typealias Jerk = Quantity<MetersPerSecond³>
typealias JerkDiff = Quantity<MetersPerSecond³>

typealias Force = Quantity<Newtons>
typealias ForceDiff = Quantity<Newtons>

typealias ForceChange = Quantity<NewtonsPerSecond>
typealias ForceChangeDiff = Quantity<NewtonsPerSecond>

typealias Mass = Quantity<Kilograms>

extension Double {
    var deg: Angle { Angle(self / 180.0 * Float64.pi) }
    var s: Duration { Duration(self) }
    var m: Distance { Distance(self) }
    var m²: Distance² { Distance²(self) }
    var m³: Distance³ { Distance³(self) }
    var m⁴: Distance⁴ { Distance⁴(self) }
}

func abs<T>(_ q: Quantity<T>) -> Quantity<T> {
    Quantity<T>(abs(q.value))
}

func min<T>(_ xs: Quantity<T>...) -> Quantity<T> {
    Quantity<T>(xs.map{ $0.value }.reduce(xs.first!.value, min))
}

func max<T>(_ xs: Quantity<T>...) -> Quantity<T> {
    Quantity<T>(xs.map{ $0.value }.reduce(xs.first!.value, max))
}

func cos(_ angle: Angle) -> Float64 {
    cos(angle.withoutUnit)
}

func sin(_ angle: Angle) -> Float64 {
    sin(angle.withoutUnit)
}

func absDiff(_ a: Angle, _ b: Angle) -> AngleDiff { abs(a - b) }

func pow²(_ d: Duration) -> Duration² {
    Duration²(pow(d.value, 2.0))
}

func pow²(_ d: Distance) -> Distance² {
    Distance²(pow(d.value, 2.0))
}

func pow²(_ d: Distance²) -> Distance⁴ {
    Distance⁴(pow(d.value, 2.0))
}

func pow³(_ d: Duration) -> Duration³ {
    Duration³(pow(d.value, 3.0))
}

func pow²(_ s: Speed) -> Speed² {
    Speed²(pow(s.value, 2.0))
}

func sqrt(_ d: Duration²) -> Duration {
    Duration(sqrt(d.value))
}

func sqrt(_ d: Distance²) -> Distance {
    Distance(sqrt(d.value))
}

func sqrt(_ d: Distance⁴) -> Distance² {
    Distance²(sqrt(d.value))
}

func sqrt(_ s: Speed²) -> Speed {
    Speed(sqrt(s.value))
}

func * (lhs: Distance, rhs: AngleDiff) -> Distance {
    Distance(lhs.value * rhs.value)
}

func * (lhs: AngleDiff, rhs: Distance) -> Distance {
    Distance(lhs.value * rhs.value)
}

func * (lhs: Distance, rhs: Distance) -> Distance² {
    Distance²(lhs.value * rhs.value)
}

func * (lhs: Distance², rhs: Distance) -> Distance³ {
    Distance³(lhs.value * rhs.value)
}

func * (lhs: Distance, rhs: Distance²) -> Distance³ {
    Distance³(lhs.value * rhs.value)
}

func * (lhs: Distance², rhs: Distance²) -> Distance⁴ {
    Distance⁴(lhs.value * rhs.value)
}

func * (lhs: Speed, rhs: Duration) -> Distance {
    Distance(lhs.value * rhs.value)
}

func * (lhs: Duration, rhs: Speed) -> Distance {
    Distance(lhs.value * rhs.value)
}

func * (lhs: Acceleration, rhs: Duration) -> Speed {
    Speed(lhs.value * rhs.value)
}

func * (lhs: Duration, rhs: Acceleration) -> Speed {
    Speed(lhs.value * rhs.value)
}

func * (lhs: Acceleration, rhs: Duration²) -> Distance {
    Distance(lhs.value * rhs.value)
}

func * (lhs: Duration², rhs: Acceleration) -> Distance {
    Distance(lhs.value * rhs.value)
}

func * (lhs: Acceleration, rhs: Distance) -> Speed² {
    Speed²(lhs.value * rhs.value)
}

func * (lhs: Distance, rhs: Acceleration) -> Speed² {
    Speed²(lhs.value * rhs.value)
}

func * (lhs: Acceleration⁻¹, rhs: Distance) -> Duration² {
    Duration²(lhs.value * rhs.value)
}

func * (lhs: Distance, rhs: Acceleration⁻¹) -> Duration² {
    Duration²(lhs.value * rhs.value)
}

func / (lhs: Duration², rhs: Duration) -> Duration {
    Duration(lhs.value / rhs.value)
}

func / (lhs: Duration³, rhs: Duration) -> Duration² {
    Duration²(lhs.value / rhs.value)
}

func / (lhs: Distance², rhs: Distance) -> Distance {
    Distance(lhs.value / rhs.value)
}

func / (lhs: Distance³, rhs: Distance²) -> Distance {
    Distance(lhs.value / rhs.value)
}

func / (lhs: Distance, rhs: Speed) -> Duration {
    Duration(lhs.value / rhs.value)
}

func / (lhs: Speed, rhs: Acceleration) -> Duration {
    Duration(lhs.value / rhs.value)
}

func / (lhs: Speed², rhs: Acceleration) -> Distance {
    Distance(lhs.value / rhs.value)
}

func / (lhs: Force, rhs: Mass) -> Acceleration {
    Acceleration(lhs.value / rhs.value)
}

func / (lhs: Force, rhs: ForceChange) -> Duration {
    Duration(lhs.value / rhs.value)
}

func / (lhs: Force, rhs: Duration) -> ForceChange {
    ForceChange(lhs.value / rhs.value)
}

func / (lhs: Float64, rhs: Acceleration) -> Acceleration⁻¹ {
    Acceleration⁻¹(lhs / rhs.value)
}

func / (lhs: Duration, rhs: Acceleration⁻¹) -> Speed {
    Speed(lhs.value / rhs.value)
}
