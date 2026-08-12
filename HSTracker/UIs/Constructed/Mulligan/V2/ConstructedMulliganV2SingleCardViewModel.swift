//
//  ConstructedMulliganV2SingleCardViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

@available(macOS 10.15, *)
class ConstructedMulliganV2SingleCardViewModel: ObservableObject, Identifiable {
    var id: Int { position }
    let position: Int
    let header: ConstructedMulliganV2SingleCardHeaderViewModel

    init(position: Int, data: MulliganV2Data.MulliganCard, isFirst: Bool) {
        self.position = position
        self.header = ConstructedMulliganV2SingleCardHeaderViewModel(position: position, data: data, isFirst: isFirst)
    }
}
