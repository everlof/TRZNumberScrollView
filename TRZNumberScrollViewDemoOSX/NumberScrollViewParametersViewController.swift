//
//  NumberScrollViewParametersViewController.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa

@objc protocol NumberScrollViewParametersViewControllerDelegate {
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeAnimationEnabled animationEnabled:Bool)
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeAnimationDuration animationDuration:TimeInterval)
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeAnimationCurve animationCurve:CAMediaTimingFunction)
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeText text:String)
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeFont font:NSFont)
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeTextColor textColor:NSColor)
    @objc optional func parametersViewController(_ sender:NumberScrollViewParametersViewController, didChangeAnimationDirection animationDirection:NumberScrollView.AnimationDirection)
    @objc optional func parametersViewControllerDidCommit(_ sender:NumberScrollViewParametersViewController)
}

class NumberScrollViewParametersViewController: NSViewController, NSControlTextEditingDelegate {

    @IBOutlet weak var animationCurveEditor: AnimationCurveEditor!
    @IBOutlet weak var upDirectionButton: NSButton!
    @IBOutlet weak var downDirectionButton: NSButton!
    
    weak var delegate:NumberScrollViewParametersViewControllerDelegate?

    @objc
    private(set) var animationEnabled: Bool = true {
        didSet {
            if oldValue != animationEnabled {
                delegate?.parametersViewController?(self, didChangeAnimationEnabled: animationEnabled)
            }
        }
    }

    @objc
    private(set) var text: String = "123456" {
        didSet {
            if oldValue != text {
                delegate?.parametersViewController?(self, didChangeText: text)
                if automaticallyCommit {
                    commit()
                }
            }
        }
    }

    @objc
    private(set) var animationDuration:TimeInterval = 1.0 {
        didSet {
            if oldValue != animationDuration {
                delegate?.parametersViewController?(self, didChangeAnimationDuration: animationDuration)
            }
        }
    }
    
    @objc
    var startControlPoint: ObservablePoint = ObservablePoint(x: 0, y: 0) {
        didSet {
            if oldValue != startControlPoint {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }
    
    @objc
    var endControlPoint: ObservablePoint = ObservablePoint(x: 0.1, y: 1)  {
        didSet {
            if oldValue != endControlPoint {
                delegate?.parametersViewController?(self, didChangeAnimationCurve: animationCurve)
            }
        }
    }

    @objc
    private(set) var font: NSFont = NSFont.systemFont(ofSize: 48) {
        didSet {
            if oldValue != font {
                delegate?.parametersViewController?(self, didChangeFont: font)
            }
        }
    }

    @objc
    private var displayFont:NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    @objc
    private(set) var textColor:NSColor = NSColor.black {
        didSet {
            if oldValue != textColor {
                delegate?.parametersViewController?(self, didChangeTextColor: textColor)
            }
        }
    }
    
    private(set) var animationDirection: NumberScrollView.AnimationDirection = .up {
        didSet {
            if oldValue != animationDirection {
                delegate?.parametersViewController?(self, didChangeAnimationDirection: animationDirection)
            }
        }
    }
    
    var animationCurve: CAMediaTimingFunction {
        return CAMediaTimingFunction(controlPoints: Float(startControlPoint.x), Float(startControlPoint.y), Float(endControlPoint.x), Float(endControlPoint.y))
    }
    
    @objc
    var automaticallyCommit:Bool = true
    
    func configureAnimationCurveEditor() {
        animationCurveEditor.startControlPointValue = self.startControlPoint.pointValue
        animationCurveEditor.endControlPointValue = self.endControlPoint.pointValue
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAnimationCurveEditor();


        animationCurveEditor.bind(NSBindingName("enabled"), to: self, withKeyPath: "animationEnabled", options: nil)
        let toNSValueOptions = [NSBindingOption.valueTransformer: ObservablePointToNSValueTransformer()]
        bind(NSBindingName("startControlPoint"), to: animationCurveEditor!, withKeyPath: "startControlPointValue", options: toNSValueOptions)
        bind(NSBindingName("endControlPoint"), to: animationCurveEditor!, withKeyPath: "endControlPointValue", options: toNSValueOptions)
    }
    
    @IBAction private func didEndEditingPointTextField(_ sender: NSTextField) {
        configureAnimationCurveEditor()
    }
    
    @objc func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let val = control.stringValue

        if val.isEmpty {
            return false
        }
        
        return true
    }
    
    @IBAction private func didChangeDirectionRadioButton(_ sender: NSButton) {
        animationDirection = (upDirectionButton.state == NSControl.StateValue.on) ? .up : .down
    }
    
    @IBAction private func didClickSetFont(_ sender: NSButton) {
        let fontManager = NSFontManager.shared
        fontManager.target = self
        fontManager.setSelectedFont(self.font, isMultiple: false)
        fontManager.orderFrontFontPanel(self)
    }


    @objc func changeFont(_ sender: Any?) {
        font = (sender as? NSFontManager)?.convert(font) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        displayFont = NSFont(descriptor: font.fontDescriptor, size: NSFont.systemFontSize)!
    }
    
    @objc private func changeAttributes(_ sender: AnyObject?) {
        textColor = (sender?.convertAttributes([String: AnyObject]())["NSColor"] as? NSColor) ?? NSColor.black
    }
    
    @IBAction private func didClickUpdate(_ sender: NSButton) {
        commit()
    }
    
    @IBAction private func didPressEnterOnTextField(_ sender: NSTextField) {
        commit()
    }
    
    private func commit() {
        delegate?.parametersViewControllerDidCommit?(self)
    }
}


@objc(TRZFontNameValueTransformer) class FontNameValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let font = value as? NSFont else { return nil }
        
        return String(format: "%@ %.1fpt", font.displayName ?? "(null)", font.pointSize)
    }
}

class ObservablePointToNSValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSValue.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let point = value as? ObservablePoint {
            return NSValue(point:CGPoint(x:point.x , y: point.y))
        } else if let point = (value as? NSValue)?.pointValue {
            return ObservablePoint(x: point.x, y: point.y)
        }
        return nil
    }
}

class ObservablePoint:NSObject {
    @objc
    var x: CGFloat = 0

    @objc
    var y: CGFloat = 0
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    var pointValue: CGPoint {
        return CGPoint(x: x, y: y)
    }
}
