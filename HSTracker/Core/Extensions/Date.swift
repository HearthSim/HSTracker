//
//  Date.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/03/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

extension Date {
    public var year: Int {
        return LogReaderManager.calendar.component(.year, from: self)
    }
    public var month: Int {
        return LogReaderManager.calendar.component(.month, from: self)
    }
    public var day: Int {
        return LogReaderManager.calendar.component(.day, from: self)
    }
    public var hour: Int {
        return LogReaderManager.calendar.component(.hour, from: self)
    }
    public var minute: Int {
        return LogReaderManager.calendar.component(.minute, from: self)
    }
    public var second: Int {
        return LogReaderManager.calendar.component(.second, from: self)
    }
    
    public var removeTimeStamp : Date? {
        guard let date = LogReaderManager.calendar.date(from: Calendar.current.dateComponents([.year, .month, .day], from: self)) else {
        return nil
       }
       return date
   }
}
