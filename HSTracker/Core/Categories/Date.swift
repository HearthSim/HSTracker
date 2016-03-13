//
//  Date.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 13/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

extension NSDate {

    func getUTCFormateDate() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.stringFromDate(self)
    }
}