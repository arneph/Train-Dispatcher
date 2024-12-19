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

public protocol IDObject: AnyObject {
    var id: ID<Self> { get }
}

public struct IDSet<T: IDObject> {
    private var map: OrderedDictionary<ID<T>, T> = [:]
    public var elements: [T] { map.values.elements }
    public var isEmpty: Bool { map.isEmpty }
    public var count: Int { map.count }

    public subscript(id: ID<T>) -> T? { map[id] }

    public func contains(_ id: ID<T>) -> Bool { map.keys.contains(id) }
    public func contains(_ element: T) -> Bool { map[element.id] === element }

    public mutating func add(_ element: T) {
        precondition(!contains(element.id))
        precondition(!contains(element))
        map[element.id] = element
    }

    public mutating func add(_ elements: [T]) {
        elements.forEach { add($0) }
    }

    public mutating func remove(_ id: ID<T>) {
        precondition(map.keys.contains(id))
        map.removeValue(forKey: id)
    }

    public mutating func remove(_ element: T) {
        precondition(contains(element))
        remove(element.id)
    }

    public mutating func remove(_ elements: [T]) {
        elements.forEach { remove($0) }
    }

    public init() {}
    public init(_ elements: [T]) {
        for element in elements {
            add(element)
        }
    }

}

public struct IDMap<Key: IDObject, Value> {
    public struct Entry {
        public let key: Key
        public let value: Value
    }
    private var map: OrderedDictionary<ID<Key>, Entry> = [:]
    public var keys: [Key] { map.values.map { $0.key } }
    public var values: [Value] { map.values.map { $0.value } }
    public var entries: [Entry] { Array(map.values) }
    public var isEmpty: Bool { map.isEmpty }
    public var count: Int { map.count }

    public subscript(id: ID<Key>) -> Value? { map[id]?.value ?? nil }
    public subscript(key: Key) -> Value? {
        get {
            if let entry = map[key.id] {
                if entry.key === key { entry.value } else { nil }
            } else {
                nil
            }
        }
        set {
            precondition(newValue != nil)
            insert(key: key, value: newValue!)
        }
    }

    public func contains(_ id: ID<Key>) -> Bool { map.keys.contains(id) }
    public func contains(_ key: Key) -> Bool { map[key.id]?.key ?? nil === key }

    public mutating func insert(key: Key, value: Value) {
        precondition(!contains(key.id) || contains(key))
        map[key.id] = Entry(key: key, value: value)
    }

    public mutating func removeValue(forID id: ID<Key>) {
        precondition(contains(id))
        map.removeValue(forKey: id)
    }

    public mutating func removeValue(forKey key: Key) {
        precondition(contains(key))
        map.removeValue(forKey: key.id)
    }

    public init() {}

}
