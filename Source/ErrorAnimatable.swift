//
//  ErrorAnimatable.swift
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


public protocol ErrorAnimatable {
    func animateErrorWiggle(showingRedBlock: Bool)
}

extension ErrorAnimatable where Self: JudoPayInputField {
    
    /**
     Helper method that will wiggle the input field and show a red line at the bottom in which is was executed
     
     - parameter redBlock: Boolean stating whether to show a red line at the bottom or not
     */
    public func animateErrorWiggle(showingRedBlock: Bool) {
        // Animate the red block on the bottom
        
        let blockAnimation = { (didFinish: Bool) -> Void in
            let contentViewAnimation = CAKeyframeAnimation()
            contentViewAnimation.keyPath = "position.x"
            contentViewAnimation.values = [0, 10, -8, 6, -4, 2, 0]
            var times = [0, (1 / 11.0), (3 / 11.0)]
            times.append((5 / 11.0))
            times.append((7 / 11.0))
            times.append((9 / 11.0))
            times.append(1)
            contentViewAnimation.keyTimes = times
            contentViewAnimation.duration = 0.4
            contentViewAnimation.isAdditive = true
            
            self.layer.add(contentViewAnimation, forKey: "wiggle")
        }
        
        if showingRedBlock {
            self.redBlock.frame = CGRect(x: 0, y: self.bounds.height, width: self.bounds.width, height: 4.0)
            
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.redBlock.frame = CGRect(x: 0, y: self.bounds.height - 4, width: self.bounds.width, height: 4.0)
                self.textField.textColor = self.theme.getErrorColor()
                }, completion: blockAnimation)
        } else {
            blockAnimation(true)
        }
    }
    
}
