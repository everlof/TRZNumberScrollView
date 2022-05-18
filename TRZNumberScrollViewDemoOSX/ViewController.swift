//
//  ViewController.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa

class ViewController: NSSplitViewController, NumberScrollViewParametersViewControllerDelegate {

    var numberScrollViewContainer:NumberScrollViewContainerViewController!
    var parametersViewController:NumberScrollViewParametersViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberScrollViewContainer = splitViewItems[0].viewController as? NumberScrollViewContainerViewController
        parametersViewController = splitViewItems[1].viewController as? NumberScrollViewParametersViewController
        parametersViewController.delegate = self
        let numberScrollView = numberScrollViewContainer.numberScrollView
        numberScrollView?.text = parametersViewController.text
        numberScrollView?.animationDuration = parametersViewController.animationDuration
        numberScrollView?.animationCurve = parametersViewController.animationCurve
        numberScrollView?.setFont(parametersViewController.font, textColor: parametersViewController.textColor)
    }
    
    func parametersViewControllerDidCommit(_ sender: NumberScrollViewParametersViewController) {
        numberScrollViewContainer.numberScrollView.setText(parametersViewController.text, animated: parametersViewController.animationEnabled)
    }
    
    func parametersViewController(_ sender: NumberScrollViewParametersViewController, didChangeAnimationCurve animationCurve: CAMediaTimingFunction) {
        numberScrollViewContainer.numberScrollView.animationCurve = animationCurve
    }

    func parametersViewController(_ sender: NumberScrollViewParametersViewController, didChangeAnimationDuration animationDuration: TimeInterval) {
        numberScrollViewContainer.numberScrollView.animationDuration = animationDuration
    }
    
    func parametersViewController(_ sender: NumberScrollViewParametersViewController, didChangeFont font: NSFont) {
        numberScrollViewContainer.numberScrollView.font = font
    }
        
    func parametersViewController(_ sender: NumberScrollViewParametersViewController, didChangeTextColor textColor: NSColor) {
        numberScrollViewContainer.numberScrollView.textColor = textColor
    }
    
    func parametersViewController(_ sender: NumberScrollViewParametersViewController, didChangeAnimationDirection animationDirection: NumberScrollView.AnimationDirection) {
        numberScrollViewContainer.numberScrollView.animationDirection = animationDirection
    }
}


class NumberScrollViewContainerViewController: NSViewController {
    @IBOutlet weak var numberScrollView: NumberScrollView!
    @IBOutlet var backgroundColorView: BackgroundColorView!
    
    override func viewDidLoad() {
        backgroundColorView.backgroundColor = NSColor.white
        numberScrollView.backgroundColor = backgroundColorView.backgroundColor
    }
}

class BackgroundColorView: NSView {
    var backgroundColor:NSColor? {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        backgroundColor?.setFill()
        bounds.fill()
    }
}
