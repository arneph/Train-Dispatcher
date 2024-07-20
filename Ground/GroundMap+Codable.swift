//
//  GroundMap+Codable.swift
//  Ground
//
//  Created by Arne Philipeit on 6/2/24.
//

import Foundation
import Base

extension GroundMap: Codable {
    private enum CodingKeys: String, CodingKey {
        case baseColor, chunks
    }

    public convenience init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let baseColor = try values.decode(Color.self, forKey: .baseColor)
        let chunks = try values.decode([ChunkID: Chunk].self, forKey: .chunks)
        self.init(baseColor: baseColor, chunks: chunks)
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(baseColor, forKey: .baseColor)
        try values.encode(chunks, forKey: .chunks)
    }

}
