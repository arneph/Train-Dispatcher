//
//  Identifiers.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 3/6/24.
//

import Foundation
import OrderedCollections

public struct ID<T>: Equatable, Hashable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    private let id: UInt

    fileprivate init(id: UInt) {
        self.id = id
    }

    public var description: String { String(describing: type(of: self)) + "(" + String(id) + ")" }
    public var debugDescription: String {
        String(describing: type(of: self)) + "(" + String(id) + ")"
    }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }
}

public class IDGenerator<T>: Equatable, Codable {
    private var count: UInt = 0

    public func new() -> ID<T> {
        let id = count
        count += 1
        return ID<T>(id: id)
    }

    public static func == (lhs: IDGenerator<T>, rhs: IDGenerator<T>) -> Bool {
        lhs.count == rhs.count
    }

    public init() {}
}

public protocol IDObject {
    var id: ID<Self> { get }
}

public struct IDSet<T: IDObject> {
    private var map: OrderedDictionary<ID<T>, T> = [:]
    public var elements: [T] { map.values.elements }

    public subscript(id: ID<T>) -> T? { map[id] }

    public func contains(_ id: ID<T>) -> Bool { map.keys.contains(id) }
    public func contains(_ element: T) -> Bool { contains(element.id) }

    public mutating func add(_ element: T) {
        assert(!map.keys.contains(element.id))
        map[element.id] = element
    }

    public mutating func remove(_ id: ID<T>) {
        assert(map.keys.contains(id))
        map.removeValue(forKey: id)
    }

    public mutating func remove(_ element: T) {
        remove(element.id)
    }

    public init() {}
    public init(_ elements: [T]) {
        for element in elements {
            add(element)
        }
    }

}
