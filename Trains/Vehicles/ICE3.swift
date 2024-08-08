//
//  ICE3.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 7/27/24.
//

import Base
import CoreGraphics
import Foundation

public final class ICE3Head: Vehicle {
    static let length = 25.835.m
    static let width = 2.950.m

    public override var length: Distance { ICE3Head.length }
    public override var frontOverhang: Distance { 5.0.m }
    public override var backOverhang: Distance { 3.3.m }

    // MARK: - Drawing
    public override func draw(_ cgContext: CGContext, _ viewContext: ViewContext, _ dirtyRect: Rect)
    {
        cgContext.saveGState()

        drawBody(cgContext, viewContext)
        drawHeadlights(cgContext, viewContext)
        drawFrontWindowAndRoofLine(cgContext, viewContext)
        drawDoors(cgContext, viewContext)

        cgContext.restoreGState()
    }

    func drawBody(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let noseLength = 4.35.m
        let frontLengthRetreat = 0.5 * ICE3Head.length - noseLength
        let backLengthRetreat = 0.5 * ICE3Head.length - 0.2.m

        let couplingL1Retreat = 0.5 * ICE3Head.length - 0.4.m
        let couplingL2Retreat = 0.5 * ICE3Head.length - 0.75.m
        let couplingWRetreat = 0.97.m

        let p1 = center + frontLengthRetreat ** forward + 0.5 * ICE3Head.width ** left
        let p2 = center + 0.5 * ICE3Head.length ** forward + 0.5 * ICE3Head.width ** left
        let p3 = center + 0.5 * ICE3Head.length ** forward
        let p4 = center + 0.5 * ICE3Head.length ** forward + 0.5 * ICE3Head.width ** right
        let p5 = center + frontLengthRetreat ** forward + 0.5 * ICE3Head.width ** right
        let p6 = center + backLengthRetreat ** backward + 0.5 * ICE3Head.width ** right
        let p7 = center + backLengthRetreat ** backward + 0.5 * ICE3Head.width ** left

        cgContext.setFillColor(CGColor.white)
        cgContext.move(to: viewContext.toViewPoint(p1))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p3),
            control: viewContext.toViewPoint(p2))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p5),
            control: viewContext.toViewPoint(p4))
        cgContext.addLine(to: viewContext.toViewPoint(p6))
        cgContext.addLine(to: viewContext.toViewPoint(p7))
        cgContext.closePath()
        cgContext.fillPath()

        let p8 = center + couplingL2Retreat ** forward + couplingWRetreat ** left
        let p9 = center + couplingL1Retreat ** forward
        let p10 = center + couplingL2Retreat ** forward + couplingWRetreat ** right

        cgContext.setStrokeColor(CGColor(gray: 0.3, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.02.m))
        cgContext.move(to: viewContext.toViewPoint(p8))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p10),
            control: viewContext.toViewPoint(p9))
        cgContext.strokePath()
    }

    func drawHeadlights(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let l1Retreat = 0.5 * ICE3Head.length - 0.63.m
        let l2Retreat = 0.5 * ICE3Head.length - 0.66.m
        let l3Retreat = 0.5 * ICE3Head.length - 0.95.m
        let l4Retreat = 0.5 * ICE3Head.length - 0.99.m
        let w1Retreat = 0.25.m
        let w2Retreat = 0.35.m
        let w3Retreat = 0.5.m
        let w4Retreat = 0.6.m

        cgContext.setFillColor(CGColor(red: 0.85, green: 0.85, blue: 1.0, alpha: 1.0))
        cgContext.setStrokeColor(CGColor(gray: 0.6, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.02.m))

        let p1Left = center + l1Retreat ** forward + w1Retreat ** left
        let p2Left = center + l3Retreat ** forward + w2Retreat ** left
        let p3Left = center + l4Retreat ** forward + w4Retreat ** left
        let p4Left = center + l2Retreat ** forward + w3Retreat ** left

        cgContext.move(to: viewContext.toViewPoint(p1Left))
        cgContext.addLine(to: viewContext.toViewPoint(p2Left))
        cgContext.addLine(to: viewContext.toViewPoint(p3Left))
        cgContext.addLine(to: viewContext.toViewPoint(p4Left))
        cgContext.closePath()
        cgContext.fillPath()
        cgContext.strokePath()

        let p1Right = center + l1Retreat ** forward + w1Retreat ** right
        let p2Right = center + l3Retreat ** forward + w2Retreat ** right
        let p3Right = center + l4Retreat ** forward + w4Retreat ** right
        let p4Right = center + l2Retreat ** forward + w3Retreat ** right

        cgContext.move(to: viewContext.toViewPoint(p1Right))
        cgContext.addLine(to: viewContext.toViewPoint(p2Right))
        cgContext.addLine(to: viewContext.toViewPoint(p3Right))
        cgContext.addLine(to: viewContext.toViewPoint(p4Right))
        cgContext.closePath()
        cgContext.fillPath()
        cgContext.strokePath()
    }

    func drawFrontWindowAndRoofLine(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let l1Retreat = 0.5 * ICE3Head.length - 1.0.m
        let l2Retreat = 0.5 * ICE3Head.length - 1.25.m
        let l3Retreat = 0.5 * ICE3Head.length - 2.35.m
        let l4Retreat = 0.5 * ICE3Head.length - 2.5.m
        let l5Retreat = 0.5 * ICE3Head.length - 3.75.m
        let w1Retreat = 0.5 * ICE3Head.width - 0.55.m
        let w2Retreat = 0.5 * ICE3Head.width - 0.48.m
        let w3Retreat = 0.5 * ICE3Head.width - 0.42.m
        let w4Retreat = 0.5 * ICE3Head.width - 0.3.m

        let backLengthRetreat = 0.5 * ICE3Head.length - 0.2.m
        let noseLength = 4.35.m
        let frontLengthRetreat = 0.5 * ICE3Head.length - noseLength
        let roofLineWRetreat = 0.5 * ICE3Head.width - 0.25.m

        let p1 = center + l2Retreat ** forward + w2Retreat ** left
        let p2 = center + l4Retreat ** forward + w3Retreat ** left
        let p3 = center + l5Retreat ** forward + w4Retreat ** left
        let p4 = center + l5Retreat ** forward
        let p5 = center + l5Retreat ** forward + w4Retreat ** right
        let p6 = center + l4Retreat ** forward + w3Retreat ** right
        let p7 = center + l2Retreat ** forward + w2Retreat ** right
        let p8 = center + l2Retreat ** forward
        let p9 = center + l3Retreat ** forward
        let p10 = center + backLengthRetreat ** backward + roofLineWRetreat ** left
        let p11 = center + frontLengthRetreat ** forward + roofLineWRetreat ** left
        let p12 = center + l5Retreat ** forward + roofLineWRetreat ** left
        let p13 = center + l1Retreat ** forward + w1Retreat ** left
        let p14 = center + l1Retreat ** forward
        let p15 = center + l1Retreat ** forward + w1Retreat ** right
        let p16 = center + l5Retreat ** forward + roofLineWRetreat ** right
        let p17 = center + frontLengthRetreat ** forward + roofLineWRetreat ** right
        let p18 = center + backLengthRetreat ** backward + roofLineWRetreat ** right

        cgContext.setFillColor(CGColor(gray: 0.1, alpha: 1.0))
        cgContext.move(to: viewContext.toViewPoint(p2))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p4),
            control: viewContext.toViewPoint(p3))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p6),
            control: viewContext.toViewPoint(p5))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p2),
            control: viewContext.toViewPoint(p9))
        cgContext.closePath()
        cgContext.fillPath()

        cgContext.setFillColor(CGColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0))
        cgContext.move(to: viewContext.toViewPoint(p6))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p8),
            control: viewContext.toViewPoint(p7))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p2),
            control: viewContext.toViewPoint(p1))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p6),
            control: viewContext.toViewPoint(p9))
        cgContext.closePath()
        cgContext.fillPath()

        cgContext.setStrokeColor(CGColor(gray: 0.75, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.03.m))
        cgContext.move(to: viewContext.toViewPoint(p10))
        cgContext.addLine(to: viewContext.toViewPoint(p11))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p2),
            control: viewContext.toViewPoint(p12))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p14),
            control: viewContext.toViewPoint(p13))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p6),
            control: viewContext.toViewPoint(p15))
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(p17),
            control: viewContext.toViewPoint(p16))
        cgContext.addLine(to: viewContext.toViewPoint(p18))
        cgContext.strokePath()
    }

    private func drawDoors(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let doorL1Retreat = 0.5 * ICE3Head.length - 8.0.m
        let doorL2Retreat = 0.5 * ICE3Head.length - 9.2.m
        let doorWRetreat = 0.5 * ICE3Head.width - 0.15.m

        cgContext.setStrokeColor(CGColor(gray: 0.5, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.03.m))
        for (lv, wv) in [(forward, left), (forward, right)] {
            let forntLeftDoorP1 = center + doorL1Retreat ** lv + 0.5 * ICE3Wagon.width ** wv
            let forntLeftDoorP2 = center + doorL1Retreat ** lv + doorWRetreat ** wv
            let forntLeftDoorP3 = center + doorL2Retreat ** lv + doorWRetreat ** wv
            let forntLeftDoorP4 = center + doorL2Retreat ** lv + 0.5 * ICE3Wagon.width ** wv

            cgContext.move(to: viewContext.toViewPoint(forntLeftDoorP1))
            cgContext.addLine(to: viewContext.toViewPoint(forntLeftDoorP2))
            cgContext.addLine(to: viewContext.toViewPoint(forntLeftDoorP3))
            cgContext.addLine(to: viewContext.toViewPoint(forntLeftDoorP4))
            cgContext.strokePath()
        }
    }

}

