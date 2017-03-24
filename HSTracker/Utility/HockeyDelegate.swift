//
//  HockeyDelegate.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 24/03/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HockeySDK

/**
	HockeyDelegate is taking care of application crash reporting to the Hockey service
 */
class HockeyDelegate: NSObject, BITHockeyManagerDelegate {
	
	private static let hockeyKey = "2f0021b9bb1842829aa1cfbbd85d3bed"
	/*if Settings.releaseChannel == .beta {
	hockeyKey = "c8af7f051ae14d0eb67438f27c3d9dc1"
	}*/

	
	override init() {
		super.init()
		BITHockeyManager.shared().configure(withIdentifier: HockeyDelegate.hockeyKey)
		BITHockeyManager.shared().crashManager.isAutoSubmitCrashReport = true
		BITHockeyManager.shared().delegate = self
		BITHockeyManager.shared().start()
	}
	
	func applicationLog(for crashManager: BITCrashManager!) -> String! {
		let fmt = DateFormatter()
		fmt.dateFormat = "yyyy-MM-dd'.log'"
		
		let file = Paths.logs.appendingPathComponent("\(fmt.string(from: Date()))")
		if FileManager.default.fileExists(atPath: file.path) {
			do {
				let content = try String(contentsOf: file)
				return Array(content
					.components(separatedBy: CharacterSet.newlines)
					.reversed() // reverse to keep 400 last lines
					.prefix(400))
					.reversed() // re-reverse them
					.joined(separator: "\n")
			} catch {}
		}
		
		return ""
	}
}

