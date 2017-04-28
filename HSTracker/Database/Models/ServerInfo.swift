//
//  ServerInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import HearthMirror

class ServerInfo: Object {

    dynamic var address = ""
    dynamic var auroraPassword = ""
    dynamic var clientHandle = 0
    dynamic var gameHandle = 0
    dynamic var mission = 0
    dynamic var port = 0
    dynamic var resumable = false
    dynamic var spectatorMode = false
    dynamic var spectatorPassword = ""
    dynamic var version = ""

    convenience init(info: MirrorGameServerInfo) {
        self.init()
        address = info.address
        auroraPassword = info.auroraPassword
        clientHandle = info.clientHandle as? Int ?? 0
        gameHandle = info.gameHandle as? Int ?? 0
        mission = info.mission as? Int ?? 0
        port = info.port as? Int ?? 0
        resumable = info.resumable
        spectatorMode = info.spectatorMode
        spectatorPassword = info.spectatorPassword
        version = info.version
    }
}
