//
//  DateTextField.swift
//  JudoKit
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

import UIKit


/**
The DateTextField allows two different modes of input.

- Picker: Use a custom UIPickerView with month and year fields
- Text:   Use a common Numpad Keyboard as text input method
*/
public enum DateInputType {
    /// DateInputTypePicker using a UIPicker as an input method
    case Picker
    /// DateInputTypeText using a Keyboard as an input method
    case Text
}

/**
 
 The DateInputField is an input field configured to detect, validate and dates that are set to define a start or end date of various types of credit cards.
 
 */
public class DateInputField: JudoPayInputField {
    
    
    /// The datePicker showing months and years to pick from for expiry or start date input
    let datePicker = UIPickerView()
    
    
    /// The date formatter that shows the date in the same way it is written on a credit card
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter
    }()
    
    /// The current year on a Gregorian calendar
    private let currentYear = Calendar.current().component(.year, from: Date())
    /// The current month on a Gregorian calendar
    private let currentMonth = Calendar.current().component(.month, from: Date())
    
    
    /// Boolean stating whether input field should identify as a start or end date
    public var isStartDate: Bool = false {
        didSet {
            self.textField.attributedPlaceholder = AttributedString(string: self.title(), attributes: [NSForegroundColorAttributeName:self.theme.getPlaceholderTextColor()])
        }
    }
    
    
    /// Variable defining the input type (text or picker)
    public var dateInputType: DateInputType = .Text {
        didSet {
            switch dateInputType {
            case .Picker:
                self.textField.inputView = self.datePicker
                let month = NSString(format: "%02i", currentMonth)
                let year = NSString(format: "%02i", currentYear - 2000) // FIXME: not quite happy with this, must be a better way
                self.textField.text = "\(month)/\(year)"
                self.datePicker.selectRow(currentMonth - 1, inComponent: 0, animated: false)
                break
            case .Text:
                self.textField.inputView = nil
                self.textField.keyboardType = .numberPad
            }
        }
    }
    
    
    // MARK: Initializers
    
    
    /**
    Setup the view
    */
    override func setupView() {
        super.setupView()
        
        // Input method should be via date picker
        self.datePicker.delegate = self
        self.datePicker.dataSource = self
        
        if self.dateInputType == .Picker {
            self.textField.inputView = self.datePicker
            let month = NSString(format: "%02i", currentMonth)
            let year = NSString(format: "%02i", currentYear - 2000)
            self.textField.text = "\(month)/\(year)"
            self.datePicker.selectRow(currentMonth - 1, inComponent: 0, animated: false)
        }
    }
    
    
    // MARK: UITextFieldDelegate
    
    
    /**
    Delegate method implementation
    
    - parameter textField: Text field
    - parameter range:     Range
    - parameter string:    String
    
    - returns: boolean to change characters in given range for a textfield
    */
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Only handle calls if textinput is selected
        guard self.dateInputType == .Text else { return true }
        
        // Only handle delegate calls for own textfield
        guard textField == self.textField else { return false }
        
        // Get old and new text
        let oldString = textField.text!
        
        guard let indexedRange = oldString.range(from: range) else { return false }
        
        let newString = oldString.replacingCharacters(in: indexedRange, with: string)
        
        if newString.characters.count == 0 {
            return true
        } else if newString.characters.count == 1 {
            return newString == "0" || newString == "1"
        } else if newString.characters.count == 2 {
            // if deletion is handled and user is trying to delete the month no slash should be added
            guard string.characters.count > 0 else {
                return true
            }
            
            guard Int(newString) > 0 && Int(newString) <= 12 else {
                return false
            }
            
            self.textField.text = newString + "/"
            return false

        } else if newString.characters.count == 3 {
            return newString.characters.last == "/"
        } else if newString.characters.count == 4 {
            // FIXME: need to make sure that number is numeric
            let deciYear = Int((Double(Calendar.current().component(.year, from: Date()) - 2000) / 10.0))
            let lastChar = Int(String(newString.characters.last!))
            
            if self.isStartDate {
                return lastChar == deciYear || lastChar == deciYear - 1
            } else {
                return lastChar == deciYear || lastChar == deciYear + 1
            }
            
        } else if newString.characters.count == 5 {
            return true
        } else {
            self.delegate?.dateInputField(self, didEncounter: JudoError(.InputLengthMismatchError))
            return false
        }
    }
    
    // MARK: Custom methods
    
    
    /**
    Check if this inputField is valid
    
    - returns: true if valid input
    */
    public override func isValid() -> Bool {
        guard let dateString = textField.text where dateString.characters.count == 5,
            let beginningOfMonthDate = self.dateFormatter.date(from: dateString) else { return false }
        if self.isStartDate {
            let minimumDate = Date().dateByAdding(years: -10)
            return beginningOfMonthDate.compare(Date()) == .orderedAscending && beginningOfMonthDate.compare(minimumDate!) == .orderedDescending
        } else {
            guard let endOfMonthDate = beginningOfMonthDate.dateAtTheEndOfMonth() else { return false }
            let maximumDate = Date().dateByAdding(years: 10)
            return endOfMonthDate.compare(Date()) == .orderedDescending && endOfMonthDate.compare(maximumDate!) == .orderedAscending
        }
    }
    
    
    /**
     Subclassed method that is called when textField content was changed
     
     - parameter textField: the textfield of which the content has changed
     */
    public override func textFieldDidChangeValue(in textField: UITextField) {
        super.textFieldDidChangeValue(in: textField)
        
        self.didChangeInputText()
        
        guard let text = textField.text where text.characters.count == 5 else { return }
        if self.dateFormatter.date(from: text) == nil { return }
        
        if self.isValid() {
            self.delegate?.dateInputField(self, didFindValidDate: textField.text!)
        } else {
            var errorMessage = "Check expiry date"
            if self.isStartDate {
                errorMessage = "Check start date"
            }
            self.delegate?.dateInputField(self, didEncounter: JudoError(.InvalidEntry, message: errorMessage))
        }
    }
    
    
    /**
     The placeholder string for the current inputField
     
     - returns: an Attributed String that is the placeholder of the receiver
     */
    public override func placeholder() -> AttributedString? {
        return AttributedString(string: self.title(), attributes: [NSForegroundColorAttributeName:self.theme.getPlaceholderTextColor()])
    }
    
    
    /**
     Title of the receiver inputField
     
     - returns: a string that is the title of the receiver
     */
    public override func title() -> String {
        return isStartDate ? "Start date" : "Expiry date"
    }
    
    
    /**
     Hint label text
     
     - returns: string that is shown as a hint when user resides in a inputField for more than 5 seconds
     */
    public override func hintLabelText() -> String {
        return "MM/YY"
    }

}


