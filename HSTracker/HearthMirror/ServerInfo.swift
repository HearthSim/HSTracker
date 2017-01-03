//
//  ServerInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 30/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct ServerInfo {
    var address: String
    var auroraPassword: String
    var clientHandle: Int
    var gameHandle: Int
    var mission: Int
    var port: Int
    var resumable: Bool
    var spectatorMode: Bool
    var spectatorPassword: String
    var version: String

    init(info: MirrorGameServerInfo) {
        address = info.address
        auroraPassword = info.auroraPassword
        clientHandle = info.clientHandle as Int
        gameHandle = info.gameHandle as Int
        mission = info.mission as Int
        port = info.port as Int
        resumable = info.resumable
        spectatorMode = info.spectatorMode
        spectatorPassword = info.spectatorPassword
        version = info.version
    }
}

extension ServerInfo: CustomStringConvertible {
    var description: String {
        return "address: \(address), " +
        "auroraPassword: \(auroraPassword), " +
        "clientHandle: \(clientHandle), " +
        "gameHandle: \(gameHandle), " +
        "mission: \(mission), " +
        "port: \(port), " +
        "resumable: \(resumable), " +
        "spectatorMode: \(spectatorMode), " +
        "spectatorPassword: \(spectatorPassword), " +
        "version: \(version)"
    }
}
