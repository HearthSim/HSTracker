//
//  BuildDate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BuildDates {
    
    struct BuildDate {
        let date: NSDate
        let build: Int
    }
    
    static func getByDate(date: NSDate) -> Int? {
        for buildDate in knownBuildDates {
            if date >= buildDate.date {
                return buildDate.build
            }
        }
        return nil
    }
    
    private static let knownBuildDates: [BuildDate] = {
        return [
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 8, day: 9)!, build: 13921),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 7, day: 26)!, build: 13807),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 7, day: 15)!, build: 13740),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 7, day: 12)!, build: 13619),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 6, day: 1)!, build: 13030),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 4, day: 25)!, build: 12574),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 4, day: 14)!, build: 12266),
            BuildDate(date: NSDate.NSDateFromYear(year: 2016, month: 3, day: 14)!, build: 12051),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 12, day: 4)!, build: 10956),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 11, day: 10)!, build: 10833),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 10, day: 20)!, build: 10604),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 9, day: 29)!, build: 10357),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 8, day: 18)!, build: 9786),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 6, day: 29)!, build: 9554),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 6, day: 15)!, build: 9166),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 5, day: 14)!, build: 8834),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 4, day: 14)!, build: 8416),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 3, day: 31)!, build: 8311),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 3, day: 19)!, build: 8108),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 2, day: 26)!, build: 8036),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 2, day: 25)!, build: 7835),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 2, day: 9)!, build: 7785),
            BuildDate(date: NSDate.NSDateFromYear(year: 2015, month: 1, day: 29)!, build: 7628),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 12, day: 4)!, build: 7234),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 10, day: 29)!, build: 6898),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 9, day: 22)!, build: 6485),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 8, day: 16)!, build: 6284),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 8, day: 6)!, build: 6187),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 7, day: 31)!, build: 6141),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 7, day: 22)!, build: 6024),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 6, day: 30)!, build: 5834),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 5, day: 28)!, build: 5506),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 5, day: 21)!, build: 5435),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 5, day: 8)!, build: 5314),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 4, day: 10)!, build: 5170),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 3, day: 13)!, build: 4973),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 1, day: 17)!, build: 4482),
            BuildDate(date: NSDate.NSDateFromYear(year: 2014, month: 1, day: 16)!, build: 4458),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 1, day: 13)!, build: 4442),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 12, day: 10)!, build: 4217),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 10, day: 17)!, build: 3937),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 10, day: 2)!, build: 3890),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 8, day: 14)!, build: 3664),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 8, day: 13)!, build: 3645),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 8, day: 12)!, build: 3604),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 6, day: 22)!, build: 3388),
            BuildDate(date: NSDate.NSDateFromYear(year: 2013, month: 6, day: 5)!, build: 3140)
        ]
    }()
}