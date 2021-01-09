//
//  GameSaveKeyId.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/26/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

enum GameSaveKeyId: Int {
    case invalid = -1,
         adventure_data_server_loot = 24,
         adventure_data_server_gil = 0x1f,
         adventure_data_client_loot = 42,
         adventure_data_client_gil = 43,
         adventure_data_client_naxx = 46,
         adventure_data_client_brm = 47,
         adventure_data_client_loe = 48,
         adventure_data_client_kara = 49,
         adventure_data_client_icc = 50,
         adventure_data_server_bot = 53,
         adventure_data_client_bot = 54,
         adventure_data_server_trl = 51,
         adventure_data_client_trl = 52,
         adventure_data_server_dalaran = 55,
         adventure_data_client_dalaran = 56,
         adventure_data_server_dalaran_heroic = 344,
         adventure_data_client_dalaran_heroic = 345,
         adventure_data_server_uldum = 318,
         adventure_data_client_uldum = 90,
         adventure_data_server_uldum_heroic = 380,
         adventure_data_client_uldum_heroic = 379,
         player_options = 356,
         collection_manager = 367,
         bacon = 410,
         character_dialog = 412,
         ranked_play = 479,
         game_mode_scene = 532,
         adventure_data_server_boh = 535,
         adventure_data_client_boh = 536
}
