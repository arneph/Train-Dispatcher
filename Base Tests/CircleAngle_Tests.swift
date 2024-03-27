//
//  CircleAngle_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/31/24.
//

import XCTest

@testable import Base

final class CircleAngle_Tests: XCTestCase {

    func testClampsValue() {
        XCTAssertEqual(CircleAngle(0.0.deg).asAngle, 0.0.deg)
        XCTAssertEqual(CircleAngle(+180.0.deg).asAngle, -180.0.deg)
        XCTAssertEqual(CircleAngle(-180.0.deg).asAngle, -180.0.deg)
        XCTAssertEqual(CircleAngle(+360.0.deg).asAngle, 0.0.deg)
        XCTAssertEqual(CircleAngle(-360.0.deg).asAngle, 0.0.deg)
        XCTAssertEqual(CircleAngle(+30.0.deg).asAngle, +30.0.deg)
        XCTAssertEqual(CircleAngle(-30.0.deg).asAngle, -30.0.deg)
        XCTAssertEqual(CircleAngle(+150.0.deg).asAngle, +150.0.deg)
        XCTAssertEqual(CircleAngle(-150.0.deg).asAngle, -150.0.deg)
        XCTAssertEqual(CircleAngle(+200.0.deg).asAngle, -160.0.deg)
        XCTAssertEqual(CircleAngle(-200.0.deg).asAngle, +160.0.deg)
        XCTAssertEqual(CircleAngle(+300.0.deg).asAngle, -60.0.deg)
        XCTAssertEqual(CircleAngle(-300.0.deg).asAngle, +60.0.deg)
        XCTAssertEqual(CircleAngle(+400.0.deg).asAngle, +40.0.deg)
        XCTAssertEqual(CircleAngle(-400.0.deg).asAngle, -40.0.deg)
        XCTAssertEqual(CircleAngle(+500.0.deg).asAngle, +140.0.deg)
        XCTAssertEqual(CircleAngle(-500.0.deg).asAngle, -140.0.deg)
        XCTAssertEqual(CircleAngle(+600.0.deg).asAngle, -120.0.deg)
        XCTAssertEqual(CircleAngle(-600.0.deg).asAngle, +120.0.deg)
    }

    func testComputesCorrectAbsDiff() {
        XCTAssertEqual(absDiff(CircleAngle(0.0.deg), CircleAngle(0.0.deg)), 0.0.deg)
        XCTAssertEqual(absDiff(CircleAngle(0.0.deg), CircleAngle(10.0.deg)), 10.0.deg)
        XCTAssertEqual(absDiff(CircleAngle(10.0.deg), CircleAngle(0.0.deg)), 10.0.deg)
        XCTAssertEqual(absDiff(CircleAngle(+175.0.deg), CircleAngle(-175.0.deg)), 10.0.deg)
        XCTAssertEqual(absDiff(CircleAngle(-175.0.deg), CircleAngle(+175.0.deg)), 10.0.deg)
        XCTAssertEqual(absDiff(CircleAngle(+175.0.deg), CircleAngle(+175.0.deg)), 0.0.deg)
        XCTAssertEqual(absDiff(CircleAngle(-175.0.deg), CircleAngle(-175.0.deg)), 0.0.deg)
    }

}

final class CircleRange_Tests: XCTestCase {

