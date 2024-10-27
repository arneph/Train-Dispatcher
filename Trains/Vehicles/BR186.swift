//
//  BR186.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 7/21/24.
//

import Base
import CoreGraphics
import Foundation

public final class BR186: Vehicle {
    static let length = 18.90.m
    static let width = 2.978.m

    public override var length: Distance { BR186.length }
    public override var frontOverhang: Distance { 4.25.m }
    public override var backOverhang: Distance { 4.25.m }
    public override var width: Distance { BR186.width }
    public override var weight: Mass { 84.0.T }
    public override var maxAccelerationForce: Force { 300_000.0.N }
    public override var maxBrakeForce: Force { 300_000.N }
    public override var maxSpeed: Speed { 140.0.kph }

    // MARK: -  Drawing
    public override func draw(ctx: DrawContext) {
        ctx.saveGState()

        drawBody(ctx)
        drawWindows(ctx)
        drawVents(ctx)
        drawACUnits(ctx)
        drawPantographs(ctx)

        ctx.restoreGState()
    }

    private func drawBody(_ ctx: DrawContext) {
        let lengthRetreat = 0.5 * BR186.length - 0.65.m
        let widthRetreat = 0.5 * BR186.width - 0.3.m

        let p1front = center + 0.5 * BR186.length ** forward + widthRetreat ** left
        let p1side = center + lengthRetreat ** forward + 0.5 * BR186.width ** left
        let p2front = center + 0.5 * BR186.length ** backward + widthRetreat ** left
        let p2side = center + lengthRetreat ** backward + 0.5 * BR186.width ** left
        let p3front = center + 0.5 * BR186.length ** backward + widthRetreat ** right
        let p3side = center + lengthRetreat ** backward + 0.5 * BR186.width ** right
        let p4front = center + 0.5 * BR186.length ** forward + widthRetreat ** right
        let p4side = center + lengthRetreat ** forward + 0.5 * BR186.width ** right

        ctx.setFillColor(CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.move(to: p1front)
        ctx.addLine(to: p1side)
        ctx.addLine(to: p2side)
        ctx.addLine(to: p2front)
        ctx.addLine(to: p3front)
        ctx.addLine(to: p3side)
        ctx.addLine(to: p4side)
        ctx.addLine(to: p4front)
        ctx.closePath()
        ctx.fillPath()

        ctx.setStrokeColor(CGColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0))
        ctx.setLineWidth(0.03.m)
        ctx.move(to: p1front)
        ctx.addLine(to: p2front)
        ctx.strokePath()
        ctx.move(to: p3front)
        ctx.addLine(to: p4front)
        ctx.strokePath()
    }

    private func drawWindows(_ ctx: DrawContext) {
        let lStart = 0.5 * BR186.length - 0.9.m
        let lEnd = 0.5 * BR186.length - 0.35.m
        let w = 0.5 * BR186.width - 0.38.m

        let p1forward = center + lStart ** forward + w ** left
        let p2forward = center + lEnd ** forward + w ** left
        let p3forward = center + lEnd ** forward + w ** right
        let p4forward = center + lStart ** forward + w ** right

        ctx.move(to: p1forward)
        ctx.addLine(to: p2forward)
        ctx.addLine(to: p3forward)
        ctx.addLine(to: p4forward)
        ctx.closePath()

        ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        ctx.fillPath()

        let p1backward = center + lStart ** backward + w ** left
        let p2backward = center + lEnd ** backward + w ** left
        let p3backward = center + lEnd ** backward + w ** right
        let p4backward = center + lStart ** backward + w ** right

        ctx.move(to: p1backward)
        ctx.addLine(to: p2backward)
        ctx.addLine(to: p3backward)
        ctx.addLine(to: p4backward)
        ctx.closePath()

        ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        ctx.fillPath()
    }

