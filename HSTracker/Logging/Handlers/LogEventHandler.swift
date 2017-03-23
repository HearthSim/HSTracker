//
//  LogHandler.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 22/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol LogEventHandler {
	
	func handle(logLine: LogLine)
}
