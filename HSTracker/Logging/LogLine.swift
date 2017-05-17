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
import Foundation
import RegexUtil

class LogDateFormatter: DateFormatter {
	
	private static let subsecRegex: RegexPattern = "(S+)"
	
	func string(from date: LogDate) -> String {
		var str = self.string(from: date.date)
		
		let matches = self.dateFormat.matches(LogDateFormatter.subsecRegex)
		for match in matches {
			let len = match.value.characters.count
			let rcen = 10^^(7-len)
			let roundedss = (date.subseconds + (rcen/2))/rcen * rcen
			
			let subsecstr = String(format: "%07d", roundedss).substring(from: 0, to: len)

			str.replaceSubrange(match.range, with: subsecstr)
		}
		
		return str
	}
	
	func date(from str: String) -> LogDate? {
		if let d: Date = self.date(from: str) {
			return LogDate(date: d)
		}
		return nil
	}
}

struct LogDate: Comparable, Equatable {
	fileprivate let date: Date
	let subseconds: Int
	
	var timeIntervalSinceNow: TimeInterval {
		return date.timeIntervalSinceNow
	}
	
	var hour: Int {
		return self.date.hour
	}
	
	var minute: Int {
		return self.date.minute
	}
	
	var second: Int {
		return self.date.second
	}
	
	init() {
		self.init(date: Date())
	}
	
	init(date: Date, subseconds: Int = 0) {
		self.date = date
		self.subseconds = subseconds
	}
	
	init(stringcomponents: [String]) {
		var d: Date = Date()
		var subsec: Int = 0
		if stringcomponents.count > 0 {
			LogLine.dateStringFormatter.defaultDate = LogLine.DateNoTime(date: d)
			if let date = LogLine.dateStringFormatter.date(from: stringcomponents[0]) {
				d = date
			}
			if stringcomponents.count > 1 {
				if let ss = Int(stringcomponents[1]) {
					subsec = ss
				}
			}
		}
		
		self.init(date: d, subseconds: subsec)
	}
	
	static func < (lhs: LogDate, rhs: LogDate) -> Bool {
		if lhs.date != rhs.date {
			return lhs.date < rhs.date
		} else {
			return lhs.subseconds < rhs.subseconds
		}
	}
	
	static func == (lhs: LogDate, rhs: LogDate) -> Bool {
		return
			lhs.date == rhs.date &&
				lhs.subseconds == rhs.subseconds
	}
	
	static func LogDateByAdding(component: Calendar.Component, value: Int,
	                            to date: LogDate, from calendar: Calendar ) -> LogDate {
		if let datePlusOne = calendar.date(byAdding: component, value: value, to: date.date) {
			return LogDate(date: datePlusOne, subseconds: date.subseconds)
		} else {
			return date
		}
	}
}

struct LogLine {
	let namespace: LogLineNamespace
	let time: LogDate
	let content: String
	let line: String
	
	@nonobjc fileprivate static let dateStringFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "HH:mm:ss"
		formatter.timeZone = TimeZone.current
		return formatter
	}()
	
	@nonobjc private static let trimFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = DateFormatter.Style.none
		formatter.dateStyle = DateFormatter.Style.short
		return formatter
	}()
	
	static func DateNoTime(date: Date) -> Date {
		let str = LogLine.trimFormatter.string(from: date) // 12/15/16
		return LogLine.trimFormatter.date(from: str)!
	}
	
	init(namespace: LogLineNamespace, line: String) {
		self.namespace = namespace
		self.line = line
		
		if line.characters.count <= 20 {
			self.time = LogDate()
			self.content = ""
			return
		}
		
		let linecomponents = line.components(separatedBy: " ")
		
		if linecomponents.count < 3 {
			self.time = LogDate()
			self.content = ""
			return
		}
		
		// parse time
		let timecomponents = linecomponents[1].components(separatedBy: ".")
		var _time = LogDate(stringcomponents: timecomponents)
		
		if _time > LogDate() {
			_time = LogDate.LogDateByAdding(component: .day, value: -1, to: _time, from: LogReaderManager.calendar)
		}
		
		self.time = _time
		self.content = linecomponents[2..<linecomponents.count].joined(separator: " ")
	}
}

extension LogLine: CustomStringConvertible {
	var description: String {
		let dateStr = LogReaderManager.fullDateStringFormatter.string(from: self.time)
		return "\(namespace): \(dateStr): \(content)"
	}
}
