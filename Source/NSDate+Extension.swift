//
//  Date+Extension.swift
//
//  Based on Version 3.1.1 Created by Melvin Rivera on 7/15/14.
//
//  Version 3.2
//
//  Copyright (c) 2016 Alternative Payments Ltd
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

// DotNet: "/Date(1268123281843)/"
let DefaultFormat = "EEE MMM dd HH:mm:ss Z yyyy"
let RSSFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ" // "Fri, 09 Sep 2011 15:26:08 +0200"
let AltRSSFormat = "d MMM yyyy HH:mm:ss ZZZ" // "09 Sep 2011 15:26:08 +0200"

var sharedDateFormatters = [String: DateFormatter]()

/**
 Helper enum for ISO8601 Formatted datestrings

- Year:             Year
- YearMonth:        Year and month
- Date:             Year, month and day
- DateTime:         same as Date including hours and minutes
- DateTimeSec:      same as DateTime including seconds
- DateTimeMilliSec: same as DateTimeSec including milliseconds
*/
public enum ISO8601Format: String {
    
    
    /// Year (1997)
    case Year = "yyyy"
    /// Year and month (1997-07)
    case YearMonth = "yyyy-MM"
    /// Year, month and day (1997-07-16)
    case Date = "yyyy-MM-dd"
    /// same as Date including hours and minutes (1997-07-16T19:20+01:00)
    case DateTime = "yyyy-MM-dd'T'HH:mmZ"
    /// same as DateTime including seconds (1997-07-16T19:20:30+01:00)
    case DateTimeSec = "yyyy-MM-dd'T'HH:mm:ssZ"
    /// same as DateTimeSec including milliseconds (1997-07-16T19:20:30.45+01:00)
    case DateTimeMilliSec = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    
    /**
    designated initializer
    
    - parameter dateString: a date string
    
    - returns: a formatted ISO8601 Format
    */
    init(dateString: String) {
        switch dateString.characters.count {
        case 4:
            self = ISO8601Format(rawValue: ISO8601Format.Year.rawValue)!
        case 7:
            self = ISO8601Format(rawValue: ISO8601Format.YearMonth.rawValue)!
        case 10:
            self = ISO8601Format(rawValue: ISO8601Format.Date.rawValue)!
        case 22:
            self = ISO8601Format(rawValue: ISO8601Format.DateTime.rawValue)!
        case 25:
            self = ISO8601Format(rawValue: ISO8601Format.DateTimeSec.rawValue)!
        default:// 28:
            self = ISO8601Format(rawValue: ISO8601Format.DateTimeMilliSec.rawValue)!
        }
    }
}


/**
 Date format enum
 
 - ISO8601: ISO8601 Date format
 - DotNet:  DotNet Date format
 - RSS:     RSS Date format
 - AltRSS:  AltRSS Date format
 - Custom:  Custom Date format
 */
public enum DateFormat {
    /// ISO8601 Date format
    case ISO8601(ISO8601Format?)
    /// DotNet Date format
    case DotNet
    /// RSS Date format
    case RSS
    /// AltRSS Date format
    case AltRSS
    /// Custom Date format
    case Custom(String)
}

public extension Date {
    
    // MARK: Intervals In Seconds
    private static func minuteInSeconds() -> Double { return 60 }
    private static func hourInSeconds() -> Double { return 3600 }
    private static func dayInSeconds() -> Double { return 86400 }
    private static func weekInSeconds() -> Double { return 604800 }
    private static func yearInSeconds() -> Double { return 31556926 }
    
    // MARK: Components
    private static func componentFlags() -> Calendar.Unit { return [Calendar.Unit.year, Calendar.Unit.month, Calendar.Unit.day, Calendar.Unit.weekOfYear, Calendar.Unit.hour, Calendar.Unit.minute, Calendar.Unit.second, Calendar.Unit.weekday, Calendar.Unit.weekdayOrdinal, Calendar.Unit.weekOfYear] }
    
    private static func components(fromDate: Date) -> DateComponents! {
        return Calendar.current().components(Date.componentFlags(), from: fromDate)
    }
    
    private func components() -> DateComponents {
        return Date.components(fromDate: self)!
    }
    
    // MARK: Date From String
    
    /**
    Creates a date based on a string and a formatter type. You can ise .ISO8601(nil) to for deducting an ISO8601Format automatically.
    
    - Parameter fromString Date string i.e. "16 July 1972 6:12:00".
    - Parameter format The Date Formatter type can be .ISO8601(ISO8601Format?), .DotNet, .RSS, .AltRSS or Custom(String).
    
    - Returns A new date
    */
    
