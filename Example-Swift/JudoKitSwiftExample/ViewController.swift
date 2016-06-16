//
//  ViewController.swift
//  JudoPayDemoSwift
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
import PassKit
import JudoKit

enum TableViewContent : Int {
    case Payment = 0, PreAuth, CreateCardToken, RepeatPayment, TokenPreAuth, ApplePayPayment, ApplePayPreAuth
    
    static func count() -> Int {
        return 7
    }
    
    func title() -> String {
        switch self {
        case .Payment:
            return "Payment"
        case .PreAuth:
            return "PreAuth"
        case .CreateCardToken:
            return "Add card"
        case .RepeatPayment:
            return "Token payment"
        case .TokenPreAuth:
            return "Token preAuth"
        case .ApplePayPayment:
            return "ApplePay payment"
        case .ApplePayPreAuth:
            return "ApplePay preAuth"
        }
    }
    
    func subtitle() -> String {
        switch self {
        case .Payment:
            return "with default settings"
        case .PreAuth:
            return "to reserve funds on a card"
        case .CreateCardToken:
            return "to be stored for future transactions"
        case .RepeatPayment:
            return "with a stored card token"
        case .TokenPreAuth:
            return "with a stored card token"
        case .ApplePayPayment:
            return "make a payment using ApplePay"
        case .ApplePayPreAuth:
            return "make a preAuth using ApplePay"
        }
    }
    
}

let token               = "hkDjZ1Sgt7ZtdHJx"
let secret              = "607d4559c6d3b2ce1a1a3df4c48767dbe38e38eb342ca95bae25fdedf6e042ad"

let judoId              = "100972777"
let tokenPayReference   = "<#YOUR REFERENCE#>"


class ViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    static let kCellIdentifier = "com.judo.judopaysample.tableviewcellidentifier"
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var settingsViewBottomConstraint: NSLayoutConstraint!
    
    var cardDetails: CardDetails?
    var paymentToken: PaymentToken?
    
    var alertController: UIAlertController?
    
    var currentCurrency: Currency = .GBP
    
    var isTransactingApplePayPreAuth = false
    
    var judoKitSession = JudoKit(token: token, secret: secret)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.judoKitSession.theme.acceptedCardNetworks = [Card.Configuration(.Visa, 16), Card.Configuration(.MasterCard, 16), Card.Configuration(.Maestro, 16), Card.Configuration(.AMEX, 15)]
        
        self.judoKitSession.setSandboxed(enabled: true)
        
        self.judoKitSession.theme.showSecurityMessage = true
        
        self.tableView.backgroundColor = UIColor.clear()
        
        self.tableView.tableFooterView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 50))
            let label = UILabel(frame: CGRect(x: 15, y: 15, width: self.view.bounds.size.width - 30, height: 50))
            label.numberOfLines = 2
            label.text = "To view test card details:\nSign in to judo and go to Developer/Tools."
            label.font = UIFont.systemFont(ofSize: 12.0)
            label.textColor = UIColor.gray()
            view.addSubview(label)
            return view
            }()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let alertController = self.alertController {
            self.present(alertController, animated: true, completion: nil)
            self.alertController = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    @IBAction func settingsButtonHandler(sender: AnyObject) {
        if self.settingsViewBottomConstraint.constant != 0 {
            self.view.layoutIfNeeded()
            self.settingsViewBottomConstraint.constant = 0.0
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.tableView.alpha = 0.2
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func settingsButtonDismissHandler(sender: AnyObject) {
        if self.settingsViewBottomConstraint.constant == 0 {
            self.view.layoutIfNeeded()
            self.settingsViewBottomConstraint.constant = -190
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.tableView.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func segmentedControlValueChange(segmentedControl: UISegmentedControl) {
        if let selectedIndexTitle = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) {
            self.currentCurrency = Currency(selectedIndexTitle)
        }
    }
    
    @IBAction func AVSValueChanged(theSwitch: UISwitch) {
        self.judoKitSession.theme.avsEnabled = theSwitch.isOn
    }
    
    // TODO: need to think of a way to add or remove certain card type acceptance as samples
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableViewContent.count()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ViewController.kCellIdentifier, for: indexPath)
        cell.textLabel?.text = TableViewContent(rawValue: indexPath.row)?.title()
        cell.detailTextLabel?.text = TableViewContent(rawValue: indexPath.row)?.subtitle()
        return cell
    }
    
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let value = TableViewContent(rawValue: indexPath.row) else {
            return
        }
        
        switch value {
        case .Payment:
            paymentOperation()
        case .PreAuth:
            preAuthOperation()
        case .CreateCardToken:
            createCardTokenOperation()
        case .RepeatPayment:
            repeatPaymentOperation()
        case .TokenPreAuth:
            repeatPreAuthOperation()
        case .ApplePayPayment:
            applePayPayment()
        case .ApplePayPreAuth:
            applePayPreAuth()
        }
    }
    
    // MARK: Operations
    
    func paymentOperation() {
        guard let ref = Reference(consumerRef: "payment reference") else { return }
        try! self.judoKitSession.invokePayment(with: judoId, amount: Amount(decimalNumber: 35, currency: currentCurrency), reference: ref, completion: { (response) -> () in
            self.dismiss(animated: true, completion: nil)
            if let error = response.error {
                if error.code == .UserDidCancel {
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                var errorTitle = "Error"
                if let errorCategory = error.category {
                    errorTitle = errorCategory.stringValue()
                }
                self.alertController = UIAlertController(title: errorTitle, message: error.message, preferredStyle: .alert)
                self.alertController!.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.dismiss(animated: true, completion:nil)
                return // BAIL
            }
            
            if let value = response.value, transactionData = value.first {
                self.cardDetails = transactionData.cardDetails
                self.paymentToken = transactionData.paymentToken()
            }
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let viewController = sb.instantiateViewController(withIdentifier: "detailviewcontroller") as! DetailViewController
            viewController.response = response
            self.navigationController?.pushViewController(viewController, animated: true)
        })
    }
    
    func preAuthOperation() {
        guard let ref = Reference(consumerRef: "payment reference") else { return }
        let amount: Amount = "2 GBP"
        try! self.judoKitSession.invokePreAuth(with: judoId, amount: amount, reference: ref, completion: { (response) -> () in
            self.dismiss(animated: true, completion: nil)
            if let error = response.error {
                if error.code == .UserDidCancel {
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                var errorTitle = "Error"
                if let errorCategory = error.category {
                    errorTitle = errorCategory.stringValue()
                }
                self.alertController = UIAlertController(title: errorTitle, message: error.message, preferredStyle: .alert)
                self.alertController!.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.dismiss(animated: true, completion:nil)
                return // BAIL
            }
            if let value = response.value, transactionData = value.first {
                self.cardDetails = transactionData.cardDetails
                self.paymentToken = transactionData.paymentToken()
            }
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let viewController = sb.instantiateViewController(withIdentifier: "detailviewcontroller") as! DetailViewController
            viewController.response = response
            self.navigationController?.pushViewController(viewController, animated: true)
            })
    }
    
    func createCardTokenOperation() {
        guard let ref = Reference(consumerRef: "payment reference") else { return }
        try! self.judoKitSession.invokeRegisterCard(with: judoId, amount: Amount(decimalNumber: 1, currency: currentCurrency), reference: ref, completion: { (response) -> () in
            self.dismiss(animated: true, completion: nil)
            if let error = response.error {
                if error.code == .UserDidCancel {
                    self.dismiss(animated: true, completion: nil)
                    return
                }
                var errorTitle = "Error"
                if let errorCategory = error.category {
                    errorTitle = errorCategory.stringValue()
                }
                self.alertController = UIAlertController(title: errorTitle, message: error.message, preferredStyle: .alert)
                self.alertController!.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.dismiss(animated: true, completion:nil)
                return // BAIL
            }
            if let value = response.value, transactionData = value.first {
                self.cardDetails = transactionData.cardDetails
                self.paymentToken = transactionData.paymentToken()
            }
            })
    }
    
    func repeatPaymentOperation() {
        if let cardDetails = self.cardDetails, let payToken = self.paymentToken, let ref = Reference(consumerRef: "payment reference") {
            try! self.judoKitSession.invokeTokenPayment(with: judoId, amount: Amount(decimalNumber: 30, currency: currentCurrency), reference: ref, cardDetails: cardDetails, paymentToken: payToken, completion: { (response) -> () in
                self.dismiss(animated: true, completion: nil)
                if let error = response.error {
                    if error.code == .UserDidCancel {
                        self.dismiss(animated: true, completion: nil)
                        return
                    }
                    var errorTitle = "Error"
                    if let errorCategory = error.category {
                        errorTitle = errorCategory.stringValue()
                    }
                    self.alertController = UIAlertController(title: errorTitle, message: error.message, preferredStyle: .alert)
                    self.alertController!.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.dismiss(animated: true, completion:nil)
                    return // BAIL
                }
                if let value = response.value, transactionData = value.first {
                    self.cardDetails = transactionData.cardDetails
                    self.paymentToken = transactionData.paymentToken()
                }
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let viewController = sb.instantiateViewController(withIdentifier: "detailviewcontroller") as! DetailViewController
                viewController.response = response
                self.navigationController?.pushViewController(viewController, animated: true)
            })
        } else {
            let alert = UIAlertController(title: "Error", message: "you need to create a card token before making a repeat payment or preauth operation", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func repeatPreAuthOperation() {
        if let cardDetails = self.cardDetails, let payToken = self.paymentToken, let ref = Reference(consumerRef: "payment reference") {
            try! self.judoKitSession.invokeTokenPreAuth(with: judoId, amount: Amount(decimalNumber: 30, currency: currentCurrency), reference: ref, cardDetails: cardDetails, paymentToken: payToken, completion: { (response) -> () in
                self.dismiss(animated: true, completion: nil)
                if let error = response.error {
                    if error.code == .UserDidCancel {
                        self.dismiss(animated: true, completion: nil)
                        return
                    }
                    var errorTitle = "Error"
                    if let errorCategory = error.category {
                        errorTitle = errorCategory.stringValue()
                    }
                    self.alertController = UIAlertController(title: errorTitle, message: error.message, preferredStyle: .alert)
                    self.alertController!.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.dismiss(animated: true, completion:nil)
                    return // BAIL
                }
                if let value = response.value, transactionData = value.first {
                    self.cardDetails = transactionData.cardDetails
                    self.paymentToken = transactionData.paymentToken()
                }
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let viewController = sb.instantiateViewController(withIdentifier: "detailviewcontroller") as! DetailViewController
                viewController.response = response
                self.navigationController?.pushViewController(viewController, animated: true)
                })
        } else {
            let alert = UIAlertController(title: "Error", message: "you need to create a card token before making a repeat payment or preauth operation", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func applePayPayment() {
        self.isTransactingApplePayPreAuth = false
        self.initiateApplePay()
    }
    
    func applePayPreAuth() {
        self.isTransactingApplePayPreAuth = true
        self.initiateApplePay()
    }
    
    func initiateApplePay() {
        // Set up our payment request.
        let paymentRequest = PKPaymentRequest()
        
        /*
        Our merchant identifier needs to match what we previously set up in
        the Capabilities window (or the developer portal).
        */
        paymentRequest.merchantIdentifier = "<#YOUR-MERCHANT-ID#>"
        
        /*
        Both country code and currency code are standard ISO formats. Country
        should be the region you will process the payment in. Currency should
        be the currency you would like to charge in.
        */
        paymentRequest.countryCode = "GB"
        paymentRequest.currencyCode = "GBP"
        
        // The networks we are able to accept.
        paymentRequest.supportedNetworks = [PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa]
        
        /*
        we at Judo support 3DS
        */
        paymentRequest.merchantCapabilities = PKMerchantCapability.capability3DS
        
        /*
        An array of `PKPaymentSummaryItems` that we'd like to display on the
        sheet.
        */
        let items = [PKPaymentSummaryItem(label: "Sub-total", amount: NSDecimalNumber(string: "30.00 £"))]
        
        paymentRequest.paymentSummaryItems = items;
        
        // Request shipping information, in this case just postal address.
        paymentRequest.requiredShippingAddressFields = .postalAddress
        
        // Display the view controller.
        let viewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        viewController.delegate = self
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    // MARK: PKPaymentAuthorizationViewControllerDelegate
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        // WARNING: this can not be properly tested with the sandbox due to restrictions from Apple- if you need to test ApplePay you have to make actual valid transaction and then void them
        let completionBlock: (Response) -> () = { (response) -> () in
            self.dismiss(animated: true, completion: nil)
            if let _ = response.error {
                let alertCont = UIAlertController(title: "Error", message: "there was an error performing the operation", preferredStyle: .alert)
                alertCont.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertCont, animated: true, completion: nil)
                return // BAIL
            }
            if let value = response.value, transactionData = value.first {
                self.cardDetails = transactionData.cardDetails
                self.paymentToken = transactionData.paymentToken()
            }
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let viewController = sb.instantiateViewController(withIdentifier: "detailviewcontroller") as! DetailViewController
            viewController.response = response
            self.navigationController?.pushViewController(viewController, animated: true)
        }
        
        guard let ref = Reference(consumerRef: "consumer Reference") else { return }
        
        if self.isTransactingApplePayPreAuth {
            _ = try! self.judoKitSession.preAuth(with: judoId, amount: Amount(decimalNumber: 30, currency: currentCurrency), reference: ref).set(pkPayment: payment).execute(withCompletion: completionBlock)
        } else {
            _ = try! self.judoKitSession.payment(with: judoId, amount: Amount(decimalNumber: 30, currency: currentCurrency), reference: ref).set(pkPayment: payment).execute(withCompletion: completionBlock)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
