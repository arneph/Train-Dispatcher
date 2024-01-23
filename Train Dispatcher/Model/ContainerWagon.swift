//
//  ContainerWagon.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 12/30/23.
//

import Foundation
import CoreGraphics

final class ContainerWagon: BaseVehicle, Vehicle, ContainerOwner {
    static let length = 2.0 * bufferLength +  platformLength
    static let bufferLength = 0.25.m
    static let platformLength = Container.length + 0.40.m
    static let width = Container.width + 0.16.m
    
    var container: Container? {
        didSet {
            if oldValue === container {
                return
            }
            oldValue?.removeOwner()
            container?.set(owner: self)
        }
    }
    
    func position(for container: Container) -> ObjectPosition { objectPosition }
    
    override init(vehiclePosition: VehiclePosition) {
        super.init(vehiclePosition: vehiclePosition)
        self.container = Container(owner: self)
    }
    
    init(vehiclePosition: VehiclePosition, container: Container) {
        super.init(vehiclePosition: vehiclePosition)
        self.container = container
    }
    
    enum CodingKeys: String, CodingKey {
        case container
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.container = try values.decode(Container?.self, forKey: .container)
        try super.init(from: values.superDecoder())
        self.container?.set(owner: self)
    }
    
    override func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(container, forKey: .container)
        try super.encode(to: values.superEncoder())
    }
    
    static let name = "ContainerWagon"
    private static let containerLabel = "container"
    
    static func parseCode(with scanner: Scanner) -> ContainerWagon? {
        parseStruct(name: name, scanner: scanner) {
            guard let vehiclePosition = BaseVehicle.parseLabelsAndArgs(with: scanner) else {
                return nil
            }
            guard scanner.next() == .comma else { return nil }
            guard let container: Container = parseArgument(label: containerLabel,
                                                           scanner: scanner) else {
                return nil
            }
            return ContainerWagon(vehiclePosition: vehiclePosition, container: container)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: ContainerWagon.name,
                    printer: printer) {
            super.printLabelsAndArgs(with: printer)
            printer.write(",\n")
            print(label: ContainerWagon.containerLabel, argument: container, printer: printer)
        }
    }
    
    // MARK: -  Drawing
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext) {
        cgContext.saveGState()
        
        let p1 = center + 0.5 * ContainerWagon.platformLength ** forward
                        + 0.5 * ContainerWagon.width ** left
        let p2 = center + 0.5 * ContainerWagon.platformLength ** backward
                        + 0.5 * ContainerWagon.width ** left
        let p3 = center + 0.5 * ContainerWagon.platformLength ** backward
                        + 0.5 * ContainerWagon.width ** right
        let p4 = center + 0.5 * ContainerWagon.platformLength ** forward
                        + 0.5 * ContainerWagon.width ** right
        
        cgContext.move(to: viewContext.toViewPoint(p1))
        cgContext.addLine(to: viewContext.toViewPoint(p2))
        cgContext.addLine(to: viewContext.toViewPoint(p3))
        cgContext.addLine(to: viewContext.toViewPoint(p4))
        cgContext.closePath()
        
        cgContext.setFillColor(CGColor(red: 0.47, green: 0.42, blue: 0.36, alpha: 1.0))
        cgContext.fillPath()
        
        container?.draw(cgContext, viewContext)
        
        cgContext.restoreGState()
    }
    
}
