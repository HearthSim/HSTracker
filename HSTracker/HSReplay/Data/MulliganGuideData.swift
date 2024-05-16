//
//  MulliganGuideData.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/17/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class MulliganGuideData: Decodable {
    var deck_dbf_id_list: [CardStats]
    var base_winrate: Double?
    var selected_params: [String: String?]?
    var toast: MulliganGuideToast?
    
    class CardStats: Decodable {
        var dbf_id: Int
        var opening_hand_winrate: Double?
        var keep_percentage: Double?
        
        init(dbf_id: Int, opening_hand_winrate: Double? = nil, keep_percentage: Double? = nil) {
            self.dbf_id = dbf_id
            self.opening_hand_winrate = opening_hand_winrate
            self.keep_percentage = keep_percentage
        }
    }
    
    class MulliganGuideToast: Decodable {
        var shortid: String
        var parameters: [String: String]
        
        init(shortid: String, parameters: [String: String]) {
            self.shortid = shortid
            self.parameters = parameters
        }
    }
}