    init(fromString string: String, format: DateFormat)
    {
        if string.isEmpty {
            self.init()
            return
        }
        
        let string = string as NSString
        
        switch format {
            
        case .DotNet:
            
            let startIndex = string.range(of: "(").location + 1
            let endIndex = string.range(of: ")").location
            let range = NSRange(location: startIndex, length: endIndex-startIndex)
            let milliseconds = (string.substring(with: range) as NSString).longLongValue
            let interval = TimeInterval(milliseconds / 1000)
            self.init(timeIntervalSince1970: interval)
            
        case .ISO8601(let isoFormat):
            
            let dateFormat = (isoFormat != nil) ? isoFormat! : ISO8601Format(dateString: string as String)
            let formatter = Date.formatter(format: dateFormat.rawValue)
            formatter.locale = Locale(localeIdentifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.local()
            formatter.dateFormat = dateFormat.rawValue
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval: 0, since: date)
            } else {
                self.init()
            }
            
        case .RSS:
            
            var s  = string
            if string.hasSuffix("Z") {
                s = s.substring(to: s.length-1) + "GMT"
            }
            let formatter = Date.formatter(format: RSSFormat)
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval:0, since:date)
            } else {
                self.init()
            }
            
        case .AltRSS:
            
            var s  = string
            if string.hasSuffix("Z") {
                s = s.substring(to: s.length-1) + "GMT"
            }
            let formatter = Date.formatter(format: AltRSSFormat)
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval:0, since:date)
            } else {
                self.init()
            }
            
        case .Custom(let dateFormat):
            
            let formatter = Date.formatter(format: dateFormat)
            if let date = formatter.date(from: string as String) {
                self.init(timeInterval:0, since:date)
            } else {
                self.init()
            }
        }
    }
    
    
    
    // MARK: Comparing Dates
    
    /**
    Returns true if dates are equal while ignoring time.
    
    - Parameter date: The Date to compare.
    */
    func isEqualToDateIgnoringTime(date: Date) -> Bool
    {
        guard let comp1 = Date.components(fromDate: self),
            let comp2 = Date.components(fromDate: date) else { return false }
        return ((comp1.year == comp2.year) && (comp1.month == comp2.month) && (comp1.day == comp2.day))
    }
    
    /**
    Returns Returns true if date is today.
    */
    func isToday() -> Bool
    {
        return self.isEqualToDateIgnoringTime(date: Date())
    }
    
    /**
    Returns true if date is tomorrow.
    */
    func isTomorrow() -> Bool
    {
        return self.isEqualToDateIgnoringTime(date: Date().dateByAdding(days: 1))
    }
    
    /**
    Returns true if date is yesterday.
    */
    func isYesterday() -> Bool
    {
        return self.isEqualToDateIgnoringTime(date: Date().dateByAdding(days: -1))
    }
    
    /**
    Returns true if date are in the same week.
     
    - Parameter date: The date to compare.
    */
    func isSameWeekAsDate(date: Date) -> Bool
    {
        guard let comp1 = Date.components(fromDate: self),
            let comp2 = Date.components(fromDate: date) else { return false }
        // Must be same week. 12/31 and 1/1 will both be week "1" if they are in the same week
        if comp1.weekOfYear != comp2.weekOfYear {
            return false
        }
        // Must have a time interval under 1 week
        return abs(self.timeIntervalSince(date)) < Date.weekInSeconds()
    }
    
    /**
    Returns true if date is this week.
    */
    func isThisWeek() -> Bool
    {
        return self.isSameWeekAsDate(date: Date())
    }
    
    /**
    Returns true if date is next week.
    */
    func isNextWeek() -> Bool
    {
        let interval: TimeInterval = Date().timeIntervalSinceReferenceDate + Date.weekInSeconds()
        let date = Date(timeIntervalSinceReferenceDate: interval)
        return self.isSameWeekAsDate(date: date)
    }
    
    /**
    Returns true if date is last week.
    */
    func isLastWeek() -> Bool
    {
        let interval: TimeInterval = Date().timeIntervalSinceReferenceDate - Date.weekInSeconds()
        let date = Date(timeIntervalSinceReferenceDate: interval)
        return self.isSameWeekAsDate(date: date)
    }
    
    /**
    Returns true if dates are in the same year.
    
    - Parameter date: The date to compare.
    */
    func isSameYearAs(date: Date) -> Bool
    {
        guard let comp1 = Date.components(fromDate: self),
            let comp2 = Date.components(fromDate: date) else { return false }
        return (comp1.year == comp2.year)
    }
    
    /**
    Returns true if date is this year.
    */
    func isThisYear() -> Bool
    {
        return self.isSameYearAs(date: Date())
    }
    
    /**
    Returns true if date is next year.
    */
    func isNextYear() -> Bool
    {
        guard let comp1 = Date.components(fromDate: self),
            let comp2 = Date.components(fromDate: Date()),
            let comp1year = comp1.year, let comp2year = comp2.year else { return false }
        return (comp1year == comp2year + 1)
    }
    
    /**
    Returns true if date is last year.
    */
    func isLastYear() -> Bool
    {
        guard let comp1 = Date.components(fromDate: self),
            let comp2 = Date.components(fromDate: Date()),
            let comp1year = comp1.year, let comp2year = comp2.year else { return false }
        return (comp1year == comp2year - 1)
    }
    
    /**
    Returns true if date is earlier than date.
    
    - Parameter date: The date to compare.
    */
    func isEarlierThan(date: Date) -> Bool
    {
        return self.compare(date) == ComparisonResult.orderedAscending
    }
    
    /**
     Returns true if date is later than date.
     
     - Parameter date: The date to compare.
     */
    func isLaterThan(date: Date) -> Bool
    {
        return self.compare(date) == ComparisonResult.orderedDescending
    }
    
    /**
    Returns true if date is in future.
    */
    func isInFuture() -> Bool
    {
        return self.isLaterThan(date: Date())
    }
    
    /**
    Returns true if date is in past.
    */
    func isInPast() -> Bool
    {
        return self.isEarlierThan(date: Date())
    }
    
    
    // MARK: Adjusting Dates
    
    /**
    Creates a new date by adding years
    
    - parameter years: The number of years to add. pass negative values for getting dates in the past
    
    - returns: A new date object
    */
    func dateByAdding(years: Int) -> Date? {
        return Calendar.current().date(byAdding: .year, value: years, to: self, options: Calendar.Options(rawValue: 0))
    }
    
    /**
    Creates a new date by a adding days.
    
    - Parameter days: The number of days to add.
    - Returns A new date object.
    */
    func dateByAdding(days: Int) -> Date
    {
        return Calendar.current().date(byAdding: .day, value: days, to: self, options: Calendar.Options(rawValue: 0))!
    }
    
    /**
    Creates a new date by a adding hours.
    
    - Parameter days: The number of hours to add.
    - Returns A new date object.
    */
    func dateByAdding(hours: Int) -> Date
    {
        return Calendar.current().date(byAdding: .hour, value: hours, to: self, options: Calendar.Options(rawValue: 0))!
    }
    
    /**
    Creates a new date by adding minutes.
    
    - Parameter days: The number of minutes to add.
    - Returns A new date object.
    */
    func dateByAdding(minutes: Int) -> Date
    {
        return Calendar.current().date(byAdding: .minute, value: minutes, to: self, options: Calendar.Options(rawValue: 0))!
    }
    
    /**
     Creates a new date by adding seconds.
     
     - Parameter seconds: The number of seconds to add.
     - Returns A new date object.
     */
    func dateByAdding(seconds: Int) -> Date
    {
        return Calendar.current().date(byAdding: .second, value: seconds, to: self, options: Calendar.Options(rawValue: 0))!
    }
    
    /**
    Creates a new date from the start of the day.
    
    - Returns A new date object.
    */
    func dateAtStartOfDay() -> Date
    {
        var components = self.components()
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current().date(from: components)!
    }
    
    /**
    Creates a new date from the end of the day.
    
    - Returns A new date object.
    */
    func dateAtEndOfDay() -> Date
    {
        var components = self.components()
        components.hour = 23
        components.minute = 59
        components.second = 59
        return Calendar.current().date(from: components)!
    }
    
    /**
    Creates a new date from the start of the week.
    
    - Returns A new date object.
    */
    func dateAtStartOfWeek() -> Date
    {
        let flags :Calendar.Unit = [Calendar.Unit.year, Calendar.Unit.month, Calendar.Unit.weekOfYear, Calendar.Unit.weekday]
        var components = Calendar.current().components(flags, from: self)
        components.weekday = Calendar.current().firstWeekday
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current().date(from: components)!
    }
    
    /**
    Creates a new date from the end of the week.
    
    - Returns A new date object.
    */
    func dateAtEndOfWeek() -> Date
    {
        let flags :Calendar.Unit = [Calendar.Unit.year, Calendar.Unit.month, Calendar.Unit.weekOfYear, Calendar.Unit.weekday]
        var components = Calendar.current().components(flags, from: self)
        components.weekday = Calendar.current().firstWeekday + 6
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current().date(from: components)!
    }
    
    /**
    Creates a new date from the first day of the month
    
    - Returns A new date object.
    */
    func dateAtTheStartOfMonth() -> Date
    {
        //Create the date components
        var components = self.components()
        components.day = 1
        //Builds the first day of the month
        let firstDayOfMonthDate :Date = Calendar.current().date(from: components)!
        
        return firstDayOfMonthDate
        
    }
    
    /**
    Creates a new date from the last day of the month
    
    - Returns A new date object.
    */
    func dateAtTheEndOfMonth() -> Date? {
        
        //Create the date components
        var components = self.components()
        //Set the last day of this month
        components.month? += 1
        components.day = 0
        
        //Builds the first day of the month
        let lastDayOfMonth :Date = Calendar.current().date(from: components)!
        
        return lastDayOfMonth
        
    }
    
    /**
     Creates a new date based on tomorrow.
     
     - Returns A new date object.
     */
    static func tomorrow() -> Date
    {
        return Date().dateByAdding(days: 1).dateAtStartOfDay()
    }
    
    /**
     Creates a new date based on yesterdat.
     
     - Returns A new date object.
     */
    static func yesterday() -> Date
    {
        return Date().dateByAdding(days: -1).dateAtStartOfDay()
    }
    
    
    // MARK: Retrieving Intervals
    
    /**
    Gets the number of seconds after a date.
    
    - Parameter date: the date to compare.
    - Returns The number of seconds
    */
    func secondsAfterDate(date: Date) -> Int
    {
        return Int(self.timeIntervalSince(date))
    }
    
    /**
     Gets the number of seconds before a date.
     
     - Parameter date: The date to compare.
     - Returns The number of seconds
     */
    func secondsBeforeDate(date: Date) -> Int
    {
        return Int(date.timeIntervalSince(self))
    }
    
    /**
    Gets the number of minutes after a date.
    
    - Parameter date: the date to compare.
    - Returns The number of minutes
    */
    func minutesAfterDate(date: Date) -> Int
    {
        let interval = self.timeIntervalSince(date)
        return Int(interval / Date.minuteInSeconds())
    }
    
    /**
    Gets the number of minutes before a date.
    
    - Parameter date: The date to compare.
    - Returns The number of minutes
    */
    func minutesBeforeDate(date: Date) -> Int
    {
        let interval = date.timeIntervalSince(self)
        return Int(interval / Date.minuteInSeconds())
    }
    
    /**
    Gets the number of hours after a date.
    
    - Parameter date: The date to compare.
    - Returns The number of hours
    */
    func hoursAfterDate(date: Date) -> Int
    {
        let interval = self.timeIntervalSince(date)
        return Int(interval / Date.hourInSeconds())
    }
    
    /**
    Gets the number of hours before a date.
    
    - Parameter date: The date to compare.
    - Returns The number of hours
    */
    func hoursBeforeDate(date: Date) -> Int
    {
        let interval = date.timeIntervalSince(self)
        return Int(interval / Date.hourInSeconds())
    }
    
    /**
    Gets the number of days after a date.
    
    - Parameter date: The date to compare.
    - Returns The number of days
    */
    func daysAfterDate(date: Date) -> Int
    {
        let interval = self.timeIntervalSince(date)
        return Int(interval / Date.dayInSeconds())
    }
    
    /**
    Gets the number of days before a date.
    
    - Parameter date: The date to compare.
    - Returns The number of days
    */
    func daysBeforeDate(date: Date) -> Int
    {
        let interval = date.timeIntervalSince(self)
        return Int(interval / Date.dayInSeconds())
    }
    
    
    // MARK: Decomposing Dates
    
    /**
    Returns the nearest hour.
    */
    func nearestHour () -> Int? {
        let halfHour = Date.minuteInSeconds() * 30
        var interval = self.timeIntervalSinceReferenceDate
        if  self.seconds() < 30 {
            interval -= halfHour
        } else {
            interval += halfHour
        }
        let date = Date(timeIntervalSinceReferenceDate: interval)
        return date.hour()
    }
    /**
    Returns the year component.
    */
    func year () -> Int? { return self.components().year  }
    /**
    Returns the month component.
    */
    func month () -> Int? { return self.components().month }
    /**
    Returns the week of year component.
    */
    func week () -> Int? { return self.components().weekOfYear }
    /**
    Returns the day component.
    */
    func day () -> Int? { return self.components().day }
    /**
    Returns the hour component.
    */
    func hour () -> Int? { return self.components().hour }
    /**
    Returns the minute component.
    */
    func minute () -> Int? { return self.components().minute }
    /**
    Returns the seconds component.
    */
    func seconds () -> Int? { return self.components().second }
    /**
    Returns the weekday component.
    */
    func weekday () -> Int? { return self.components().weekday }
    /**
    Returns the nth days component. e.g. 2nd Tuesday of the month is 2.
    */
    func nthWeekday () -> Int? { return self.components().weekdayOrdinal }
    /**
    Returns the days of the month.
    */
    func monthDays () -> Int { return Calendar.current().range(of: Calendar.Unit.day, in: Calendar.Unit.month, for: self).length }
    /**
    Returns the first day of the week.
    */
    func firstDayOfWeek () -> Int? {
        let distanceToStartOfWeek = Date.dayInSeconds() * Double(self.components().weekday! - 1)
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek
        return Date(timeIntervalSinceReferenceDate: interval).day()
    }
    /**
    Returns the last day of the week.
    */
    func lastDayOfWeek () -> Int? {
        let distanceToStartOfWeek = Date.dayInSeconds() * Double(self.components().weekday! - 1)
        let distanceToEndOfWeek = Date.dayInSeconds() * Double(7)
        let interval: TimeInterval = self.timeIntervalSinceReferenceDate - distanceToStartOfWeek + distanceToEndOfWeek
        return Date(timeIntervalSinceReferenceDate: interval).day()
    }
    /**
    Returns true if a weekday.
    */
    func isWeekday() -> Bool {
        return !self.isWeekend()
    }
    /**
    Returns true if weekend.
    */
    func isWeekend() -> Bool {
        let range = Calendar.current().maximumRange(of: Calendar.Unit.weekday)
        return (self.weekday() == range.location || self.weekday() == range.length)
    }
    
    
    // MARK: To String
    
    /**
    A string representation using short date and time style.
    */
    func toString() -> String {
        return self.toString(dateStyle: .shortStyle, timeStyle: .shortStyle, doesRelativeDateFormatting: false)
    }
    
    /**
    A string representation based on a format.
    
    - Parameter format: The format of date can be .ISO8601(.ISO8601Format?), .DotNet, .RSS, .AltRSS or Custom(FormatString).
    - Returns The date string representation
    */
    func toString(format: DateFormat) -> String
    {
        var dateFormat: String
        switch format {
        case .DotNet:
            let offset = TimeZone.default().secondsFromGMT / 3600
            let nowMillis = 1000 * self.timeIntervalSince1970
            return  "/Date(\(nowMillis)\(offset))/"
        case .ISO8601(let isoFormat):
            dateFormat = (isoFormat != nil) ? isoFormat!.rawValue : ISO8601Format.DateTimeMilliSec.rawValue
        case .RSS:
            dateFormat = RSSFormat
        case .AltRSS:
            dateFormat = AltRSSFormat
        case .Custom(let string):
            dateFormat = string
        }
        let formatter = Date.formatter(format: dateFormat)
        return formatter.string(from: self)
    }
    
    /**
    A string representation based on custom style.
    
    - Parameter dateStyle: The date style to use.
    - Parameter timeStyle: The time style to use.
    - Parameter doesRelativeDateFormatting: Enables relative date formatting.
    - Returns A string representation of the date.
    */
    func toString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, doesRelativeDateFormatting: Bool = false) -> String
    {
        let formatter = Date.formatter(dateStyle: dateStyle, timeStyle: timeStyle, doesRelativeDateFormatting: doesRelativeDateFormatting)
        return formatter.string(from: self)
    }
    
    /**
    A string representation based on a relative time language. i.e. just now, 1 minute ago etc..
    */
    func relativeTimeToString() -> String
    {
        let time = self.timeIntervalSince1970
        let now = Date().timeIntervalSince1970
        
        let seconds = now - time
        let minutes = round(seconds/60)
        let hours = round(minutes/60)
        let days = round(hours/24)
        
        if seconds < 10 {
            return NSLocalizedString("just now", comment: "Show the relative time from a date")
        } else if seconds < 60 {
            let relativeTime = NSLocalizedString("%.f seconds ago", comment: "Show the relative time from a date")
            return String(format: relativeTime, seconds)
        }
        
        if minutes < 60 {
            if minutes == 1 {
                return NSLocalizedString("1 minute ago", comment: "Show the relative time from a date")
            } else {
                let relativeTime = NSLocalizedString("%.f minutes ago", comment: "Show the relative time from a date")
                return String(format: relativeTime, minutes)
            }
        }
        
        if hours < 24 {
            if hours == 1 {
                return NSLocalizedString("1 hour ago", comment: "Show the relative time from a date")
            } else {
                let relativeTime = NSLocalizedString("%.f hours ago", comment: "Show the relative time from a date")
                return String(format: relativeTime, hours)
            }
        }
        
        if days < 7 {
            if days == 1 {
                return NSLocalizedString("1 day ago", comment: "Show the relative time from a date")
            } else {
                let relativeTime = NSLocalizedString("%.f days ago", comment: "Show the relative time from a date")
                return String(format: relativeTime, days)
            }
        }
        
        return self.toString()
    }
    
    /**
    A string representation of the weekday.
    */
    func weekdayToString() -> String {
        let formatter = Date.formatter()
        return formatter.weekdaySymbols[self.weekday()! - 1] as String
    }
    
    /**
    A short string representation of the weekday.
    */
    func shortWeekdayToString() -> String {
        let formatter = Date.formatter()
        return formatter.shortWeekdaySymbols[self.weekday()! - 1] as String
    }
    
    /**
    A very short string representation of the weekday.
    
    - Returns String
    */
    func veryShortWeekdayToString() -> String {
        let formatter = Date.formatter()
        return formatter.veryShortWeekdaySymbols[self.weekday()! - 1] as String
    }
    
    /**
    A string representation of the month.
    
    - Returns String
    */
    func monthToString() -> String {
        let formatter = Date.formatter()
        return formatter.monthSymbols[self.month()! - 1] as String
    }
    
    /**
    A short string representation of the month.
    
    - Returns String
    */
    func shortMonthToString() -> String {
        let formatter = Date.formatter()
        return formatter.shortMonthSymbols[self.month()! - 1] as String
    }
    
    /**
    A very short string representation of the month.
    
    - Returns String
    */
    func veryShortMonthToString() -> String {
        let formatter = Date.formatter()
        return formatter.veryShortMonthSymbols[self.month()! - 1] as String
    }
    
    
    // MARK: Static Cached Formatters
    
    /**
    Returns a cached formatter based on the format, timeZone and locale. Formatters are cached in a singleton array using hashkeys generated by format, timeZone and locale.
    
    - Parameter format: The format to use.
    - Parameter timeZone: The time zone to use, defaults to the local time zone.
    - Parameter locale: The locale to use, defaults to the current locale
    - Returns The date formatter.
    */
    private static func formatter(format:String = DefaultFormat, timeZone: TimeZone = TimeZone.local(), locale: Locale = Locale.current()) -> DateFormatter {
        let hashKey = "\(format.hashValue)\(timeZone.hashValue)\(locale.hashValue)"
        var formatters = sharedDateFormatters
        if let cachedDateFormatter = formatters[hashKey] {
            return cachedDateFormatter
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = timeZone
            formatter.locale = locale
            formatters[hashKey] = formatter
            return formatter
        }
    }
    
    /**
    Returns a cached formatter based on date style, time style and relative date. Formatters are cached in a singleton array using hashkeys generated by date style, time style, relative date, timeZone and locale.
    
    - Parameter dateStyle: The date style to use.
    - Parameter timeStyle: The time style to use.
    - Parameter doesRelativeDateFormatting: Enables relative date formatting.
    - Parameter timeZone: The time zone to use.
    - Parameter locale: The locale to use.
    - Returns The date formatter.
    */
    private static func formatter(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, doesRelativeDateFormatting: Bool, timeZone: TimeZone = TimeZone.local(), locale: Locale = Locale.current()) -> DateFormatter {
        var formatters = sharedDateFormatters
        let hashKey = "\(dateStyle.hashValue)\(timeStyle.hashValue)\(doesRelativeDateFormatting.hashValue)\(timeZone.hashValue)\(locale.hashValue)"
        if let cachedDateFormatter = formatters[hashKey] {
            return cachedDateFormatter
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
            formatter.doesRelativeDateFormatting = doesRelativeDateFormatting
            formatter.timeZone = timeZone
            formatter.locale = locale
            formatters[hashKey] = formatter
            return formatter
        }
    }
    
    
    
}
