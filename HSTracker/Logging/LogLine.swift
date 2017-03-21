/*
* This file is part of the HSTracker package.
* (c) Benjamin Michotte <bmichotte@gmail.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*
* Created on 13/02/16.
*/

import CleanroomLogger

struct LogLine {
	let namespace: LogLineNamespace
	let time: Date
	let content: String
	let line: String
	let include: Bool
	
	private static let dateStringFormatterNS: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "HH:mm:ss.SSSSSSS"
		formatter.timeZone = TimeZone.current
		return formatter
	}()
	
	private static let dateStringFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "HH:mm:ss"
		formatter.timeZone = TimeZone.current
		return formatter
	}()
	
	private static let trimFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = DateFormatter.Style.none
		formatter.dateStyle = DateFormatter.Style.short
		return formatter
	}()
	
	init(namespace: LogLineNamespace, line: String, include: Bool = true) {
		self.namespace = namespace
		self.include = include // FIXME: we dont want this here
		self.line = line
		
		if line.characters.count <= 20 {
			self.time = Date()
			self.content = ""
			return
		}
		
		let linecomponents = line.components(separatedBy: " ")
		
		if linecomponents.count < 3 {
			self.time = Date()
			self.content = ""
			return
		}
		
		var time = Date()
		
		// parse time
		if linecomponents[1].components(separatedBy: ".").count > 1 {
			LogLine.dateStringFormatterNS.defaultDate = LogLine.DateNoTime(date: time)
			if let date = LogLine.dateStringFormatterNS.date(from: linecomponents[1]) {
				time = date
			}
		} else {
			LogLine.dateStringFormatter.defaultDate = LogLine.DateNoTime(date: time)
			if let date = LogLine.dateStringFormatter.date(from: linecomponents[1]) {
				time = date
			}
		}
		
		if time > Date() {
			time = LogReaderManager.calendar.date(byAdding: .day, value: -1, to: time) ?? Date()
		}
		
		self.time = time
		self.content = linecomponents[2..<linecomponents.count].joined(separator: " ")
	}
	
	private static func DateNoTime(date: Date) -> Date {
		
		let str = LogLine.trimFormatter.string(from: date) // 12/15/16
		return LogLine.trimFormatter.date(from: str)!
	}
}

extension LogLine: CustomStringConvertible {
	var description: String {
		let dateStr = LogReaderManager.fullDateStringFormatter.string(from: time)
		return "\(namespace): \(dateStr): \(content)"
	}
}
