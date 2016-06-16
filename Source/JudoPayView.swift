//
//  JudoPayView.swift
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


/// JudoPayView - the main view in the transaction journey
public class JudoPayView: UIView {
    
    /// The content view of the JudoPayView
    public let contentView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    let theme: Theme
    
    /// The card input field object
    let cardInputField: CardInputField
    /// The expiry date input field object
    let expiryDateInputField: DateInputField
    /// The secure code input field object
    let secureCodeInputField: SecurityInputField
    /// The start date input field object
    let startDateInputField: DateInputField
    /// The issue number input field object
    let issueNumberInputField: IssueNumberInputField
    /// The billing country input field object
    let billingCountryInputField: BillingCountryInputField
    /// The post code input field object
    let postCodeInputField: PostCodeInputField
    
    /// The card details object
    var cardDetails: CardDetails?
    
    /// The phantom keyboard height constraint
    var keyboardHeightConstraint: NSLayoutConstraint?
    
    /// The Maestro card fields (issue number and start date) height constraint
    var maestroFieldsHeightConstraint: NSLayoutConstraint?
    /// The billing country field height constraint
    var avsFieldsHeightConstraint: NSLayoutConstraint?
    /// the security messages top distance constraint
    var securityMessageTopConstraint: NSLayoutConstraint?
    
    // MARK: UI properties
    var isPaymentEnabled = false
    var currentKeyboardHeight: CGFloat = 0.0
    
    /// The hint label object
    let hintLabel: HintLabel
    
    /// the security message label that is shown if showSecurityMessage is set to true
    let securityMessageLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Can not initialize because self is not available at this point to set the target
    // Must be var? because can also not be initialized in init before self is available
    /// Payment navbar button
    var paymentNavBarButton: UIBarButtonItem?
    /// The payment button object
    var paymentButton: PayButton
    
    var loadingView: LoadingView
    let threeDSecureWebView = _DSWebView()
    
    /// The transactionType of the current journey
    var transactionType: TransactionType
    
    internal let isTokenPayment: Bool
    
