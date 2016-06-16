//
//  JudoPayViewController.swift
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

import Foundation

/// A class which can be used to easily customize the SDKs view
public struct Theme {
    
    /// A tint color that is used to generate a theme for the judo payment form
    public var tintColor: UIColor = UIColor(red: 30/255, green: 120/255, blue: 160/255, alpha: 1.0)
    
    /// Set the address verification service to true to prompt the user to input his country and post code information
    public var avsEnabled: Bool = false
    
    /// a boolean indicating whether a security message should be shown below the input
    public var showSecurityMessage: Bool = false
    
    /// An array of accepted card configurations (card network and card number length)
    public var acceptedCardNetworks: [Card.Configuration] = [Card.Configuration(.AMEX, 15), Card.Configuration(.Visa, 16), Card.Configuration(.MasterCard, 16), Card.Configuration(.Maestro, 16)]
    
    
    // MARK: Buttons
    
    /// the title for the payment button
    public var paymentButtonTitle = "Pay"
    /// the title for the button when registering a card
    public var registerCardButtonTitle = "Add card"
    /// the title for the back button of the navigation controller
    public var registerCardNavBarButtonTitle = "Add"
    /// the title for the back button
    public var backButtonTitle = "Back"
    
    
    // MARK: Titles
    
    /// the title for a payment
    public var paymentTitle = "Payment"
    /// the title for a card registration
    public var registerCardTitle = "Add card"
    /// the title for a refund
    public var refundTitle = "Refund"
    /// the title for an authentication
    public var authenticationTitle = "Authentication"
    
    
    // MARK: Loading
    
    /// when a register card transaction is currently running
    public var loadingIndicatorRegisterCardTitle = "Adding card..."
    /// the title of the loading indicator during a transaction
    public var loadingIndicatorProcessingTitle = "Processing payment..."
    /// the title of the loading indicator during a redirect to a 3DS webview
    public var redirecting3DSTitle = "Redirecting..."
    /// the title of the loading indicator during the verification of the transaction
    public var verifying3DSPaymentTitle = "Verifying payment"
    /// the title of the loading indicator during the verification of the card registration
    public var verifying3DSRegisterCardTitle = "Verifying card"
    
    
    // MARK: Input fields
    
    /// the height of the input fields
    public var inputFieldHeight: CGFloat = 48
    
    // MARK: Security message
    
    /// the message that is shown below the input fields the ensure safety when entering card information
    public var securityMessageString = "Your card details are encrypted using SSL before transmission to our secure payment service provider. They will not be stored on this device or on our servers."
    
    /// the text size of the security message
    public var securityMessageTextSize: CGFloat = 12
    
    
    // MARK: Colors
    
    /**
     Helper method to identifiy whether to use a dark or light theme
     
     - returns: A boolean indicating to use dark or light mode
     */
    public func colorMode() -> Bool {
        return self.tintColor.greyScale() < 0.5
    }
    
    /// The default text color
    public var judoTextColor: UIColor?
    
    /// The default navigation bar title color
    public var judoNavigationBarTitleColor: UIColor?
    
    /// The color that is used for active input fields
    public var judoInputFieldTextColor: UIColor?
    
    /// The color that is used for the placeholders of the input fields
    public var judoPlaceholderTextColor: UIColor?
    
    /// The color that is used for the border color of the input fields
    public var judoInputFieldBorderColor: UIColor?
    
    /// The background color of the contentView
    public var judoContentViewBackgroundColor: UIColor?
    
    /// The button color
    public var judoButtonColor: UIColor?
    
    /// The title color of the button
    public var judoButtonTitleColor: UIColor?
    
    /// The background color of the loadingView
    public var judoLoadingBackgroundColor: UIColor?
    
    /// The color that is used when an error occurs during entry
    public var judoErrorColor: UIColor?
    
    /// The color of the block that is shown when something is loading
    public var judoLoadingBlockViewColor: UIColor?
    