    private func drawVents(_ ctx: DrawContext) {
        let l = 0.5 * BR186.length - 2.1.m
        let wStart = 0.5 * BR186.width - 0.3.m
        let wEnd = 0.5 * BR186.width - 0.05.m

        let p1left = center + l ** forward + wStart ** left
        let p2left = center + l ** backward + wStart ** left
        let p3left = center + l ** backward + wEnd ** left
        let p4left = center + l ** forward + wEnd ** left

        ctx.move(to: p1left)
        ctx.addLine(to: p2left)
        ctx.addLine(to: p3left)
        ctx.addLine(to: p4left)
        ctx.closePath()

        ctx.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0))
        ctx.fillPath()

        let p1right = center + l ** forward + wStart ** right
        let p2right = center + l ** backward + wStart ** right
        let p3right = center + l ** backward + wEnd ** right
        let p4right = center + l ** forward + wEnd ** right

        ctx.move(to: p1right)
        ctx.addLine(to: p2right)
        ctx.addLine(to: p3right)
        ctx.addLine(to: p4right)
        ctx.closePath()

        ctx.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0))
        ctx.fillPath()
    }

    private func drawACUnits(_ ctx: DrawContext) {
        let lStart = 0.5 * BR186.length - 6.55.m
        let lEnd = 0.5 * BR186.length - 4.6.m
        let wStart = 0.15.m
        let wEnd = 1.1.m
        let wd = 0.5 * (wEnd - wStart)
        let fan1L = lStart + wd
        let fan2L = lEnd - wd
        let fanW = wStart + wd
        let fanR = wd - 0.08.m

        let frontP1 = center + lStart ** forward + wStart ** left
        let frontP2 = center + lStart ** forward + wEnd ** left
        let frontP3 = center + lEnd ** forward + wEnd ** left
        let frontP4 = center + lEnd ** forward + wStart ** left

        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        ctx.move(to: frontP1)
        ctx.addLine(to: frontP2)
        ctx.addLine(to: frontP3)
        ctx.addLine(to: frontP4)
        ctx.fillPath()

        let frontFan1P = center + fan1L ** forward + fanW ** left
        let frontFan2P = center + fan2L ** forward + fanW ** left

        ctx.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0))
        ctx.fillCircle(at: frontFan1P, radius: fanR)
        ctx.fillCircle(at: frontFan2P, radius: fanR)

        let backP1 = center + lStart ** backward + wStart ** right
        let backP2 = center + lStart ** backward + wEnd ** right
        let backP3 = center + lEnd ** backward + wEnd ** right
        let backP4 = center + lEnd ** backward + wStart ** right

        ctx.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        ctx.move(to: backP1)
        ctx.addLine(to: backP2)
        ctx.addLine(to: backP3)
        ctx.addLine(to: backP4)
        ctx.fillPath()

        let backFan1P = center + fan1L ** backward + fanW ** right
        let backFan2P = center + fan2L ** backward + fanW ** right

        ctx.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0))
        ctx.fillCircle(at: backFan1P, radius: fanR)
        ctx.fillCircle(at: backFan2P, radius: fanR)
    }

    private func drawPantographs(_ ctx: DrawContext) {
        let cableW = 0.95.m
        let cableR = 0.2.m
        let connectorL = 0.5 * BR186.length - 4.7.m
        let connectorSpace = 0.3.m
        let connector1W = cableW - 0.5 * connectorSpace
        let connector2W = cableW + 0.5 * connectorSpace
        let bottomAxleL = 0.5 * BR186.length - 2.7.m
        let bottomAxleW = 0.65.m
        let middleAxleL = bottomAxleL - 1.5.m
        let middleAxleW = 0.40.m
        let topAxleL = middleAxleL + 1.7.m
        let topAxleW = 0.85.m
        let contactSpace = 0.35.m
        let contact1L = topAxleL - 0.5 * contactSpace
        let contact2L = topAxleL + 0.5 * contactSpace
        let contactW = 1.25.m

        let frontCableP1 = center + bottomAxleL ** forward
        let frontCableP2 = center + bottomAxleL ** forward + (cableW - cableR) ** right
        let frontCableP3 = center + (bottomAxleL - cableR) ** forward + (cableW - cableR) ** right
        let frontCableP4 = center + (bottomAxleL - cableR) ** forward + cableW ** right
        let frontCableP5 = center + connectorL ** forward + cableW ** right
        let frontCableP6 = center + connectorL ** forward + connector1W ** right
        let frontCableP7 = center + connectorL ** forward + connector2W ** right

        ctx.setStrokeColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        ctx.setLineWidth(0.06.m)
        ctx.move(to: frontCableP1)
        ctx.addLine(to: frontCableP2)
        ctx.addArc(
            center: frontCableP3,
            radius: cableR,
            startAngle: angle(from: frontCableP3, to: frontCableP2),
            endAngle: angle(from: frontCableP3, to: frontCableP4),
            clockwise: true)
        ctx.addLine(to: frontCableP5)
        ctx.strokePath()
        ctx.move(to: frontCableP6)
        ctx.addLine(to: frontCableP7)
        ctx.strokePath()
        ctx.fillCircle(at: frontCableP6, radius: 0.06.m)
        ctx.fillCircle(at: frontCableP7, radius: 0.06.m)

        let frontBottomAxleP1 = center + bottomAxleL ** forward + bottomAxleW ** left
        let frontBottomAxleP2 = center + bottomAxleL ** forward + bottomAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.16.m)
        ctx.move(to: frontBottomAxleP1)
        ctx.addLine(to: frontBottomAxleP2)
        ctx.strokePath()

        let frontLowerArmP1 = center + bottomAxleL ** forward
        let frontLowerArmP2 = center + middleAxleL ** forward

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.16.m)
        ctx.move(to: frontLowerArmP1)
        ctx.addLine(to: frontLowerArmP2)
        ctx.strokePath()

        let frontMiddleAxleP1 = center + middleAxleL ** forward + middleAxleW ** left
        let frontMiddleAxleP2 = center + middleAxleL ** forward + middleAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.10.m)
        ctx.move(to: frontMiddleAxleP1)
        ctx.addLine(to: frontMiddleAxleP2)
        ctx.strokePath()

        let frontTopAxleP1 = center + topAxleL ** forward + topAxleW ** left
        let frontTopAxleP2 = center + topAxleL ** forward + topAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.10.m)
        ctx.move(to: frontTopAxleP1)
        ctx.addLine(to: frontTopAxleP2)
        ctx.strokePath()

        let frontUpperArm1P1 = center + middleAxleL ** forward + middleAxleW ** left
        let frontUpperArm1P2 = center + topAxleL ** forward + topAxleW ** left
        let frontUpperArm2P1 = center + middleAxleL ** forward + middleAxleW ** right
        let frontUpperArm2P2 = center + topAxleL ** forward + topAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.08.m)
        ctx.move(to: frontUpperArm1P1)
        ctx.addLine(to: frontUpperArm1P2)
        ctx.strokePath()
        ctx.move(to: frontUpperArm2P1)
        ctx.addLine(to: frontUpperArm2P2)
        ctx.strokePath()

        let frontContactSupport1P1 = center + contact1L ** forward + topAxleW ** left
        let frontContactSupport1P2 = center + contact2L ** forward + topAxleW ** left
        let frontContactSupport2P1 = center + contact1L ** forward + topAxleW ** right
        let frontContactSupport2P2 = center + contact2L ** forward + topAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.08.m)
        ctx.move(to: frontContactSupport1P1)
        ctx.addLine(to: frontContactSupport1P2)
        ctx.strokePath()
        ctx.move(to: frontContactSupport2P1)
        ctx.addLine(to: frontContactSupport2P2)
        ctx.strokePath()

        let frontContact1P1 = center + contact1L ** forward + contactW ** left
        let frontContact1P2 = center + contact1L ** forward + contactW ** right
        let frontContact2P1 = center + contact2L ** forward + contactW ** left
        let frontContact2P2 = center + contact2L ** forward + contactW ** right

        ctx.setStrokeColor(CGColor(red: 0.35, green: 0.5, blue: 0.5, alpha: 1.0))
        ctx.setLineWidth(0.12.m)
        ctx.move(to: frontContact1P1)
        ctx.addLine(to: frontContact1P2)
        ctx.strokePath()
        ctx.move(to: frontContact2P1)
        ctx.addLine(to: frontContact2P2)
        ctx.strokePath()

        let backCableP1 = center + bottomAxleL ** backward
        let backCableP2 = center + bottomAxleL ** backward + (cableW - cableR) ** left
        let backCableP3 = center + (bottomAxleL - cableR) ** backward + (cableW - cableR) ** left
        let backCableP4 = center + (bottomAxleL - cableR) ** backward + cableW ** left
        let backCableP5 = center + connectorL ** backward + cableW ** left
        let backCableP6 = center + connectorL ** backward + connector1W ** left
        let backCableP7 = center + connectorL ** backward + connector2W ** left

        ctx.setStrokeColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        ctx.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        ctx.setLineWidth(0.06.m)
        ctx.move(to: backCableP1)
        ctx.addLine(to: backCableP2)
        ctx.addArc(
            center: backCableP3,
            radius: cableR,
            startAngle: angle(from: backCableP3, to: backCableP2),
            endAngle: angle(from: backCableP3, to: backCableP4),
            clockwise: true)
        ctx.addLine(to: backCableP5)
        ctx.strokePath()
        ctx.move(to: backCableP6)
        ctx.addLine(to: backCableP7)
        ctx.strokePath()
        ctx.fillCircle(at: backCableP6, radius: 0.06.m)
        ctx.fillCircle(at: backCableP7, radius: 0.06.m)

        let backBottomAxleP1 = center + bottomAxleL ** backward + bottomAxleW ** left
        let backBottomAxleP2 = center + bottomAxleL ** backward + bottomAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.16.m)
        ctx.move(to: backBottomAxleP1)
        ctx.addLine(to: backBottomAxleP2)
        ctx.strokePath()

        let backLowerArmP1 = center + bottomAxleL ** backward
        let backLowerArmP2 = center + middleAxleL ** backward

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.16.m)
        ctx.move(to: backLowerArmP1)
        ctx.addLine(to: backLowerArmP2)
        ctx.strokePath()

        let backMiddleAxleP1 = center + middleAxleL ** backward + middleAxleW ** left
        let backMiddleAxleP2 = center + middleAxleL ** backward + middleAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.10.m)
        ctx.move(to: backMiddleAxleP1)
        ctx.addLine(to: backMiddleAxleP2)
        ctx.strokePath()

        let backTopAxleP1 = center + topAxleL ** backward + topAxleW ** left
        let backTopAxleP2 = center + topAxleL ** backward + topAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.10.m)
        ctx.move(to: backTopAxleP1)
        ctx.addLine(to: backTopAxleP2)
        ctx.strokePath()

        let backUpperArm1P1 = center + middleAxleL ** backward + middleAxleW ** left
        let backUpperArm1P2 = center + topAxleL ** backward + topAxleW ** left
        let backUpperArm2P1 = center + middleAxleL ** backward + middleAxleW ** right
        let backUpperArm2P2 = center + topAxleL ** backward + topAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.08.m)
        ctx.move(to: backUpperArm1P1)
        ctx.addLine(to: backUpperArm1P2)
        ctx.strokePath()
        ctx.move(to: backUpperArm2P1)
        ctx.addLine(to: backUpperArm2P2)
        ctx.strokePath()

        let backContactSupport1P1 = center + contact1L ** backward + topAxleW ** left
        let backContactSupport1P2 = center + contact2L ** backward + topAxleW ** left
        let backContactSupport2P1 = center + contact1L ** backward + topAxleW ** right
        let backContactSupport2P2 = center + contact2L ** backward + topAxleW ** right

        ctx.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        ctx.setLineWidth(0.08.m)
        ctx.move(to: backContactSupport1P1)
        ctx.addLine(to: backContactSupport1P2)
        ctx.strokePath()
        ctx.move(to: backContactSupport2P1)
        ctx.addLine(to: backContactSupport2P2)
        ctx.strokePath()

        let backContact1P1 = center + contact1L ** backward + contactW ** left
        let backContact1P2 = center + contact1L ** backward + contactW ** right
        let backContact2P1 = center + contact2L ** backward + contactW ** left
        let backContact2P2 = center + contact2L ** backward + contactW ** right

        ctx.setStrokeColor(CGColor(red: 0.35, green: 0.5, blue: 0.5, alpha: 1.0))
        ctx.setLineWidth(0.12.m)
        ctx.move(to: backContact1P1)
        ctx.addLine(to: backContact1P2)
        ctx.strokePath()
        ctx.move(to: backContact2P1)
        ctx.addLine(to: backContact2P2)
        ctx.strokePath()
    }

}