// MARK: UIPickerViewDataSource
extension DateInputField: UIPickerViewDataSource {
    
    
    /**
    Datasource method for datePickerView
    
    - parameter pickerView: PickerView that calls its delegate
    
    - returns: The number of components in the pickerView
    */
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    
    /**
     Datasource method for datePickerView
     
     - parameter pickerView: PickerView that calls its delegate
     - parameter component:  A given component
     
     - returns: number of rows in component
     */
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? 12 : 11
    }

}

// MARK: UIPickerViewDelegate

extension DateInputField: UIPickerViewDelegate {
    
    /**
    Delegate method for datePickerView
    
    - parameter pickerView: The caller
    - parameter row:        The row
    - parameter component:  The component
    
    - returns: content of a given component and row
    */
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return NSString(format: "%02i", row + 1) as String
        case 1:
            return NSString(format: "%02i", (self.isStartDate ? currentYear - row : currentYear + row) - 2000) as String
        default:
            return nil
        }
    }
    
    
    /**
     Delegate method for datePickerView that had a given row in a component selected
     
     - parameter pickerView: The caller
     - parameter row:        The row
     - parameter component:  The component
     */
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Need to use NSString because Precision String Format Specifier is easier this way
        if component == 0 {
            let month = NSString(format: "%02i", row + 1)
            let oldDateString = self.textField.text!
            let year = oldDateString.substring(from: oldDateString.index(oldDateString.endIndex, offsetBy: -2))
            self.textField.text = "\(month)/\(year)"
        } else if component == 1 {
            let oldDateString = self.textField.text!
            let month = oldDateString.substring(to: oldDateString.index(oldDateString.startIndex, offsetBy: 2))
            let year = NSString(format: "%02i", (self.isStartDate ? currentYear - row : currentYear + row) - 2000)
            self.textField.text = "\(month)/\(year)"
        }
    }
    
}