    /// Input field background color
    public var judoInputFieldBackgroundColor: UIColor?
    
    
    /**
     The default text color
     
     - returns: A UIColor object
     */
    public func getTextColor() -> UIColor {
        if self.judoTextColor != nil {
            return self.judoTextColor!
        }
        let dgc = UIColor(red: 75/255, green: 75/255, blue: 75/255, alpha: 1.0)
        if self.colorMode() {
            return dgc
        } else {
            return dgc.inverse()
        }
    }
    
    
    /**
     The default text color
     
     - returns: A UIColor object
     */
    public func getNavigationBarTitleColor() -> UIColor {
        if self.judoNavigationBarTitleColor != nil {
            return self.judoNavigationBarTitleColor!
        }
        let dgc = UIColor(red: 75/255, green: 75/255, blue: 75/255, alpha: 1.0)
        if self.colorMode() {
            return dgc
        } else {
            return dgc.inverse()
        }
    }
    
    
    /**
     The color that is used for active input fields
     
     - returns: A UIColor object
     */
    public func getInputFieldTextColor() -> UIColor {
        return self.judoInputFieldTextColor ?? UIColor(red: 75/255, green: 75/255, blue: 75/255, alpha: 1.0)
    }
    
    
    /**
     The color that is used for the placeholders of the input fields
     
     - returns: A UIColor object
     */
    public func getPlaceholderTextColor() -> UIColor {
        if self.judoPlaceholderTextColor != nil {
            return self.judoPlaceholderTextColor!
        }
        let lgc = UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1.0)
        if self.colorMode() {
            return lgc
        } else {
            return lgc.inverse()
        }
    }
    
    
    /**
     The color that is used for the border color of the input fields
     
     - returns: A UIColor object
     */
    public func getInputFieldBorderColor() -> UIColor {
        return self.judoInputFieldBorderColor ?? UIColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 1.0)
    }
    
    
    /**
     The background color of the contentView
     
     - returns: A UIColor object
     */
    public func getContentViewBackgroundColor() -> UIColor {
        if self.judoContentViewBackgroundColor != nil {
            return self.judoContentViewBackgroundColor!
        }
        let gc = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        if self.colorMode() {
            return gc
        } else {
            return UIColor(red: 75/255, green: 75/255, blue: 75/255, alpha: 1)
        }
    }
    
    
    /**
     The button color
     
     - returns: A UIColor object
     */
    public func getButtonColor() -> UIColor {
        return self.judoButtonColor ?? self.tintColor
    }
    
    
    /**
     The title color of the button
     
     - returns: A UIColor object
     */
    public func getButtonTitleColor() -> UIColor {
        if self.judoButtonTitleColor != nil {
            return self.judoButtonTitleColor!
        }
        if self.colorMode() {
            return .white()
        } else {
            return .black()
        }
    }
    
    
    /**
     The background color of the loadingView
     
     - returns: A UIColor object
     */
    public func getLoadingBackgroundColor() -> UIColor {
        if self.judoLoadingBackgroundColor != nil {
            return self.judoLoadingBackgroundColor!
        }
        let lbc = UIColor(red: 210/255, green: 210/255, blue: 210/255, alpha: 0.8)
        if self.colorMode() {
            return lbc
        } else {
            return lbc.inverse()
        }
    }
    
    
    /**
     The color that is used when an error occurs during entry
     
     - returns: A UIColor object
     */
    public func getErrorColor() -> UIColor {
        return self.judoErrorColor ?? UIColor(red: 235/255, green: 55/255, blue: 45/255, alpha: 1.0)
    }
    
    
    /**
     The color of the block that is shown when something is loading
     
     - returns: A UIColor object
     */
    public func getLoadingBlockViewColor() -> UIColor {
        if self.judoLoadingBlockViewColor != nil {
            return self.judoLoadingBlockViewColor!
        }
        if self.colorMode() {
            return .white()
        } else {
            return .black()
        }
    }
    
    
    /**
     Input field background color
     
     - returns: A UIColor object
     */
    public func getInputFieldBackgroundColor() -> UIColor {
        return self.judoInputFieldBackgroundColor ?? .white()
    }
    
}
