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

    // MARK: -  Drawing
    public override func draw(_ cgContext: CGContext, _ viewContext: ViewContext, _ dirtyRect: Rect)
    {
        cgContext.saveGState()

        drawBody(cgContext, viewContext)
        drawWindows(cgContext, viewContext)
        drawVents(cgContext, viewContext)
        drawACUnits(cgContext, viewContext)
        drawPantographs(cgContext, viewContext)

        cgContext.restoreGState()
    }

    private func drawBody(_ cgContext: CGContext, _ viewContext: ViewContext) {
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

        cgContext.setFillColor(CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.move(to: viewContext.toViewPoint(p1front))
        cgContext.addLine(to: viewContext.toViewPoint(p1side))
        cgContext.addLine(to: viewContext.toViewPoint(p2side))
        cgContext.addLine(to: viewContext.toViewPoint(p2front))
        cgContext.addLine(to: viewContext.toViewPoint(p3front))
        cgContext.addLine(to: viewContext.toViewPoint(p3side))
        cgContext.addLine(to: viewContext.toViewPoint(p4side))
        cgContext.addLine(to: viewContext.toViewPoint(p4front))
        cgContext.closePath()
        cgContext.fillPath()

        cgContext.setStrokeColor(CGColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.03.m))
        cgContext.move(to: viewContext.toViewPoint(p1front))
        cgContext.addLine(to: viewContext.toViewPoint(p2front))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(p3front))
        cgContext.addLine(to: viewContext.toViewPoint(p4front))
        cgContext.strokePath()
    }

    private func drawWindows(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let lStart = 0.5 * BR186.length - 0.9.m
        let lEnd = 0.5 * BR186.length - 0.35.m
        let w = 0.5 * BR186.width - 0.38.m

        let p1forward = center + lStart ** forward + w ** left
        let p2forward = center + lEnd ** forward + w ** left
        let p3forward = center + lEnd ** forward + w ** right
        let p4forward = center + lStart ** forward + w ** right

        cgContext.move(to: viewContext.toViewPoint(p1forward))
        cgContext.addLine(to: viewContext.toViewPoint(p2forward))
        cgContext.addLine(to: viewContext.toViewPoint(p3forward))
        cgContext.addLine(to: viewContext.toViewPoint(p4forward))
        cgContext.closePath()

        cgContext.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        cgContext.fillPath()

        let p1backward = center + lStart ** backward + w ** left
        let p2backward = center + lEnd ** backward + w ** left
        let p3backward = center + lEnd ** backward + w ** right
        let p4backward = center + lStart ** backward + w ** right

        cgContext.move(to: viewContext.toViewPoint(p1backward))
        cgContext.addLine(to: viewContext.toViewPoint(p2backward))
        cgContext.addLine(to: viewContext.toViewPoint(p3backward))
        cgContext.addLine(to: viewContext.toViewPoint(p4backward))
        cgContext.closePath()

        cgContext.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        cgContext.fillPath()
    }

    private func drawVents(_ cgContext: CGContext, _ viewContext: ViewContext) {
        let l = 0.5 * BR186.length - 2.1.m
        let wStart = 0.5 * BR186.width - 0.3.m
        let wEnd = 0.5 * BR186.width - 0.05.m

        let p1left = center + l ** forward + wStart ** left
        let p2left = center + l ** backward + wStart ** left
        let p3left = center + l ** backward + wEnd ** left
        let p4left = center + l ** forward + wEnd ** left

        cgContext.move(to: viewContext.toViewPoint(p1left))
        cgContext.addLine(to: viewContext.toViewPoint(p2left))
        cgContext.addLine(to: viewContext.toViewPoint(p3left))
        cgContext.addLine(to: viewContext.toViewPoint(p4left))
        cgContext.closePath()

        cgContext.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0))
        cgContext.fillPath()

        let p1right = center + l ** forward + wStart ** right
        let p2right = center + l ** backward + wStart ** right
        let p3right = center + l ** backward + wEnd ** right
        let p4right = center + l ** forward + wEnd ** right

        cgContext.move(to: viewContext.toViewPoint(p1right))
        cgContext.addLine(to: viewContext.toViewPoint(p2right))
        cgContext.addLine(to: viewContext.toViewPoint(p3right))
        cgContext.addLine(to: viewContext.toViewPoint(p4right))
        cgContext.closePath()

        cgContext.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0))
        cgContext.fillPath()
    }

    private func drawACUnits(_ cgContext: CGContext, _ viewContext: ViewContext) {
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

        cgContext.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        cgContext.move(to: viewContext.toViewPoint(frontP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontP2))
        cgContext.addLine(to: viewContext.toViewPoint(frontP3))
        cgContext.addLine(to: viewContext.toViewPoint(frontP4))
        cgContext.fillPath()

        let frontFan1P = center + fan1L ** forward + fanW ** left
        let frontFan2P = center + fan2L ** forward + fanW ** left

        cgContext.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: frontFan1P,
                    length: 2.0 * fanR)))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: frontFan2P,
                    length: 2.0 * fanR)))

        let backP1 = center + lStart ** backward + wStart ** right
        let backP2 = center + lStart ** backward + wEnd ** right
        let backP3 = center + lEnd ** backward + wEnd ** right
        let backP4 = center + lEnd ** backward + wStart ** right

        cgContext.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        cgContext.move(to: viewContext.toViewPoint(backP1))
        cgContext.addLine(to: viewContext.toViewPoint(backP2))
        cgContext.addLine(to: viewContext.toViewPoint(backP3))
        cgContext.addLine(to: viewContext.toViewPoint(backP4))
        cgContext.fillPath()

        let backFan1P = center + fan1L ** backward + fanW ** right
        let backFan2P = center + fan2L ** backward + fanW ** right

        cgContext.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: backFan1P,
                    length: 2.0 * fanR)))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: backFan2P,
                    length: 2.0 * fanR)))
    }

    private func drawPantographs(_ cgContext: CGContext, _ viewContext: ViewContext) {
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
            clockwise: true)
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

        let frontBottomAxleP1 = center + bottomAxleL ** forward + bottomAxleW ** left
        let frontBottomAxleP2 = center + bottomAxleL ** forward + bottomAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.16.m))
        cgContext.move(to: viewContext.toViewPoint(frontBottomAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontBottomAxleP2))
        cgContext.strokePath()

        let frontLowerArmP1 = center + bottomAxleL ** forward
        let frontLowerArmP2 = center + middleAxleL ** forward

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.16.m))
        cgContext.move(to: viewContext.toViewPoint(frontLowerArmP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontLowerArmP2))
        cgContext.strokePath()

        let frontMiddleAxleP1 = center + middleAxleL ** forward + middleAxleW ** left
        let frontMiddleAxleP2 = center + middleAxleL ** forward + middleAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.10.m))
        cgContext.move(to: viewContext.toViewPoint(frontMiddleAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontMiddleAxleP2))
        cgContext.strokePath()

        let frontTopAxleP1 = center + topAxleL ** forward + topAxleW ** left
        let frontTopAxleP2 = center + topAxleL ** forward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.10.m))
        cgContext.move(to: viewContext.toViewPoint(frontTopAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(frontTopAxleP2))
        cgContext.strokePath()

        let frontUpperArm1P1 = center + middleAxleL ** forward + middleAxleW ** left
        let frontUpperArm1P2 = center + topAxleL ** forward + topAxleW ** left
        let frontUpperArm2P1 = center + middleAxleL ** forward + middleAxleW ** right
        let frontUpperArm2P2 = center + topAxleL ** forward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.08.m))
        cgContext.move(to: viewContext.toViewPoint(frontUpperArm1P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontUpperArm1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontUpperArm2P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontUpperArm2P2))
        cgContext.strokePath()

        let frontContactSupport1P1 = center + contact1L ** forward + topAxleW ** left
        let frontContactSupport1P2 = center + contact2L ** forward + topAxleW ** left
        let frontContactSupport2P1 = center + contact1L ** forward + topAxleW ** right
        let frontContactSupport2P2 = center + contact2L ** forward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.08.m))
        cgContext.move(to: viewContext.toViewPoint(frontContactSupport1P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContactSupport1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontContactSupport2P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContactSupport2P2))
        cgContext.strokePath()

        let frontContact1P1 = center + contact1L ** forward + contactW ** left
        let frontContact1P2 = center + contact1L ** forward + contactW ** right
        let frontContact2P1 = center + contact2L ** forward + contactW ** left
        let frontContact2P2 = center + contact2L ** forward + contactW ** right

        cgContext.setStrokeColor(CGColor(red: 0.35, green: 0.5, blue: 0.5, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.12.m))
        cgContext.move(to: viewContext.toViewPoint(frontContact1P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContact1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(frontContact2P1))
        cgContext.addLine(to: viewContext.toViewPoint(frontContact2P2))
        cgContext.strokePath()

        let backCableP1 = center + bottomAxleL ** backward
        let backCableP2 = center + bottomAxleL ** backward + (cableW - cableR) ** left
        let backCableP3 = center + (bottomAxleL - cableR) ** backward + (cableW - cableR) ** left
        let backCableP4 = center + (bottomAxleL - cableR) ** backward + cableW ** left
        let backCableP5 = center + connectorL ** backward + cableW ** left
        let backCableP6 = center + connectorL ** backward + connector1W ** left
        let backCableP7 = center + connectorL ** backward + connector2W ** left

        cgContext.setStrokeColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        cgContext.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.06.m))
        cgContext.move(to: viewContext.toViewPoint(backCableP1))
        cgContext.addLine(to: viewContext.toViewPoint(backCableP2))
        cgContext.addArc(
            center: viewContext.toViewPoint(backCableP3),
            radius: viewContext.toViewDistance(cableR),
            startAngle: viewContext.toViewAngle(angle(from: backCableP3, to: backCableP2)),
            endAngle: viewContext.toViewAngle(angle(from: backCableP3, to: backCableP4)),
            clockwise: true)
        cgContext.addLine(to: viewContext.toViewPoint(backCableP5))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(backCableP6))
        cgContext.addLine(to: viewContext.toViewPoint(backCableP7))
        cgContext.strokePath()
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: backCableP6,
                    length: 0.12.m)))
        cgContext.fillEllipse(
            in: viewContext.toViewRect(
                Rect.square(
                    around: backCableP7,
                    length: 0.12.m)))

        let backBottomAxleP1 = center + bottomAxleL ** backward + bottomAxleW ** left
        let backBottomAxleP2 = center + bottomAxleL ** backward + bottomAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.16.m))
        cgContext.move(to: viewContext.toViewPoint(backBottomAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(backBottomAxleP2))
        cgContext.strokePath()

        let backLowerArmP1 = center + bottomAxleL ** backward
        let backLowerArmP2 = center + middleAxleL ** backward

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.16.m))
        cgContext.move(to: viewContext.toViewPoint(backLowerArmP1))
        cgContext.addLine(to: viewContext.toViewPoint(backLowerArmP2))
        cgContext.strokePath()

        let backMiddleAxleP1 = center + middleAxleL ** backward + middleAxleW ** left
        let backMiddleAxleP2 = center + middleAxleL ** backward + middleAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.10.m))
        cgContext.move(to: viewContext.toViewPoint(backMiddleAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(backMiddleAxleP2))
        cgContext.strokePath()

        let backTopAxleP1 = center + topAxleL ** backward + topAxleW ** left
        let backTopAxleP2 = center + topAxleL ** backward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.10.m))
        cgContext.move(to: viewContext.toViewPoint(backTopAxleP1))
        cgContext.addLine(to: viewContext.toViewPoint(backTopAxleP2))
        cgContext.strokePath()

        let backUpperArm1P1 = center + middleAxleL ** backward + middleAxleW ** left
        let backUpperArm1P2 = center + topAxleL ** backward + topAxleW ** left
        let backUpperArm2P1 = center + middleAxleL ** backward + middleAxleW ** right
        let backUpperArm2P2 = center + topAxleL ** backward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.08.m))
        cgContext.move(to: viewContext.toViewPoint(backUpperArm1P1))
        cgContext.addLine(to: viewContext.toViewPoint(backUpperArm1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(backUpperArm2P1))
        cgContext.addLine(to: viewContext.toViewPoint(backUpperArm2P2))
        cgContext.strokePath()

        let backContactSupport1P1 = center + contact1L ** backward + topAxleW ** left
        let backContactSupport1P2 = center + contact2L ** backward + topAxleW ** left
        let backContactSupport2P1 = center + contact1L ** backward + topAxleW ** right
        let backContactSupport2P2 = center + contact2L ** backward + topAxleW ** right

        cgContext.setStrokeColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.08.m))
        cgContext.move(to: viewContext.toViewPoint(backContactSupport1P1))
        cgContext.addLine(to: viewContext.toViewPoint(backContactSupport1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(backContactSupport2P1))
        cgContext.addLine(to: viewContext.toViewPoint(backContactSupport2P2))
        cgContext.strokePath()

        let backContact1P1 = center + contact1L ** backward + contactW ** left
        let backContact1P2 = center + contact1L ** backward + contactW ** right
        let backContact2P1 = center + contact2L ** backward + contactW ** left
        let backContact2P2 = center + contact2L ** backward + contactW ** right

        cgContext.setStrokeColor(CGColor(red: 0.35, green: 0.5, blue: 0.5, alpha: 1.0))
        cgContext.setLineWidth(viewContext.toViewDistance(0.12.m))
        cgContext.move(to: viewContext.toViewPoint(backContact1P1))
        cgContext.addLine(to: viewContext.toViewPoint(backContact1P2))
        cgContext.strokePath()
        cgContext.move(to: viewContext.toViewPoint(backContact2P1))
        cgContext.addLine(to: viewContext.toViewPoint(backContact2P2))
        cgContext.strokePath()
    }

}