    /**
     Designated initializer
     
     - parameter type:        The transactionType of this transaction
     - parameter cardDetails: Card details information if they have been passed
     
     - returns: a JudoPayView object
     */
    public init(type: TransactionType, currentTheme: Theme, cardDetails: CardDetails? = nil, isTokenPayment: Bool = false) {
        self.transactionType = type
        self.cardDetails = cardDetails
        self.theme = currentTheme
        self.hintLabel = HintLabel(currentTheme: currentTheme)
        self.paymentButton = PayButton(currentTheme: currentTheme)
        self.loadingView = LoadingView(currentTheme: currentTheme)

        self.cardInputField = CardInputField(theme: currentTheme)
        self.expiryDateInputField = DateInputField(theme: currentTheme)
        self.secureCodeInputField = SecurityInputField(theme: currentTheme)
        self.startDateInputField = DateInputField(theme: currentTheme)
        self.issueNumberInputField = IssueNumberInputField(theme: currentTheme)
        self.billingCountryInputField = BillingCountryInputField(theme: currentTheme)
        self.postCodeInputField = PostCodeInputField(theme: currentTheme)
        
        self.isTokenPayment = isTokenPayment
        
        super.init(frame: UIScreen.main().bounds)
        
        self.setupView()
        
        NotificationCenter.default().addObserver(self, selector: #selector(JudoPayView.keyboardWillShow(note:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default().addObserver(self, selector: #selector(JudoPayView.keyboardWillHide(note:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    /**
     Required initializer for the JudoPayView that will fail
     
     - parameter aDecoder: A Decoder
     
     - returns: a fatal error will be thrown as this class should not be retrieved by decoding
     */
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Keyboard notification configuration
    
    /**
    Deinitializer
    */
    deinit {
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /**
     This method will receive the height of the keyboard when the keyboard will appear to fit the size of the contentview accordingly
     
     - parameter note: the notification that calls this method
     */
    func keyboardWillShow(note: NSNotification) {
        guard UI_USER_INTERFACE_IDIOM() == .phone else { return } // BAIL
        
        guard let info = note.userInfo else { return } // BAIL
        
        guard let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey],
            let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] else { return } // BAIL
        
        guard let keyboardRect = info[UIKeyboardFrameEndUserInfoKey]?.cgRectValue else { return } // BAIL
        
        self.currentKeyboardHeight = keyboardRect.height
        
        self.keyboardHeightConstraint!.constant = -1 * keyboardRect.height + (self.isPaymentEnabled ? 0 : self.paymentButton.bounds.height)
        self.paymentButton.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: (animationCurve as! UInt)), animations: { () -> Void in
            self.paymentButton.layoutIfNeeded()
            }, completion: nil)
    }
    
    
    /**
     This method will receive the keyboard will disappear notification to fit the size of the contentview accordingly
     
     - parameter note: the notification that calls this method
     */
    func keyboardWillHide(note: NSNotification) {
        guard UI_USER_INTERFACE_IDIOM() == .phone else { return } // BAIL
        
        guard let info = note.userInfo else { return } // BAIL
        
        guard let animationCurve = info[UIKeyboardAnimationCurveUserInfoKey],
            let animationDuration = info[UIKeyboardAnimationDurationUserInfoKey] else { return } // BAIL
        
        self.currentKeyboardHeight = 0.0
        
        self.keyboardHeightConstraint!.constant = 0.0 + (self.isPaymentEnabled ? 0 : self.paymentButton.bounds.height)
        self.paymentButton.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: animationDuration.doubleValue, delay: 0.0, options:UIViewAnimationOptions(rawValue: (animationCurve as! UInt)), animations: { () -> Void in
            self.paymentButton.layoutIfNeeded()
            }, completion: nil)
    }
    
    // MARK: View LifeCycle
    
    func setupView() {
        let payButtonTitle = self.transactionType == .RegisterCard ? self.theme.registerCardTitle : self.theme.paymentButtonTitle
        self.loadingView.actionLabel.text = self.transactionType == .RegisterCard ? self.theme.loadingIndicatorRegisterCardTitle : self.theme.loadingIndicatorProcessingTitle
        
        let attributedString = NSMutableAttributedString(string: "Secure server: ", attributes: [NSForegroundColorAttributeName:self.theme.getTextColor(), NSFontAttributeName:UIFont.boldSystemFont(ofSize: self.theme.securityMessageTextSize)])
        attributedString.append(AttributedString(string: self.theme.securityMessageString, attributes: [NSForegroundColorAttributeName:self.theme.getTextColor(), NSFontAttributeName:UIFont.systemFont(ofSize: self.theme.securityMessageTextSize)]))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 3
        
        attributedString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        self.securityMessageLabel.attributedText = attributedString
        
        self.paymentButton.setTitle(payButtonTitle, for: UIControlState())
        
        self.startDateInputField.isStartDate = true
        
        // View
        self.addSubview(contentView)
        self.contentView.contentSize = self.bounds.size
        
        self.backgroundColor = self.theme.getContentViewBackgroundColor()
        
        self.contentView.addSubview(cardInputField)
        self.contentView.addSubview(startDateInputField)
        self.contentView.addSubview(issueNumberInputField)
        self.contentView.addSubview(expiryDateInputField)
        self.contentView.addSubview(secureCodeInputField)
        self.contentView.addSubview(billingCountryInputField)
        self.contentView.addSubview(postCodeInputField)
        self.contentView.addSubview(hintLabel)
        self.contentView.addSubview(securityMessageLabel)
        
        self.addSubview(paymentButton)
        self.addSubview(threeDSecureWebView)
        self.addSubview(loadingView)
        
        // Delegates
        self.cardInputField.delegate = self
        self.expiryDateInputField.delegate = self
        self.secureCodeInputField.delegate = self
        self.issueNumberInputField.delegate = self
        self.startDateInputField.delegate = self
        self.billingCountryInputField.delegate = self
        self.postCodeInputField.delegate = self
        
        self.hintLabel.font = UIFont.systemFont(ofSize: 14)
        self.hintLabel.numberOfLines = 3
        self.hintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[scrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["scrollView":contentView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]-1-[button]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["scrollView":contentView, "button":paymentButton]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[loadingView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["loadingView":loadingView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[loadingView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["loadingView":loadingView]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[tdsecure]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["tdsecure":threeDSecureWebView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(68)-[tdsecure]-(30)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["tdsecure":threeDSecureWebView]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[button]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["button":paymentButton]))
        self.paymentButton.addConstraint(NSLayoutConstraint(item: paymentButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50))
        
        self.keyboardHeightConstraint = NSLayoutConstraint(item: paymentButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: self.isPaymentEnabled ? 0 : 50)
        self.addConstraint(keyboardHeightConstraint!)
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-1)-[card]-(-1)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics:nil, views: ["card":cardInputField]))
        self.contentView.addConstraint(NSLayoutConstraint(item: cardInputField, attribute: NSLayoutAttribute.width, relatedBy: .equal, toItem: self.contentView, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 2))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-1)-[expiry]-(-1)-[security(==expiry)]-(-1)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["expiry":expiryDateInputField, "security":secureCodeInputField]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-1)-[start]-(-1)-[issue(==start)]-(-1)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["start":startDateInputField, "issue":issueNumberInputField]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-1)-[billing]-(-1)-[post(==billing)]-(-1)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["billing":billingCountryInputField, "post":postCodeInputField]))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[hint]-(12)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["hint":hintLabel]))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(12)-[securityMessage]-(12)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["securityMessage":securityMessageLabel]))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-75-[card(fieldHeight)]-(-1)-[start]-(-1)-[expiry(fieldHeight)]-(-1)-[billing]-(20)-[hint(18)]-(15)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: ["fieldHeight":self.theme.inputFieldHeight], views: ["card":cardInputField, "start":startDateInputField, "expiry":expiryDateInputField, "billing":billingCountryInputField, "hint":hintLabel]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-75-[card(fieldHeight)]-(-1)-[issue(==start)]-(-1)-[security(fieldHeight)]-(-1)-[post]-(20)-[hint]-(15)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: ["fieldHeight":self.theme.inputFieldHeight], views: ["card":cardInputField, "issue":issueNumberInputField, "start":startDateInputField, "security":secureCodeInputField, "post":postCodeInputField, "hint":hintLabel]))
        
        self.maestroFieldsHeightConstraint = NSLayoutConstraint(item: startDateInputField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0)
        self.avsFieldsHeightConstraint = NSLayoutConstraint(item: billingCountryInputField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0.0)
        self.securityMessageTopConstraint = NSLayoutConstraint(item: securityMessageLabel, attribute: .top, relatedBy: .equal, toItem: self.hintLabel, attribute: .bottom, multiplier: 1.0, constant: -self.hintLabel.bounds.height)
        
        self.securityMessageLabel.isHidden = !(self.theme.showSecurityMessage ?? false)
        
        self.startDateInputField.addConstraint(maestroFieldsHeightConstraint!)
        self.billingCountryInputField.addConstraint(avsFieldsHeightConstraint!)
        
        self.contentView.addConstraint(securityMessageTopConstraint!)
        
        // If card details are available, fill out the fields
        if let cardDetails = self.cardDetails, let formattedLastFour = cardDetails.formattedLastFour(), let expiryDate = cardDetails.formattedEndDate() {
            self.updateInputFields(withNetwork: cardDetails.cardNetwork)
            if !self.isTokenPayment, let presentationCardNumber = try? cardDetails._cardNumber?.cardPresentationString(self.theme.acceptedCardNetworks) {
                self.cardInputField.textField.text = presentationCardNumber
                self.cardInputField.textField.alpha = 1.0
                self.expiryDateInputField.textField.alpha = 1.0
            } else {
                self.cardInputField.textField.text = formattedLastFour
            }
            
            self.expiryDateInputField.textField.text = expiryDate
            self.updateInputFields(withNetwork: cardDetails.cardNetwork)
            self.secureCodeInputField.isTokenPayment = self.isTokenPayment
            self.cardInputField.isTokenPayment = self.isTokenPayment
            self.cardInputField.isUserInteractionEnabled = !self.isTokenPayment
            self.expiryDateInputField.isUserInteractionEnabled = !self.isTokenPayment
            self.cardInputField.textField.isSecureTextEntry = false
        }
    }
    
    /**
     This method is intended to toggle the start date and issue number fields visibility when a Card has been identified.
     
     - Discussion: Maestro cards need a start date or an issue number to be entered for making any transaction
     
     - parameter isVisible: Whether start date and issue number fields should be visible
     */
    public func setStartDate(visibility isVisible: Bool) {
        self.maestroFieldsHeightConstraint?.constant = isVisible ? self.theme.inputFieldHeight : 1
        self.issueNumberInputField.setNeedsUpdateConstraints()
        self.startDateInputField.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options:UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            self.issueNumberInputField.layoutIfNeeded()
            self.startDateInputField.layoutIfNeeded()
            
            self.expiryDateInputField.layoutIfNeeded()
            self.secureCodeInputField.layoutIfNeeded()
            }, completion: nil)
    }
    
    
    /**
     This method toggles the visibility of address fields (billing country and post code).
     
     - Discussion: If AVS is necessary, this should be activated. AVS only needs Postcode to verify
     
     - parameter isVisible:  Whether post code and billing country fields should be visible
     - parameter completion: Block that is called when animation was finished
     */
    public func setAVS(visibility isVisible: Bool, completion: (() -> ())? = nil) {
        self.avsFieldsHeightConstraint?.constant = isVisible ? self.theme.inputFieldHeight : 0
        self.billingCountryInputField.setNeedsUpdateConstraints()
        self.postCodeInputField.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.billingCountryInputField.layoutIfNeeded()
            self.postCodeInputField.layoutIfNeeded()
            }) { (didFinish) -> Void in
                if let completion = completion {
                    completion()
                }
        }
    }
    
    // MARK: Helpers
    
    
    /**
    When a network has been identified, the secure code text field has to adjust its title and maximum number entry to enable the payment
    
    - parameter network: The network that has been identified
    */
    func updateInputFields(withNetwork network: CardNetwork?) {
        guard let network = network else { return }
        self.cardInputField.cardNetwork = network
        self.cardInputField.updateCardLogo()
        self.secureCodeInputField.cardNetwork = network
        self.secureCodeInputField.updateCardLogo()
        self.secureCodeInputField.textField.placeholder = network.securityCodeTitle()
        self.setStartDate(visibility: network == .Maestro)
    }
    
    
    /**
    Helper method to enable the payment after all fields have been validated and entered
    
    - parameter enabled: Pass true to enable the payment buttons
    */
    func setPayment(enabled: Bool) {
        self.isPaymentEnabled = enabled
        self.paymentButton.isHidden = !enabled
        
        self.keyboardHeightConstraint?.constant = -self.currentKeyboardHeight + (isPaymentEnabled ? 0 : self.paymentButton.bounds.height)
        
        self.paymentButton.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options:enabled ? .curveEaseOut : .curveEaseIn, animations: { () -> Void in
            self.paymentButton.layoutIfNeeded()
        }, completion: nil)
        
        self.paymentNavBarButton!.isEnabled = enabled
    }
    
    
    /**
     The hint label has a timer that executes the visibility.
     
     - parameter input: The input field which the user is currently idling
     */
    func showHintAfterDefaultDelay(on input: JudoPayInputField) {
        if self.secureCodeInputField.isTokenPayment && self.secureCodeInputField.textField.text!.characters.count == 0 {
            self.hintLabel.show(hint: self.secureCodeInputField.hintLabelText())
        } else {
            self.hintLabel.hideHint()
        }
        self.updateSecurityMessagePosition(toggleUp: true)
        _ = Timer.schedule(delay: 3.0, handler: { (timer) -> Void in
            let hintLabelText = input.hintLabelText()
            if hintLabelText.characters.count > 0
                && input.textField.text?.characters.count == 0
                && input.textField.isFirstResponder() {
                
                self.updateSecurityMessagePosition(toggleUp: false)
                self.hintLabel.show(hint: input.hintLabelText())
            }
        })
    }
    
    
    /**
     Helper method to update the position of the security message
     
     - parameter toggleUp: whether the label should move up or down
     */
    func updateSecurityMessagePosition(toggleUp: Bool) {
        self.contentView.layoutIfNeeded()
        self.securityMessageTopConstraint?.constant = (toggleUp && !self.hintLabel.isActive()) ? -self.hintLabel.bounds.height : 14
        UIView.animate(withDuration: 0.3) { self.contentView.layoutIfNeeded() }
    }
    
}
