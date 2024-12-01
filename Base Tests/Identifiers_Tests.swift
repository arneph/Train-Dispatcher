//
//  Identifiers_Tests.swift
//  Base Tests
//
//  Created by Arne Philipeit on 12/1/24.
//

import XCTest

@testable import Base

final class IDGenerator_Tests: XCTestCase {

    class TestType {}

    func testGeneratesUniqueIDs() {
        let generator = IDGenerator<TestType>()
        let ids = (0...7).map { _ in generator.new() }
        for i in ids.indices {
            for j in ids.indices {
                if i == j {
                    XCTAssertEqual(ids[i], ids[j])
                } else {
                    XCTAssertNotEqual(ids[i], ids[j])
                }
            }
        }
    }

    func testEncodesAndDecodes() throws {
        let originalGenerator = IDGenerator<TestType>()
        let originalIDs = (0...7).map { _ in originalGenerator.new() }
        let encoder = JSONEncoder()
        let encodedGenerator = try encoder.encode(originalGenerator)
        let encodedIDs = try encoder.encode(originalIDs)
        let decoder = JSONDecoder()
        let decodedGenerator = try decoder.decode(
            IDGenerator<TestType>.self,
            from: encodedGenerator)
        let decodedIDs = try decoder.decode(
            [ID<TestType>].self,
            from: encodedIDs)
        XCTAssertEqual(originalGenerator, decodedGenerator)
        XCTAssertEqual(originalIDs, decodedIDs)
        for i in decodedIDs.indices {
            for j in decodedIDs.indices {
                if i == j {
                    XCTAssertEqual(decodedIDs[i], decodedIDs[j])
                } else {
                    XCTAssertNotEqual(decodedIDs[i], decodedIDs[j])
                }
            }
        }
        let additionalIDs = (0...3).map { _ in decodedGenerator.new() }
        XCTAssertNotEqual(originalGenerator, decodedGenerator)
        for i in decodedIDs.indices {
            for j in additionalIDs.indices {
                XCTAssertNotEqual(originalIDs[i], additionalIDs[j])
                XCTAssertNotEqual(decodedIDs[i], additionalIDs[j])
            }
        }
        for i in additionalIDs.indices {
            for j in additionalIDs.indices {
                if i == j {
                    XCTAssertEqual(additionalIDs[i], additionalIDs[j])
                } else {
                    XCTAssertNotEqual(additionalIDs[i], additionalIDs[j])
                }
            }
        }
    }

}

final class IDSet_Tests: XCTestCase {

    final class TestType: IDObject, Codable {
        let id: ID<TestType>

        init(id: ID<TestType>) {
            self.id = id
        }
    }

