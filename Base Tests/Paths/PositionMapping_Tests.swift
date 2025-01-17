//
//  PositionMapping_Tests.swift
//  Base Tests
//
//  Created by Arne Philipeit on 12/20/24.
//

import Base
import Testing

struct PositionMapping_Tests {

    @Test func mapsIdentically() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m)

        #expect(mapping.validOldRange == 0.0.m...12.3.m)
        #expect(mapping.validNewRange == 0.0.m...12.3.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == 0.0.m)
        #expect(mapping.newPosition(for: 1.2.m) == 1.2.m)
        #expect(mapping.newPosition(for: 12.3.m) == 12.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...12.3.m) == .full(0.0.m...12.3.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(0.0.m...1.2.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(1.2.m...2.3.m))
        #expect(mapping.newRange(for: 2.3.m...12.3.m) == .full(2.3.m...12.3.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(0.0.m...1.0.m))
        #expect(mapping.newRange(for: 11.3.m...13.3.m) == .partial(11.3.m...12.3.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(0.0.m...12.3.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shifts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shift(by: 7.0.m)

        #expect(mapping.validOldRange == 0.0.m...12.3.m)
        #expect(mapping.validNewRange == 7.0.m...19.3.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == 7.0.m)
        #expect(mapping.newPosition(for: 1.2.m) == 8.2.m)
        #expect(mapping.newPosition(for: 12.3.m) == 19.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...12.3.m) == .full(7.0.m...19.3.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(7.0.m...8.2.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(8.2.m...9.3.m))
        #expect(mapping.newRange(for: 2.3.m...12.3.m) == .full(9.3.m...19.3.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(7.0.m...8.0.m))
        #expect(mapping.newRange(for: 11.3.m...13.3.m) == .partial(18.3.m...19.3.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(7.0.m...19.3.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func inverts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).inverted

        #expect(mapping.validOldRange == 0.0.m...12.3.m)
        #expect(mapping.validNewRange == 0.0.m...12.3.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 0.0.m) == 12.3.m)
        #expect(mapping.newPosition(for: 1.2.m) == 11.1.m)
        #expect(mapping.newPosition(for: 12.3.m) == 0.0.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...12.3.m) == .full(0.0.m...12.3.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(11.1.m...12.3.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(10.0.m...11.1.m))
        #expect(mapping.newRange(for: 2.3.m...12.3.m) == .full(0.0.m...10.0.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(11.3.m...12.3.m))
        #expect(mapping.newRange(for: 11.3.m...13.3.m) == .partial(0.0.m...1.0.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(0.0.m...12.3.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shortensAtStart() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shortenAtStart(to: 5.0.m)

        #expect(mapping.validOldRange == 7.3.m...12.3.m)
        #expect(mapping.validNewRange == 7.3.m...12.3.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == nil)
        #expect(mapping.newPosition(for: 7.3.m) == 7.3.m)
        #expect(mapping.newPosition(for: 8.0.m) == 8.0.m)
        #expect(mapping.newPosition(for: 12.3.m) == 12.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 7.3.m...8.0.m) == .full(7.3.m...8.0.m))
        #expect(mapping.newRange(for: 8.0.m...12.3.m) == .full(8.0.m...12.3.m))
        #expect(mapping.newRange(for: 8.0.m...9.0.m) == .full(8.0.m...9.0.m))

        #expect(mapping.newRange(for: 7.0.m...8.0.m) == .partial(7.3.m...8.0.m))
        #expect(mapping.newRange(for: 12.0.m...13.0.m) == .partial(12.0.m...12.3.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(7.3.m...12.3.m))

        #expect(mapping.newRange(for: -2.0.m...7.0.m) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shortensAtEnd() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shortenAtEnd(to: 5.0.m)

        #expect(mapping.validOldRange == 0.0.m...5.0.m)
        #expect(mapping.validNewRange == 0.0.m...5.0.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == 0.0.m)
        #expect(mapping.newPosition(for: 1.2.m) == 1.2.m)
        #expect(mapping.newPosition(for: 5.0.m) == 5.0.m)
        #expect(mapping.newPosition(for: 12.3.m) == nil)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...5.0.m) == .full(0.0.m...5.0.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(0.0.m...1.2.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(1.2.m...2.3.m))
        #expect(mapping.newRange(for: 2.3.m...5.0.m) == .full(2.3.m...5.0.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(0.0.m...1.0.m))
        #expect(mapping.newRange(for: 4.0.m...6.0.m) == .partial(4.0.m...5.0.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(0.0.m...5.0.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func invertsAndShifts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).inverted.shift(by: -5.3.m)

        #expect(mapping.validOldRange == 0.0.m...12.3.m)
        #expect(mapping.validNewRange == -5.3.m...7.0.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 0.0.m) == 7.0.m)
        #expect(mapping.newPosition(for: 1.2.m) == 5.8.m)
        #expect(mapping.newPosition(for: 12.3.m) == -5.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...12.3.m) == .full(-5.3.m...7.0.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(5.8.m...7.0.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(4.7.m...5.8.m))
        #expect(mapping.newRange(for: 2.3.m...12.3.m) == .full(-5.3.m...4.7.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(6.0.m...7.0.m))
        #expect(mapping.newRange(for: 11.3.m...13.3.m) == .partial(-5.3.m...(-4.3.m)))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(-5.3.m...7.0.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shiftsAndInverts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shift(by: -5.3.m).inverted

        #expect(mapping.validOldRange == 0.0.m...12.3.m)
        #expect(mapping.validNewRange == -5.3.m...7.0.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 0.0.m) == 7.0.m)
        #expect(mapping.newPosition(for: 1.2.m) == 5.8.m)
        #expect(mapping.newPosition(for: 12.3.m) == -5.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...12.3.m) == .full(-5.3.m...7.0.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(5.8.m...7.0.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(4.7.m...5.8.m))
        #expect(mapping.newRange(for: 2.3.m...12.3.m) == .full(-5.3.m...4.7.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(6.0.m...7.0.m))
        #expect(mapping.newRange(for: 11.3.m...13.3.m) == .partial(-5.3.m...(-4.3.m)))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(-5.3.m...7.0.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shortensAtStartAndShifts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shortenAtStart(to: 5.0.m).shift(
            by: -4.0.m)

        #expect(mapping.validOldRange == 7.3.m...12.3.m)
        #expect(mapping.validNewRange == 3.3.m...8.3.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == nil)
        #expect(mapping.newPosition(for: 7.3.m) == 3.3.m)
        #expect(mapping.newPosition(for: 8.0.m) == 4.0.m)
        #expect(mapping.newPosition(for: 12.3.m) == 8.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 7.3.m...8.0.m) == .full(3.3.m...4.0.m))
        #expect(mapping.newRange(for: 8.0.m...12.3.m) == .full(4.0.m...8.3.m))
        #expect(mapping.newRange(for: 8.0.m...9.0.m) == .full(4.0.m...5.0.m))

        #expect(mapping.newRange(for: 7.0.m...8.0.m) == .partial(3.3.m...4.0.m))
        #expect(mapping.newRange(for: 12.0.m...13.0.m) == .partial(8.0.m...8.3.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(3.3.m...8.3.m))

        #expect(mapping.newRange(for: -2.0.m...7.0.m) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shiftsAndShortensAtStart() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shift(by: -4.0.m).shortenAtStart(
            to: 5.0.m)

        #expect(mapping.validOldRange == 7.3.m...12.3.m)
        #expect(mapping.validNewRange == 3.3.m...8.3.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == nil)
        #expect(mapping.newPosition(for: 7.3.m) == 3.3.m)
        #expect(mapping.newPosition(for: 8.0.m) == 4.0.m)
        #expect(mapping.newPosition(for: 12.3.m) == 8.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 7.3.m...8.0.m) == .full(3.3.m...4.0.m))
        #expect(mapping.newRange(for: 8.0.m...12.3.m) == .full(4.0.m...8.3.m))
        #expect(mapping.newRange(for: 8.0.m...9.0.m) == .full(4.0.m...5.0.m))

        #expect(mapping.newRange(for: 7.0.m...8.0.m) == .partial(3.3.m...4.0.m))
        #expect(mapping.newRange(for: 12.0.m...13.0.m) == .partial(8.0.m...8.3.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(3.3.m...8.3.m))

        #expect(mapping.newRange(for: -2.0.m...7.0.m) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func invertsAndShortensAtStart() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).inverted.shortenAtStart(to: 5.0.m)

        #expect(mapping.validOldRange == 0.0.m...5.0.m)
        #expect(mapping.validNewRange == 7.3.m...12.3.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 0.0.m) == 12.3.m)
        #expect(mapping.newPosition(for: 1.2.m) == 11.1.m)
        #expect(mapping.newPosition(for: 5.0.m) == 7.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...5.0.m) == .full(7.3.m...12.3.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(11.1.m...12.3.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(10.0.m...11.1.m))
        #expect(mapping.newRange(for: 2.3.m...5.0.m) == .full(7.3.m...10.0.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(11.3.m...12.3.m))
        #expect(mapping.newRange(for: 4.0.m...6.0.m) == .partial(7.3.m...8.3.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(7.3.m...12.3.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shortensAtStartAndInverts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shortenAtStart(to: 5.0.m).inverted

        #expect(mapping.validOldRange == 7.3.m...12.3.m)
        #expect(mapping.validNewRange == 7.3.m...12.3.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 0.0.m) == nil)
        #expect(mapping.newPosition(for: 7.3.m) == 12.3.m)
        #expect(mapping.newPosition(for: 8.0.m) == 11.6.m)
        #expect(mapping.newPosition(for: 12.3.m) == 7.3.m)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 7.3.m...8.0.m) == .full(11.6.m...12.3.m))
        #expect(mapping.newRange(for: 8.0.m...12.3.m) == .full(7.3.m...11.6.m))
        #expect(mapping.newRange(for: 8.0.m...9.0.m) == .full(10.6.m...11.6.m))

        #expect(mapping.newRange(for: 7.0.m...8.0.m) == .partial(11.6.m...12.3.m))
        #expect(mapping.newRange(for: 12.0.m...13.0.m) == .partial(7.3.m...7.6.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(7.3.m...12.3.m))

        #expect(mapping.newRange(for: -2.0.m...7.0.m) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func invertsAndShortensAtEnd() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).inverted.shortenAtEnd(to: 5.0.m)

        #expect(mapping.validOldRange == 7.3.m...12.3.m)
        #expect(mapping.validNewRange == 0.0.m...5.0.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 7.3.m) == 5.0.m)
        #expect(mapping.newPosition(for: 8.5.m) == 3.8.m)
        #expect(mapping.newPosition(for: 12.3.m) == 0.0.m)
        #expect(mapping.newPosition(for: 0.0.m) == nil)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 7.3.m...12.3.m) == .full(0.0.m...5.0.m))
        #expect(mapping.newRange(for: 7.3.m...8.5.m) == .full(3.8.m...5.0.m))
        #expect(mapping.newRange(for: 8.5.m...9.6.m) == .full(2.7.m...3.8.m))
        #expect(mapping.newRange(for: 9.6.m...12.3.m) == .full(0.0.m...2.7.m))

        #expect(mapping.newRange(for: 6.0.m...8.3.m) == .partial(4.0.m...5.0.m))
        #expect(mapping.newRange(for: 11.3.m...13.0.m) == .partial(0.0.m...1.0.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(0.0.m...5.0.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func shortensAtEndAndInverts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m).shortenAtEnd(to: 5.0.m).inverted

        #expect(mapping.validOldRange == 0.0.m...5.0.m)
        #expect(mapping.validNewRange == 0.0.m...5.0.m)
        #expect(mapping.direction == .negative)

        #expect(mapping.newPosition(for: 0.0.m) == 5.0.m)
        #expect(mapping.newPosition(for: 1.2.m) == 3.8.m)
        #expect(mapping.newPosition(for: 5.0.m) == 0.0.m)
        #expect(mapping.newPosition(for: 12.3.m) == nil)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...5.0.m) == .full(0.0.m...5.0.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(3.8.m...5.0.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(2.7.m...3.8.m))
        #expect(mapping.newRange(for: 2.3.m...5.0.m) == .full(0.0.m...2.7.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(4.0.m...5.0.m))
        #expect(mapping.newRange(for: 4.0.m...6.0.m) == .partial(0.0.m...1.0.m))
        #expect(mapping.newRange(for: -1.0.m...13.3.m) == .partial(0.0.m...5.0.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 13.0.m...14.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 12.3.m...13.0.m) == .none)
    }

    @Test func invertsShortensAtStartShiftsAndInverts() async throws {
        let mapping = PositionMapping(for: 0.0.m...12.3.m)
            .inverted
            .shortenAtStart(to: 5.0.m)
            .shift(by: 20.0.m)
            .inverted

        #expect(mapping.validOldRange == 0.0.m...5.0.m)
        #expect(mapping.validNewRange == 27.3.m...32.3.m)
        #expect(mapping.direction == .positive)

        #expect(mapping.newPosition(for: 0.0.m) == 27.3.m)
        #expect(mapping.newPosition(for: 1.2.m) == 28.5.m)
        #expect(mapping.newPosition(for: 5.0.m) == 32.3.m)
        #expect(mapping.newPosition(for: 12.3.m) == nil)
        #expect(mapping.newPosition(for: -1.0.m) == nil)
        #expect(mapping.newPosition(for: 13.0.m) == nil)

        #expect(mapping.newRange(for: 0.0.m...5.0.m) == .full(27.3.m...32.3.m))
        #expect(mapping.newRange(for: 0.0.m...1.2.m) == .full(27.3.m...28.5.m))
        #expect(mapping.newRange(for: 1.2.m...2.3.m) == .full(28.5.m...29.6.m))
        #expect(mapping.newRange(for: 2.3.m...5.0.m) == .full(29.6.m...32.3.m))

        #expect(mapping.newRange(for: -1.0.m...1.0.m) == .partial(27.3.m...28.3.m))
        #expect(mapping.newRange(for: 4.0.m...6.0.m) == .partial(31.3.m...32.3.m))
        #expect(mapping.newRange(for: -1.0.m...6.0.m) == .partial(27.3.m...32.3.m))

        #expect(mapping.newRange(for: -2.0.m...(-1.0.m)) == .none)
        #expect(mapping.newRange(for: 6.0.m...8.0.m) == .none)
        #expect(mapping.newRange(for: -1.0.m...0.0.m) == .none)
        #expect(mapping.newRange(for: 5.0.m...13.0.m) == .none)
    }

}