public final class ICE3Wagon: Vehicle {
    static let length = 24.775.m
    static let width = 2.950.m

    public override var length: Distance { ICE3Wagon.length }
    public override var frontOverhang: Distance { 3.3.m }
    public override var backOverhang: Distance { 3.3.m }

    let hasPantograph: Bool

    public init(direction: Vehicle.Direction, hasPantograph: Bool) {
        self.hasPantograph = hasPantograph
        super.init(direction: direction)
    }

    private enum CodingKeys: String, CodingKey {
        case hasPantograph
    }

    required init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.hasPantograph = try values.decode(Bool.self, forKey: .hasPantograph)
        try super.init(from: values.superDecoder())
    }

    public override func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(hasPantograph, forKey: .hasPantograph)
        try super.encode(to: values.superEncoder())
    }

    // MARK: - Drawing
    public override func draw(_ cgContext: CGContext, _ viewContext: ViewContext, _ dirtyRect: Rect)
    {
        cgContext.saveGState()

        drawBody(cgContext, viewContext)
        drawDoors(cgContext, viewContext)
        if hasPantograph {
            drawPantograph(cgContext, viewContext)
        }

        cgContext.restoreGState()
    }

    func drawBody(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let lengthRetreat = 0.5 * ICE3Wagon.length - 0.2.m
        let roofLineWRetreat = 0.5 * ICE3Wagon.width - 0.25.m

        let p1 = center + lengthRetreat ** forward + 0.5 * ICE3Wagon.width ** left
        let p2 = center + lengthRetreat ** forward + 0.5 * ICE3Wagon.width ** right
        let p3 = center + lengthRetreat ** backward + 0.5 * ICE3Wagon.width ** right
        let p4 = center + lengthRetreat ** backward + 0.5 * ICE3Wagon.width ** left
        let p5 = center + lengthRetreat ** forward + roofLineWRetreat ** left
        let p6 = center + lengthRetreat ** backward + roofLineWRetreat ** left
        let p7 = center + lengthRetreat ** forward + roofLineWRetreat ** right
        let p8 = center + lengthRetreat ** backward + roofLineWRetreat ** right

        cgContext.setFillColor(CGColor.white)
        cgContext.move(to: viewContext.toViewPoint(p1))
        cgContext.addLine(to: viewContext.toViewPoint(p2))
        cgContext.addLine(to: viewContext.toViewPoint(p3))
        cgContext.addLine(to: viewContext.toViewPoint(p4))
        cgContext.closePath()
        cgContext.fillPath()

        cgContext.setStrokeColor(CGColor(gray: 0.75, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.03.m))
        cgContext.move(to: viewContext.toViewPoint(p5))
        cgContext.addLine(to: viewContext.toViewPoint(p6))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(p7))
        cgContext.addLine(to: viewContext.toViewPoint(p8))
        cgContext.strokePath()

    }

    private func drawDoors(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let lengthRetreat = 0.5 * ICE3Wagon.length - 0.2.m
        let doorL1Retreat = lengthRetreat - 0.3.m
        let doorL2Retreat = lengthRetreat - 1.5.m
        let doorWRetreat = 0.5 * ICE3Wagon.width - 0.15.m

        cgContext.setStrokeColor(CGColor(gray: 0.5, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.03.m))
        for (lv, wv) in [(forward, left), (forward, right), (backward, left), (backward, right)] {
            let forntLeftDoorP1 = center + doorL1Retreat ** lv + 0.5 * ICE3Wagon.width ** wv
            let forntLeftDoorP2 = center + doorL1Retreat ** lv + doorWRetreat ** wv
            let forntLeftDoorP3 = center + doorL2Retreat ** lv + doorWRetreat ** wv
            let forntLeftDoorP4 = center + doorL2Retreat ** lv + 0.5 * ICE3Wagon.width ** wv

            cgContext.move(to: viewContext.toViewPoint(forntLeftDoorP1))
            cgContext.addLine(to: viewContext.toViewPoint(forntLeftDoorP2))
            cgContext.addLine(to: viewContext.toViewPoint(forntLeftDoorP3))
            cgContext.addLine(to: viewContext.toViewPoint(forntLeftDoorP4))
            cgContext.strokePath()
        }
    }

    private func drawPantograph(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let cableW = 0.95.m
        let cableR = 0.2.m
        let connectorL = 0.5 * ICE3Wagon.length - 5.2.m
        let connectorSpace = 0.3.m
        let connector1W = cableW - 0.5 * connectorSpace
        let connector2W = cableW + 0.5 * connectorSpace
        let bottomAxleL = 0.5 * ICE3Wagon.length - 3.2.m
        let bottomAxleW = 0.65.m
        let middleAxleL = bottomAxleL - 1.5.m
        let middleAxleW = 0.40.m
        let topAxleL = middleAxleL + 1.7.m
        let topAxleW = 0.85.m
        let contactSpace = 0.35.m
        let contact1L = topAxleL - 0.5 * contactSpace
        let contact2L = topAxleL + 0.5 * contactSpace
        let contactW = 1.25.m

        let frontCableP1 = center + bottomAxleL ** backward
        let frontCableP2 = center + bottomAxleL ** backward + (cableW - cableR) ** right
        let frontCableP3 = center + (bottomAxleL - cableR) ** backward + (cableW - cableR) ** right
        let frontCableP4 = center + (bottomAxleL - cableR) ** backward + cableW ** right
        let frontCableP5 = center + connectorL ** backward + cableW ** right
        let frontCableP6 = center + connectorL ** backward + connector1W ** right
        let frontCableP7 = center + connectorL ** backward + connector2W ** right

        cgContext.setStrokeColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        cgContext.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.06.m))
        cgContext.move(to: viewContext.toViewPoint(frontCableP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontCableP2))
        cgContext.addArc(
            center: viewContext.toViewPoint(frontCableP3),
            radius: viewContext.toViewDistance(cableR),
            startAngle: viewContext.toViewAngle(angle(from: frontCableP3, to: frontCableP2)),
            endAngle: viewContext.toViewAngle(angle(from: frontCableP3, to: frontCableP4)),
            clockwise: false)
        cgContext.addLine(to: viewContext.toViewPoint(frontCableP5))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontCableP6))
        cgContext.addLine(to: viewContext.toViewPoint(frontCableP7))
        cgContext.strokePath()
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: frontCableP6,
                    length: 0.12.m)))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: frontCableP7,
                    length: 0.12.m)))

        let frontBottomAxleP1 = center + bottomAxleL ** backward + bottomAxleW ** left
        let frontBottomAxleP2 = center + bottomAxleL ** backward + bottomAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.16.m))
        cgContext.move(to: viewContext.toViewPoint(frontBottomAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontBottomAxleP2))
        cgContext.strokePath()

        let frontLowerArmP1 = center + bottomAxleL ** backward
        let frontLowerArmP2 = center + middleAxleL ** backward

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.16.m))
        cgContext.move(to: viewContext.toViewPoint(frontLowerArmP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontLowerArmP2))
        cgContext.strokePath()

        let frontMiddleAxleP1 = center + middleAxleL ** backward + middleAxleW ** left
        let frontMiddleAxleP2 = center + middleAxleL ** backward + middleAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.10.m))
        cgContext.move(to: viewContext.toViewPoint(frontMiddleAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontMiddleAxleP2))
        cgContext.strokePath()

        let frontTopAxleP1 = center + topAxleL ** backward + topAxleW ** left
        let frontTopAxleP2 = center + topAxleL ** backward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.10.m))
        cgContext.move(to: viewContext.toViewPoint(frontTopAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontTopAxleP2))
        cgContext.strokePath()

        let frontUpperArm1P1 = center + middleAxleL ** backward + middleAxleW ** left
        let frontUpperArm1P2 = center + topAxleL ** backward + topAxleW ** left
        let frontUpperArm2P1 = center + middleAxleL ** backward + middleAxleW ** right
        let frontUpperArm2P2 = center + topAxleL ** backward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.08.m))
        cgContext.move(to: viewContext.toViewPoint(frontUpperArm1P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontUpperArm1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontUpperArm2P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontUpperArm2P2))
        cgContext.strokePath()

        let frontContactSupport1P1 = center + contact1L ** backward + topAxleW ** left
        let frontContactSupport1P2 = center + contact2L ** backward + topAxleW ** left
        let frontContactSupport2P1 = center + contact1L ** backward + topAxleW ** right
        let frontContactSupport2P2 = center + contact2L ** backward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.08.m))
        cgContext.move(to: viewContext.toViewPoint(frontContactSupport1P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContactSupport1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontContactSupport2P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContactSupport2P2))
        cgContext.strokePath()

        let frontContact1P1 = center + contact1L ** backward + contactW ** left
        let frontContact1P2 = center + contact1L ** backward + contactW ** right
        let frontContact2P1 = center + contact2L ** backward + contactW ** left
        let frontContact2P2 = center + contact2L ** backward + contactW ** right

        cgContext.setStrokeColor(CGColor(red: 0.35, green: 0.5, blue: 0.5, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.12.m))
        cgContext.move(to: viewContext.toViewPoint(frontContact1P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContact1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontContact2P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContact2P2))
        cgContext.strokePath()
    }

}