    func testHandlesAdditionsAndRemovals() {
        let generator = IDGenerator<TestType>()
        var set = IDSet<TestType>()

        XCTAssert(set.isEmpty)
        XCTAssertEqual(set.count, 0)

        let objectA = TestType(id: generator.new())

        XCTAssertNil(set[objectA.id])
        XCTAssertFalse(set.contains(objectA.id))
        XCTAssertFalse(set.contains(objectA))

        set.add(objectA)

        XCTAssertFalse(set.isEmpty)
        XCTAssertEqual(set.count, 1)
        XCTAssert(set.elements[0] === objectA)
        XCTAssert(set[objectA.id] === objectA)
        XCTAssert(set.contains(objectA.id))
        XCTAssert(set.contains(objectA))

        let objectB = TestType(id: generator.new())

        XCTAssertNil(set[objectB.id])
        XCTAssertFalse(set.contains(objectB.id))
        XCTAssertFalse(set.contains(objectB))

        set.add(objectB)

        XCTAssertFalse(set.isEmpty)
        XCTAssertEqual(set.count, 2)
        XCTAssert(set.elements[0] === objectA)
        XCTAssert(set.elements[1] === objectB)
        XCTAssert(set[objectA.id] === objectA)
        XCTAssert(set.contains(objectA.id))
        XCTAssert(set.contains(objectA))
        XCTAssert(set[objectB.id] === objectB)
        XCTAssert(set.contains(objectB.id))
        XCTAssert(set.contains(objectB))

        let objectC = TestType(id: generator.new())
        let objectD = TestType(id: generator.new())
        let objectE = TestType(id: generator.new())

        for newObject in [objectC, objectD, objectE] {
            XCTAssertNil(set[newObject.id])
            XCTAssertFalse(set.contains(newObject.id))
            XCTAssertFalse(set.contains(newObject))
        }

        set.add([objectC, objectD, objectE])

        XCTAssertFalse(set.isEmpty)
        XCTAssertEqual(set.count, 5)
        for (i, object) in [objectA, objectB, objectC, objectD, objectE].enumerated() {
            XCTAssert(set.elements[i] === object)
            XCTAssert(set[object.id] === object)
            XCTAssert(set.contains(object.id))
            XCTAssert(set.contains(object))
        }

        set.remove(objectD)

        XCTAssertFalse(set.isEmpty)
        XCTAssertEqual(set.count, 4)
        XCTAssertNil(set[objectD.id])
        XCTAssertFalse(set.contains(objectD.id))
        XCTAssertFalse(set.contains(objectD))
        for (i, object) in [objectA, objectB, objectC, objectE].enumerated() {
            XCTAssert(set.elements[i] === object)
            XCTAssert(set[object.id] === object)
            XCTAssert(set.contains(object.id))
            XCTAssert(set.contains(object))
        }

        set.remove([objectA, objectC])

        XCTAssertFalse(set.isEmpty)
        XCTAssertEqual(set.count, 2)
        for object in [objectA, objectC, objectD] {
            XCTAssertNil(set[object.id])
            XCTAssertFalse(set.contains(object.id))
            XCTAssertFalse(set.contains(object))
        }
        for (i, object) in [objectB, objectE].enumerated() {
            XCTAssert(set.elements[i] === object)
            XCTAssert(set[object.id] === object)
            XCTAssert(set.contains(object.id))
            XCTAssert(set.contains(object))
        }

        set.remove([objectB, objectE])

        XCTAssert(set.isEmpty)
        XCTAssertEqual(set.count, 0)
        for object in [objectA, objectB, objectC, objectD, objectE] {
            XCTAssertNil(set[object.id])
            XCTAssertFalse(set.contains(object.id))
            XCTAssertFalse(set.contains(object))
        }
    }

    func testDistinguishesObjectsWithSameIDs() throws {
        let generator = IDGenerator<TestType>()
        let originalObject = TestType(id: generator.new())
        let encoder = JSONEncoder()
        let encodedObject = try encoder.encode(originalObject)
        let decoder = JSONDecoder()
        let decodedObject = try decoder.decode(TestType.self, from: encodedObject)
        let otherObject = TestType(id: generator.new())

        XCTAssertEqual(originalObject.id, decodedObject.id)
        XCTAssertNotEqual(originalObject.id, otherObject.id)

        let set = IDSet<TestType>([otherObject, originalObject])

        XCTAssertEqual(set.count, 2)
        XCTAssert(set.elements[0] === otherObject)
        XCTAssert(set[otherObject.id] === otherObject)
        XCTAssert(set.contains(otherObject.id))
        XCTAssert(set.contains(otherObject))
        XCTAssert(set.elements[1] === originalObject)
        XCTAssert(set[originalObject.id] === originalObject)
        XCTAssert(set.contains(originalObject.id))
        XCTAssert(set.contains(originalObject))

        XCTAssertFalse(set.elements[1] === decodedObject)
        XCTAssert(set.contains(decodedObject.id))
        XCTAssertFalse(set.contains(decodedObject))
    }

}

final class IDMap_Tests: XCTestCase {

    final class TestType: IDObject, Codable {
        let id: ID<TestType>

        init(id: ID<TestType>) {
            self.id = id
        }
    }