struct FinitePathAndPositionChange_Tests {

    @Test func reverses() async throws {
        let original = LinearPath(
            start: Point(x: 1.2.m, y: 1.2.m),
            end: Point(x: 2.3.m, y: 2.3.m))!
        let reverseWithMapping = original.withMapping.reverse
        let reverse = reverseWithMapping.path
        let mapping = reverseWithMapping.mapping

        #expect(reverse == original.reverse)
        for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
            let originalX = original.length * f
            let originalPoint = original.point(at: originalX)
            let reverseX = mapping.newPosition(for: originalX)
            if let reverseX = reverseX {
                let reversePoint = reverse.point(at: reverseX)
                #expect(originalPoint != nil)
                #expect(originalPoint == reversePoint)
            } else {
                #expect(originalPoint == nil)
            }
        }
    }

    @Test func splits() async throws {
        let original = LinearPath(
            start: Point(x: 1.2.m, y: 1.2.m),
            end: Point(x: 3.4.m, y: 3.4.m))!
        let (partAWithMapping, partBWithMapping) = original.withMapping.split(at: 0.7.m)!
        let partA = partAWithMapping.path
        let mappingA = partAWithMapping.mapping
        let partB = partBWithMapping.path
        let mappingB = partBWithMapping.mapping

        #expect(original.split(at: 0.7.m)! == (partA, partB))
        for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
            let originalX = original.length * f
            let originalPoint = original.point(at: originalX)
            let partAX = mappingA.newPosition(for: originalX)
            let partBX = mappingB.newPosition(for: originalX)
            if let partAX = partAX {
                let partAPoint = partA.point(at: partAX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partAPoint)
            }
            if let partBX = partBX {
                let partBPoint = partB.point(at: partBX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partBPoint)
            }
            if partAX == nil && partBX == nil {
                #expect(originalPoint == nil)
            }
        }
    }

    @Test func handlesImpossibleSplit() async throws {
        let original = LinearPath(
            start: Point(x: 1.2.m, y: 1.2.m),
            end: Point(x: 3.4.m, y: 3.4.m))!

        #expect(original.withMapping.split(at: 7.0.m) == nil)
    }

    @Test func splitsInto3Parts() async throws {
        let original = LinearPath(
            start: Point(x: 1.2.m, y: 1.2.m),
            end: Point(x: 3.4.m, y: 3.4.m))!
        let (partAWithMapping, partBWithMapping, partCWithMapping) =
            original.withMapping.split(at: 0.7.m, and: 0.9.m)!
        let partA = partAWithMapping.path
        let mappingA = partAWithMapping.mapping
        let partB = partBWithMapping.path
        let mappingB = partBWithMapping.mapping
        let partC = partCWithMapping.path
        let mappingC = partCWithMapping.mapping

        #expect(original.split(at: 0.7.m, and: 0.9.m)! == (partA, partB, partC))
        for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
            let originalX = original.length * f
            let originalPoint = original.point(at: originalX)
            let partAX = mappingA.newPosition(for: originalX)
            let partBX = mappingB.newPosition(for: originalX)
            let partCX = mappingC.newPosition(for: originalX)
            if let partAX = partAX {
                let partAPoint = partA.point(at: partAX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partAPoint)
            }
            if let partBX = partBX {
                let partBPoint = partB.point(at: partBX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partBPoint)
            }
            if let partCX = partCX {
                let partCPoint = partC.point(at: partCX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partCPoint)
            }
            if partAX == nil && partBX == nil && partCX == nil {
                #expect(originalPoint == nil)
            }
        }
    }

    @Test func combines() async throws {
        let partA = LinearPath(start: Point(x: 1.2.m, y: 1.2.m), end: Point(x: 3.4.m, y: 3.4.m))!
        let partB = LinearPath(start: Point(x: 3.4.m, y: 3.4.m), end: Point(x: 5.6.m, y: 5.6.m))!
        let (result, partAMapping, partBMapping) = FinitePathAndPositionMapping.combine(
            partA.withMapping, partB.withMapping)!

        #expect(LinearPath.combine(partA, partB) == result)
        for (part, mapping) in [(partA, partAMapping), (partB, partBMapping)] {
            for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
                let originalX = part.length * f
                let originalPoint = part.point(at: originalX)
                let resultX = mapping.newPosition(for: originalX)
                if let resultX = resultX {
                    let resultPoint = result.point(at: resultX)
                    #expect(originalPoint != nil)
                    #expect(originalPoint == resultPoint)
                } else {
                    #expect(originalPoint == nil)
                }
            }
        }
    }

    @Test func handlesImpossibleCombinationOfTwoPaths() async throws {
        let partA = LinearPath(start: Point(x: 1.2.m, y: 1.2.m), end: Point(x: 3.4.m, y: 3.4.m))!
        let partB = LinearPath(start: Point(x: 5.6.m, y: 5.6.m), end: Point(x: 7.8.m, y: 7.8.m))!

        #expect(
            FinitePathAndPositionMapping.combine(
                partA.withMapping, partB.withMapping) == nil)
    }

    @Test func splitsReversedPath() async throws {
        let original = LinearPath(
            start: Point(x: 1.2.m, y: 1.2.m),
            end: Point(x: 3.4.m, y: 3.4.m))!
        let (partAWithMapping, partBWithMapping) =
            original.withMapping.reverse.split(at: 0.7.m)!

        let partA = partAWithMapping.path
        let mappingA = partAWithMapping.mapping
        let partB = partBWithMapping.path
        let mappingB = partBWithMapping.mapping

        #expect(original.reverse.split(at: 0.7.m)! == (partA, partB))
        for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
            let originalX = original.length * f
            let originalPoint = original.point(at: originalX)
            let partAX = mappingA.newPosition(for: originalX)
            let partBX = mappingB.newPosition(for: originalX)
            if let partAX = partAX {
                let partAPoint = partA.point(at: partAX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partAPoint)
            }
            if let partBX = partBX {
                let partBPoint = partB.point(at: partBX)
                #expect(originalPoint != nil)
                #expect(originalPoint == partBPoint)
            }
            if partAX == nil && partBX == nil {
                #expect(originalPoint == nil)
            }
        }
    }

    @Test func combinesReversedPathAndPath() async throws {
        let partA = LinearPath(start: Point(x: 3.4.m, y: 3.4.m), end: Point(x: 1.2.m, y: 1.2.m))!
        let partB = LinearPath(start: Point(x: 3.4.m, y: 3.4.m), end: Point(x: 5.6.m, y: 5.6.m))!
        let (result, partAMapping, partBMapping) = FinitePathAndPositionMapping.combine(
            partA.withMapping.reverse, partB.withMapping)!

        #expect(LinearPath.combine(partA.reverse, partB) == result)
        for (part, mapping) in [(partA, partAMapping), (partB, partBMapping)] {
            for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
                let originalX = part.length * f
                let originalPoint = part.point(at: originalX)
                let resultX = mapping.newPosition(for: originalX)
                if let resultX = resultX {
                    let resultPoint = result.point(at: resultX)
                    #expect(originalPoint != nil)
                    #expect(originalPoint == resultPoint)
                } else {
                    #expect(originalPoint == nil)
                }
            }
        }
    }

    @Test func combinesPathAndReversedPath() async throws {
        let partA = LinearPath(start: Point(x: 1.2.m, y: 1.2.m), end: Point(x: 3.4.m, y: 3.4.m))!
        let partB = LinearPath(start: Point(x: 5.6.m, y: 5.6.m), end: Point(x: 3.4.m, y: 3.4.m))!
        let (result, partAMapping, partBMapping) = FinitePathAndPositionMapping.combine(
            partA.withMapping, partB.withMapping.reverse)!

        #expect(LinearPath.combine(partA, partB.reverse) == result)
        for (part, mapping) in [(partA, partAMapping), (partB, partBMapping)] {
            for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
                let originalX = part.length * f
                let originalPoint = part.point(at: originalX)
                let resultX = mapping.newPosition(for: originalX)
                if let resultX = resultX {
                    let resultPoint = result.point(at: resultX)
                    #expect(originalPoint != nil)
                    #expect(originalPoint == resultPoint)
                } else {
                    #expect(originalPoint == nil)
                }
            }
        }
    }

    @Test func combinesTwoReversedPaths() async throws {
        let partA = LinearPath(start: Point(x: 3.4.m, y: 3.4.m), end: Point(x: 1.2.m, y: 1.2.m))!
        let partB = LinearPath(start: Point(x: 5.6.m, y: 5.6.m), end: Point(x: 3.4.m, y: 3.4.m))!
        let (result, partAMapping, partBMapping) = FinitePathAndPositionMapping.combine(
            partA.withMapping.reverse, partB.withMapping.reverse)!

        #expect(LinearPath.combine(partA.reverse, partB.reverse) == result)
        for (part, mapping) in [(partA, partAMapping), (partB, partBMapping)] {
            for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
                let originalX = part.length * f
                let originalPoint = part.point(at: originalX)
                let resultX = mapping.newPosition(for: originalX)
                if let resultX = resultX {
                    let resultPoint = result.point(at: resultX)
                    #expect(originalPoint != nil)
                    #expect(originalPoint == resultPoint)
                } else {
                    #expect(originalPoint == nil)
                }
            }
        }
    }

    @Test func combinesFourPaths() async throws {
        let partA = LinearPath(start: Point(x: 3.4.m, y: 3.4.m), end: Point(x: 1.2.m, y: 1.2.m))!
        let partB = LinearPath(start: Point(x: 3.4.m, y: 3.4.m), end: Point(x: 5.6.m, y: 5.6.m))!
        let partC = LinearPath(start: Point(x: 5.6.m, y: 5.6.m), end: Point(x: 7.8.m, y: 7.8.m))!
        let partD = LinearPath(start: Point(x: 8.9.m, y: 8.9.m), end: Point(x: 7.8.m, y: 7.8.m))!
        let parts = [partA, partB, partC, partD]
        let (result, partMappings) = FinitePathAndPositionMapping.combine([
            partA.withMapping.reverse,
            partB.withMapping,
            partC.withMapping,
            partD.withMapping.reverse,
        ])!

        #expect(
            result == LinearPath(start: Point(x: 1.2.m, y: 1.2.m), end: Point(x: 8.9.m, y: 8.9.m)))
        #expect(partMappings.count == 4)
        for (part, mapping) in zip(parts, partMappings) {
            for f in [-1.0, -0.1, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.1, 2.0] {
                let originalX = part.length * f
                let originalPoint = part.point(at: originalX)
                let resultX = mapping.newPosition(for: originalX)
                if let resultX = resultX {
                    let resultPoint = result.point(at: resultX)
                    #expect(originalPoint != nil)
                    #expect(originalPoint == resultPoint)
                } else {
                    #expect(originalPoint == nil)
                }
            }
        }
    }

    @Test func handlesImpossibleCombinationOfThreePaths() async throws {
        let partA = LinearPath(start: Point(x: 1.2.m, y: 1.2.m), end: Point(x: 3.4.m, y: 3.4.m))!
        let partB = LinearPath(start: Point(x: 5.6.m, y: 5.6.m), end: Point(x: 7.8.m, y: 7.8.m))!
        let partC = LinearPath(start: Point(x: 8.9.m, y: 8.9.m), end: Point(x: 7.8.m, y: 7.8.m))!

        #expect(
            FinitePathAndPositionMapping.combine([
                partA.withMapping,
                partB.withMapping,
                partC.withMapping,
            ]) == nil)
    }

}
