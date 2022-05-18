//
//  AnimationCurveEditor.swift
//  TRZNumberScrollViewDemoOSX
//
//  Created by Thomas Zhao on 3/11/16.
//  Copyright © 2016 Thomas Zhao. All rights reserved.
//

import Cocoa


public class AnimationCurveEditor: NSControl {
    public var backgroundColor:NSColor? = NSColor.white {
        didSet { needsDisplay = true }
    }
    
    public var drawsGrid = true {
        didSet { needsDisplay = true }
    }
    
    public var gridDivisions:Int = 10 {
        didSet { needsDisplay = true }
    }
    
    public var gridStrokeColor = NSColor.gridColor {
        didSet { needsDisplay = true }
    }
    
    public var gridLineWidth:CGFloat = 1 {
        didSet { needsDisplay = true }
    }
    
    public var curveStrokeColor:NSColor = NSColor(for: .blueControlTint) {
        didSet { needsDisplay = true }
    }
    
    public var curveLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }
    
    public var handleStrokeColor:NSColor = NSColor.gray {
        didSet { needsDisplay = true }
    }
    
    public var handleLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }

    @objc
    public var startControlPointValue:CGPoint = CGPoint(x: 0, y: 0) {
        didSet { needsDisplay = true }
    }
    
    public var startControlPointKnobFillColor:NSColor = NSColor.white {
        didSet { needsDisplay = true }
    }

    public var startControlPointKnobLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }

    public var startControlPointKnobStrokeColor:NSColor = NSColor.red {
        didSet { needsDisplay = true }
    }
    
    @objc
    public var endControlPointValue:CGPoint = CGPoint(x: 1, y: 1) {
        didSet { needsDisplay = true }
    }
    
    public var endControlPointKnobLineWidth:CGFloat = 2 {
        didSet { needsDisplay = true }
    }

    public var endControlPointKnobFillColor:NSColor = NSColor.white {
        didSet { needsDisplay = true }
    }

    public var endControlPointKnobStrokeColor:NSColor = NSColor.blue {
        didSet { needsDisplay = true }
    }
    
    public var controlPointKnobDiameter:CGFloat = 5 {
        didSet { needsDisplay = true }
    }
    
    override public var isEnabled:Bool {
        didSet { panGestureRecognizer.isEnabled = isEnabled }
    }
    
    private var _target:AnyObject?
    private var _action:Selector? = nil
    private var panGestureRecognizer = NSPanGestureRecognizer();

    override public var target:AnyObject? {
        get { return _target }
        set { _target = newValue }
    }
    
    override public var action:Selector? {
        get { return _action }
        set { _action = newValue }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        panGestureRecognizer.target = self
        panGestureRecognizer.action = #selector(AnimationCurveEditor.panGestureRecognizerDidRecognize(_:))
        addGestureRecognizer(panGestureRecognizer)
    }
    
    private var startControlPointKnobIsOnTop = true
    
    private var adjustingStartControlPoint:Bool = false
    private var adjustingEndControlPoint:Bool = false
    
    @objc private func panGestureRecognizerDidRecognize(_ gestureRecognizer:NSPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: self)
            let checkStartControl:(CGFloat)->Bool = { tolerance in
                if self.startControlPointKnobBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(location) {
                    self.adjustingStartControlPoint = true
                    self.startControlPointKnobIsOnTop = true
                    return true
                }
                return false
            }
            
            let checkEndControl:(CGFloat)->Bool = { tolerance in
                if self.endControlPointKnobBounds.insetBy(dx: -tolerance, dy: -tolerance).contains(location) {
                    self.adjustingEndControlPoint = true
                    self.startControlPointKnobIsOnTop = false
                    return true
                }
                return false
            }
            
            if startControlPointKnobIsOnTop {
                if checkStartControl(0) { return }
                if checkEndControl(0) { return }
                if checkStartControl(10) { return }
                if checkEndControl(10) { return }
            } else {
                if checkEndControl(0) { return }
                if checkStartControl(0) { return }
                if checkEndControl(10) { return }
                if checkStartControl(10) { return }
            }
            
        } else if gestureRecognizer.state == .changed {
            if adjustingStartControlPoint || adjustingEndControlPoint {
                let location = gestureRecognizer.location(in: self)
                let relativePoint = CGPoint(x: (location.x - squareBounds.minX)/squareBounds.width, y: (location.y - squareBounds.minY)/squareBounds.height)
                
                let restrictedPoint = CGPoint(x: max(min(relativePoint.x, 1), 0), y: max(min(relativePoint.y, 1), 0))
                
                if adjustingStartControlPoint {
                    startControlPointValue = restrictedPoint
                } else if adjustingEndControlPoint {
                    endControlPointValue = restrictedPoint
                }
                
                sendAction(action, to: target)
            }
        } else if gestureRecognizer.state == .cancelled || gestureRecognizer.state == .ended {
            adjustingStartControlPoint = false
            adjustingEndControlPoint = false
        }
    }
    
    private var squareBounds:CGRect {
        let length = min(bounds.width, bounds.height)
        
        let squareSize = CGSize(width: length, height: length)
        let rect = CGRect(origin: CGPoint(x: (bounds.width - length)/2, y: (bounds.height - length)/2), size: squareSize).integral
        return rect
    }
    
    private func controlPointsForRect(_ rect:CGRect) -> (CGPoint, CGPoint) {
        let cp1x = startControlPointValue.x * rect.width + rect.minX
        let cp1y = startControlPointValue.y * rect.height + rect.minY
        let cp2x = endControlPointValue.x * rect.width + rect.minX
        let cp2y = endControlPointValue.y * rect.height + rect.minY
        return (CGPoint(x:cp1x, y:cp1y), CGPoint(x:cp2x, y:cp2y))
    }

    private var startControlPointKnobBounds:CGRect {
        let (control1, _) = controlPointsForRect(squareBounds)
        return CGRect(origin: control1, size: CGSize.zero).insetBy(dx: -controlPointKnobDiameter, dy: -controlPointKnobDiameter).integral
    }
    
    private var endControlPointKnobBounds:CGRect {
        let (_, control2) = controlPointsForRect(squareBounds)
        return CGRect(origin: control2, size: CGSize.zero).insetBy(dx: -controlPointKnobDiameter, dy: -controlPointKnobDiameter).integral
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let rect = squareBounds
        
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
            rect.fill()
        }
        
        if drawsGrid {
            drawGrid(rect)
        }
        
        drawCurve(rect)
        
        drawHandles(rect)
    }
    
    private func drawGrid(_ rect: CGRect) {
        guard gridDivisions > 0 else { return }
        
        let subLength = rect.width / CGFloat(gridDivisions)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.setStrokeColor(gridStrokeColor.cgColor)
        ctx.setLineWidth(gridLineWidth)
        ctx.stroke(rect.insetBy(dx: gridLineWidth / 2, dy: gridLineWidth / 2))
        
        for i in 1..<gridDivisions {
            let offset = CGFloat(i) * subLength
            ctx.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
            ctx.addLine(to: CGPoint(x: rect.minX + offset, y: rect.maxY))
            ctx.strokePath()
            
            ctx.move(to: CGPoint(x: rect.minX, y: rect.minY + offset))
            ctx.addLine(to: CGPoint(x: rect.maxY + rect.height, y: rect.minY  + offset))
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
    
    private func drawCurve(_ rect: CGRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.setStrokeColor(curveStrokeColor.cgColor)
        ctx.setLineWidth(curveLineWidth)
        ctx.move(to: CGPoint(x: rect.minX, y: rect.minY))
        let (control1, control2) = controlPointsForRect(rect)
        ctx.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control1: control1, control2: control2)
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    private func drawHandles(_ rect:CGRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        
        let (control1, control2) = controlPointsForRect(rect)
        
        let drawStartHandle = {
            ctx.setStrokeColor(self.handleStrokeColor.cgColor)
            ctx.setLineWidth(self.handleLineWidth)
            ctx.move(to: CGPoint(x: rect.minX, y: rect.minY))
            ctx.addLine(to: control1)
            ctx.strokePath()
            
            let startControlPointKnobBounds = self.startControlPointKnobBounds
            
            ctx.setFillColor(self.startControlPointKnobFillColor.cgColor)
            ctx.fillEllipse(in: startControlPointKnobBounds)
            let strokeColor = self.isEnabled ? self.startControlPointKnobStrokeColor : NSColor.disabledControlTextColor
            ctx.setStrokeColor(strokeColor.cgColor)
            ctx.setLineWidth(self.startControlPointKnobLineWidth)
            ctx.strokeEllipse(in: startControlPointKnobBounds)
        }
        
        let drawSecondHandle = {
            ctx.setStrokeColor(self.handleStrokeColor.cgColor)
            ctx.setLineWidth(self.handleLineWidth)
            ctx.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            ctx.addLine(to: control2)
            ctx.strokePath()

            let endControlPointKnobBounds = self.endControlPointKnobBounds
            ctx.setFillColor(self.endControlPointKnobFillColor.cgColor)
            ctx.fillEllipse(in: endControlPointKnobBounds)
            let strokeColor = self.isEnabled ? self.endControlPointKnobStrokeColor : NSColor.disabledControlTextColor
            ctx.setStrokeColor(strokeColor.cgColor)
            ctx.setLineWidth(self.endControlPointKnobLineWidth)
            ctx.strokeEllipse(in: endControlPointKnobBounds)
        }

        if startControlPointKnobIsOnTop {
            drawSecondHandle()
            drawStartHandle()
        } else {
            drawStartHandle()
            drawSecondHandle()
        }
        
        ctx.restoreGState()
    }
}
