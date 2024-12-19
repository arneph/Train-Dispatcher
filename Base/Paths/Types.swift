//
//  Types.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

public enum AtomicPathType: Equatable, Hashable, Codable {
    case linear, circular
}

public enum FinitePathType: Equatable, Hashable, Codable {
    case linear, circular, compound

    public var atomicPathType: AtomicPathType? {
        switch self {
        case .linear: .linear
        case .circular: .circular
        case .compound: nil
        }
    }

    public init(_ atomicPathType: AtomicPathType) {
        switch atomicPathType {
        case .linear: self = .linear
        case .circular: self = .circular
        }
    }
}