    func testHandlesInsertionsAndRemovals() {
        let generator = IDGenerator<TestType>()
        var map = IDMap<TestType, String>()

        XCTAssert(map.isEmpty)
        XCTAssertEqual(map.count, 0)

        let objectA = TestType(id: generator.new())

        XCTAssertNil(map[objectA.id])
        XCTAssertNil(map[objectA])
        XCTAssertFalse(map.contains(objectA.id))
        XCTAssertFalse(map.contains(objectA))

        map.insert(key: objectA, value: "Object A1")

        XCTAssertFalse(map.isEmpty)
        XCTAssertEqual(map.count, 1)
        XCTAssert(map.keys[0] === objectA)
        XCTAssert(map.values[0] == "Object A1")
        XCTAssert(map[objectA.id] == "Object A1")
        XCTAssert(map[objectA] == "Object A1")
        XCTAssert(map.contains(objectA.id))
        XCTAssert(map.contains(objectA))

        let objectB = TestType(id: generator.new())

        XCTAssertNil(map[objectB.id])
        XCTAssertNil(map[objectB])
        XCTAssertFalse(map.contains(objectB.id))
        XCTAssertFalse(map.contains(objectB))

        map[objectB] = "Object B"

        XCTAssertFalse(map.isEmpty)
        XCTAssertEqual(map.count, 2)
        XCTAssert(map.keys[0] === objectA)
        XCTAssert(map.values[0] == "Object A1")
        XCTAssert(map[objectA.id] == "Object A1")
        XCTAssert(map[objectA] == "Object A1")
        XCTAssert(map.contains(objectA.id))
        XCTAssert(map.contains(objectA))
        XCTAssert(map.keys[1] === objectB)
        XCTAssert(map.values[1] == "Object B")
        XCTAssert(map[objectB.id] == "Object B")
        XCTAssert(map[objectB] == "Object B")
        XCTAssert(map.contains(objectB.id))
        XCTAssert(map.contains(objectB))

        map[objectA] = "Object A2"

        XCTAssertFalse(map.isEmpty)
        XCTAssertEqual(map.count, 2)
        XCTAssert(map.keys[0] === objectA)
        XCTAssert(map.values[0] == "Object A2")
        XCTAssert(map[objectA.id] == "Object A2")
        XCTAssert(map[objectA] == "Object A2")
        XCTAssert(map.contains(objectA.id))
        XCTAssert(map.contains(objectA))
        XCTAssert(map.keys[1] === objectB)
        XCTAssert(map.values[1] == "Object B")
        XCTAssert(map[objectB.id] == "Object B")
        XCTAssert(map[objectB] == "Object B")
        XCTAssert(map.contains(objectB.id))
        XCTAssert(map.contains(objectB))

        map.removeValue(forID: objectA.id)

        XCTAssertFalse(map.isEmpty)
        XCTAssertEqual(map.count, 1)
        XCTAssert(map.keys[0] === objectB)
        XCTAssert(map.values[0] == "Object B")
        XCTAssert(map[objectB.id] == "Object B")
        XCTAssert(map[objectB] == "Object B")
        XCTAssert(map.contains(objectB.id))
        XCTAssert(map.contains(objectB))
        XCTAssertNil(map[objectA.id])
        XCTAssertNil(map[objectA])
        XCTAssertFalse(map.contains(objectA.id))
        XCTAssertFalse(map.contains(objectA))

        map.removeValue(forKey: objectB)

        XCTAssert(map.isEmpty)
        XCTAssertEqual(map.count, 0)
        XCTAssertNil(map[objectA.id])
        XCTAssertNil(map[objectA])
        XCTAssertFalse(map.contains(objectA.id))
        XCTAssertFalse(map.contains(objectA))
        XCTAssertNil(map[objectB.id])
        XCTAssertNil(map[objectB])
        XCTAssertFalse(map.contains(objectB.id))
        XCTAssertFalse(map.contains(objectB))
    }

    func testDistinguishesObjectsWithSameIDs() throws {
        let generator = IDGenerator<TestType>()
        let originalObject = TestType(id: generator.new())
        let encoder = JSONEncoder()
        let encodedObject = try encoder.encode(originalObject)
        let decoder = JSONDecoder()
        let decodedObject = try decoder.decode(TestType.self, from: encodedObject)
        let otherObject = TestType(id: generator.new())

        XCTAssertEqual(originalObject.id, decodedObject.id)
        XCTAssertNotEqual(originalObject.id, otherObject.id)

        var map = IDMap<TestType, String>()
        map[otherObject] = "Other object"
        map[originalObject] = "Original object"

        XCTAssertEqual(map.count, 2)
        XCTAssert(map.keys[0] === otherObject)
        XCTAssert(map.values[0] == "Other object")
        XCTAssert(map[otherObject.id] == "Other object")
        XCTAssert(map[otherObject] == "Other object")
        XCTAssert(map.contains(otherObject.id))
        XCTAssert(map.contains(otherObject))
        XCTAssert(map.keys[1] === originalObject)
        XCTAssert(map.values[1] == "Original object")
        XCTAssert(map[originalObject.id] == "Original object")
        XCTAssert(map[originalObject] == "Original object")
        XCTAssert(map.contains(originalObject.id))
        XCTAssert(map.contains(originalObject))

        XCTAssertFalse(map.keys[1] === decodedObject)
        XCTAssertNil(map[decodedObject])
        XCTAssert(map.contains(decodedObject.id))
        XCTAssertFalse(map.contains(decodedObject))
    }

}