    func testFlipsCorrectly() {
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(0.0.deg), delta: +90.0.deg
            ).flipped, CircleRange(start: CircleAngle(90.0.deg), delta: -90.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(90.0.deg), delta: -90.0.deg
            ).flipped, CircleRange(start: CircleAngle(0.0.deg), delta: +90.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+120.0.deg), delta: +80.0.deg
            ).flipped, CircleRange(start: CircleAngle(-160.0.deg), delta: -80.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-160.0.deg), delta: -80.0.deg
            ).flipped, CircleRange(start: CircleAngle(+120.0.deg), delta: +80.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-120.0.deg), delta: +80.0.deg
            ).flipped, CircleRange(start: CircleAngle(-40.0.deg), delta: -80.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-40.0.deg), delta: -80.0.deg
            ).flipped, CircleRange(start: CircleAngle(-120.0.deg), delta: +80.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-90.0.deg), delta: -70.0.deg
            ).flipped, CircleRange(start: CircleAngle(-160.0.deg), delta: +70.0.deg))
    }

    func testReturnsCorrectOppositeExtent() {
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+0.0.deg), delta: +90.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+90.0.deg), delta: +270.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+0.0.deg), delta: -90.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(-90.0.deg), delta: -270.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+30.0.deg), delta: +40.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+70.0.deg), delta: +320.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-30.0.deg), delta: -40.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(-70.0.deg), delta: -320.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+30.0.deg), delta: -40.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(-10.0.deg), delta: -320.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-30.0.deg), delta: +40.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+10.0.deg), delta: +320.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: +25.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(-165.0.deg), delta: +335.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: -25.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+145.0.deg), delta: -335.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: -25.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+165.0.deg), delta: -335.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: +25.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(-145.0.deg), delta: +335.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+30.0.deg), delta: 0.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+30.0.deg), delta: +360.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+30.0.deg), delta: +360.0.deg
            ).withOppositeExtent, CircleRange(start: CircleAngle(+30.0.deg), delta: +0.0.deg))
    }

    func testDeterminesCorrectContainment() {
        XCTAssert(
            CircleRange(
                start: CircleAngle(0.0.deg), delta: +90.0.deg
            ).contains(CircleAngle(0.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(0.0.deg), delta: +90.0.deg
            ).contains(CircleAngle(+30.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(0.0.deg), delta: +90.0.deg
            ).contains(CircleAngle(+90.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(0.0.deg), delta: +90.0.deg
            ).contains(CircleAngle(+100.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(0.0.deg), delta: +90.0.deg
            ).contains(CircleAngle(-10.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(-30.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(0.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(+30.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(+100.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(+150.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(+160.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(-60.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(-120.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(-50.0.deg), delta: +200.0.deg
            ).contains(CircleAngle(-180.0.deg)))

        XCTAssert(
            CircleRange(
                start: CircleAngle(+90.0.deg), delta: -90.0.deg
            ).contains(CircleAngle(0.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+90.0.deg), delta: -90.0.deg
            ).contains(CircleAngle(+30.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+90.0.deg), delta: -90.0.deg
            ).contains(CircleAngle(+90.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(+90.0.deg), delta: -90.0.deg
            ).contains(CircleAngle(+100.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(+90.0.deg), delta: -90.0.deg
            ).contains(CircleAngle(-10.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(+30.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(0.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(-30.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(-100.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(-150.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(-180.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(-160.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(+60.0.deg)))
        XCTAssertFalse(
            CircleRange(
                start: CircleAngle(+50.0.deg), delta: -200.0.deg
            ).contains(CircleAngle(+120.0.deg)))

        XCTAssert(
            CircleRange(
                start: CircleAngle(140.0.deg), delta: +100.0.deg
            ).contains(CircleAngle(+140.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(140.0.deg), delta: +100.0.deg
            ).contains(CircleAngle(+170.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(140.0.deg), delta: +100.0.deg
            ).contains(CircleAngle(-170.0.deg)))
        XCTAssert(
            CircleRange(
                start: CircleAngle(140.0.deg), delta: +100.0.deg
            ).contains(CircleAngle(-120.0.deg)))
    }

    func testCalculatesCorrectFractions() {
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(10.0.deg)), 0.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(17.0.deg)), 0.35, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(30.0.deg)), 1.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(45.0.deg)), 1.75, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(5.0.deg)), 17.75, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(10.0.deg)), 0.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(7.0.deg)), 0.15, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(-10.0.deg)), 1.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(-25.0.deg)), 1.75, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(10.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(+15.0.deg)), 17.75, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(-170.0.deg)), 0.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(+180.0.deg)), 0.5, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(+170.0.deg)), 1.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(+160.0.deg)), 1.5, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-170.0.deg), delta: -20.0.deg
            ).fraction(for: CircleAngle(-160.0.deg)), 17.5, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(+170.0.deg)), 0.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(+180.0.deg)), 0.5, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(-170.0.deg)), 1.0, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(-160.0.deg)), 1.5, accuracy: 1e-9)
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+170.0.deg), delta: +20.0.deg
            ).fraction(for: CircleAngle(+160.0.deg)), 17.5, accuracy: 1e-9)
    }

    func testDeterminesCorrectDelta() {
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(0.0.deg), end: CircleAngle(0.0.deg), direction: .positive),
            CircleRange(start: CircleAngle(0.0.deg), delta: 0.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(0.0.deg), end: CircleAngle(0.0.deg), direction: .negative),
            CircleRange(start: CircleAngle(0.0.deg), delta: 0.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(0.0.deg), end: CircleAngle(90.0.deg), direction: .positive),
            CircleRange(start: CircleAngle(0.0.deg), delta: +90.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(0.0.deg), end: CircleAngle(90.0.deg), direction: .negative),
            CircleRange(start: CircleAngle(0.0.deg), delta: -270.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+50.0.deg), end: CircleAngle(-150.0.deg), direction: .positive),
            CircleRange(start: CircleAngle(+50.0.deg), delta: +160.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(+50.0.deg), end: CircleAngle(-150.0.deg), direction: .negative),
            CircleRange(start: CircleAngle(+50.0.deg), delta: -200.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-50.0.deg), end: CircleAngle(+150.0.deg), direction: .positive),
            CircleRange(start: CircleAngle(-50.0.deg), delta: +200.0.deg))
        XCTAssertEqual(
            CircleRange(
                start: CircleAngle(-50.0.deg), end: CircleAngle(+150.0.deg), direction: .negative),
            CircleRange(start: CircleAngle(-50.0.deg), delta: -160.0.deg))
    }

}
