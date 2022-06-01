// The MIT License (MIT)
//
// Copyright (c) 2016 Thomas Zhao
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if os(OSX)
    import AppKit
    
    public typealias TRZImage = NSImage
    public typealias TRZFont = NSFont
    public typealias TRZColor = NSColor
    public typealias TRZView = NSView
#elseif os(iOS) || os(tvOS)
    import UIKit
    
    public typealias TRZImage = UIImage
    public typealias TRZFont = UIFont
    public typealias TRZColor = UIColor
    public typealias TRZView = UIView
#endif

private func performWithoutImplicitAnimation(_ block: ()->Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    block()
    CATransaction.commit()
}

public class NumberScrollView: TRZView {
    
    public typealias AnimationDirection = NumberScrollLayer.AnimationDirection
    
    public enum ImageCachePolicy {
        case never
        case global
        case custom(NumberScrollLayerImageCache)
    }
    
    public var text:String {
        get { return numberScrollLayer.text }
        set {
            let oldSize = numberScrollLayer.boundingSize
            numberScrollLayer.text = newValue
            if (numberScrollLayer.boundingSize != oldSize) {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    public func setText(_ text: String, animated: Bool, completion: (() -> Void)? = nil) {
        let oldText = self.text
        self.text = text
        if animated {
            self.numberScrollLayer.playScrollAnimation(oldText: oldText, completion)
        } else {
            completion?()
        }
    }
    
    public func setFont(_ font: TRZFont, textColor:TRZColor) {
        let oldSize = numberScrollLayer.boundingSize
        performWithoutImplicitAnimation() {
            numberScrollLayer.setFont(font, textColor: textColor)
        }
        if (numberScrollLayer.boundingSize != oldSize) {
            invalidateIntrinsicContentSize()
        }
    }
    
    public var textColor: TRZColor {
        get { return numberScrollLayer.textColor }
        set { performWithoutImplicitAnimation() {
            numberScrollLayer.textColor = newValue
            }
        }
    }
    
    public var font: TRZFont {
        get { return numberScrollLayer.font }
        set {
            let oldSize = numberScrollLayer.boundingSize
            numberScrollLayer.font = newValue
            if (numberScrollLayer.boundingSize != oldSize) {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    public var animationDuration:TimeInterval {
        get { return numberScrollLayer.animationDuration }
        set { numberScrollLayer.animationDuration = newValue }
    }
    
    public var animationCurve:CAMediaTimingFunction {
        get { return numberScrollLayer.animationCurve }
        set { numberScrollLayer.animationCurve = newValue }
    }
    
    public var animationDirection:AnimationDirection {
        get { return numberScrollLayer.animationDirection }
        set { numberScrollLayer.animationDirection = newValue }
    }
    
    public var imageCachePolicy:ImageCachePolicy = {
        #if os(OSX)
            return .never
        #elseif os(iOS) || os(tvOS)
            return .global
        #endif
        }() {
        didSet {
            configureImageCache()
        }
    }
    
    //Requires the TRZNUMBERSCROLL_ENABLE_PRIVATE_API preprocessor symbol to be defined
    #if os(OSX) && TRZNUMBERSCROLL_ENABLE_PRIVATE_API
    public var fontSmoothingBackgroundColor:TRZColor? {
        get { return numberScrollLayer.fontSmoothingBackgroundColor }
        set {
            numberScrollLayer.fontSmoothingBackgroundColor = newValue
        }
    }
    #endif
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        #if os(OSX)
            let layer = NumberScrollLayer()
            layer.delegate = self
            self.layer = layer
            self.wantsLayer = true
        #endif
        configureImageCache()
        numberScrollLayer.masksToBounds = true
    }
    
    private var numberScrollLayer:NumberScrollLayer {
        return self.layer as! NumberScrollLayer
    }
    
    private func configureImageCache() {
        switch imageCachePolicy {
        case .never: numberScrollLayer.imageCache = nil
        case .global: numberScrollLayer.imageCache = NumberScrollLayer.globalImageCache
        case let .custom(imageCache): numberScrollLayer.imageCache = imageCache
        }
    }
    
    override public var intrinsicContentSize:CGSize {
        return numberScrollLayer.boundingSize
    }
    
    #if os(OSX)
    override public var isFlipped:Bool {
        return true
    }
    #elseif os(iOS) || os(tvOS)
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return intrinsicContentSize
    }
    #endif
    
    #if os(OSX)
    public var backgroundColor:TRZColor? {
        get {
            if let bkgColor = numberScrollLayer.backgroundColor {
                return TRZColor(cgColor: bkgColor)
            } else {
                return nil
            }
        }
        set { numberScrollLayer.backgroundColor = newValue?.cgColor }
    }
    #endif
    
    #if os(iOS) || os(tvOS)
    override public class var layerClass: AnyClass {
        return NumberScrollLayer.self
    }
    #endif
}

public protocol AcquireRelinquishProtocol {
    associatedtype T
    func acquire() -> T
    func relinquish()
    var acquireCount:Int { get }
}

public class AcquireRelinquishBox<V>: AcquireRelinquishProtocol {
    public typealias T = V
    private lazy var queue:DispatchQueue = {
        let queueQos = DispatchQoS(qosClass: .utility, relativePriority: 0)
        return DispatchQueue(label: String(describing: AcquireRelinquishBox.self) + ".queue", qos: queueQos)
    }()
    
    public init(value:V) {
        self.value = value
    }
    public func acquire() -> V {
        queue.sync {
            _acquireCount += 1
        }
        return value
    }
    public func relinquish() {
        queue.sync {
            _acquireCount -= 1
        }
    }
    
    private var _acquireCount:Int32 = 1
    
    public var acquireCount:Int {
        return Int(_acquireCount)
    }
    private let value:V
}

public protocol NumberScrollLayerImageCache {
    func imageBox(forKey key: String, font:TRZFont, color:TRZColor, backgroundColor:TRZColor?, fontSmoothingBackgroundColor:TRZColor?) -> AcquireRelinquishBox<TRZImage>?
    func setImage(_ image:TRZImage, forKey key:String, font:TRZFont, color:TRZColor, backgroundColor:TRZColor?, fontSmoothingBackgroundColor:TRZColor?) -> AcquireRelinquishBox<TRZImage>
    func evict()
}

public class NumberScrollLayer: CALayer {
    public init(imageCache:NumberScrollLayerImageCache?) {
        super.init()
        self.imageCache = imageCache
    }
    
    public override init() {
        super.init()
        self.imageCache = NumberScrollLayer.globalImageCache
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? NumberScrollLayer {
            self.imageCache = layer.imageCache
            self.setFont(layer.font, textColor: layer.textColor)
            self.animationCurve = layer.animationCurve
            self.animationDuration = layer.animationDuration
            self.text = layer.text
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.imageCache = NumberScrollLayer.globalImageCache
        let selfName = String(describing: NumberScrollLayer.self)
        let font = aDecoder.decodeObject(forKey: selfName + ".font") as! TRZFont
        let textColor = aDecoder.decodeObject(forKey: selfName + ".textColor") as! TRZColor
        self.setFont(font, textColor: textColor)
        
        self.text = aDecoder.decodeObject(forKey: selfName + ".text") as! String
        self.animationCurve = aDecoder.decodeObject(forKey: selfName + ".animationCurve")! as! CAMediaTimingFunction
        self.animationDuration = aDecoder.decodeDouble(forKey: selfName + ".animationDuration")
    }
    
    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        let selfName = String(describing: NumberScrollLayer.self)
        aCoder.encode(self.font, forKey: selfName + ".font")
        aCoder.encode(self.textColor, forKey: selfName + ".textColor")
        aCoder.encode(self.text, forKey: selfName + ".text")
        aCoder.encode(self.animationCurve, forKey: selfName + ".animationCurve")
        aCoder.encode(self.animationDuration, forKey: selfName + ".animationDuration")
    }
    
    public class DefaultImageCache: NSObject, NumberScrollLayerImageCache {
        private lazy var queue:DispatchQueue = {
            let queueQos = DispatchQoS(qosClass: .utility, relativePriority: 0)
            return DispatchQueue(label: String(describing: DefaultImageCache.self) + ".queue", qos: queueQos)
        }()
        
        public override init() {
            super.init()
            
            #if !os(OSX)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(DefaultImageCache.evict),
                                                   name: UIApplication.didReceiveMemoryWarningNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(DefaultImageCache.evict),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
            if #available(iOSApplicationExtension 8.2, *) {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(DefaultImageCache.evict),
                                                       name: .NSExtensionHostDidEnterBackground, object: nil)
            }
            #endif
        }

        private lazy var cachedImages = [CacheKey: AcquireRelinquishBox<TRZImage>]()
        
        private struct CacheKey: Equatable, Hashable {
            var key: String
            var font: TRZFont
            var color: TRZColor
            var backgroundColor: TRZColor?
            var fontSmoothingBackgroundColor: TRZColor?

            var hashValue:Int {
                return key.hashValue ^ font.hashValue ^ color.hashValue ^ (fontSmoothingBackgroundColor?.hashValue ?? 0) ^ (backgroundColor?.hashValue ?? 0)
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(key)
                hasher.combine(font)
                hasher.combine(color)
                hasher.combine(fontSmoothingBackgroundColor)
                hasher.combine(backgroundColor)
            }
            
            static func ==(lhs:CacheKey, rhs:CacheKey) -> Bool {
                return lhs.key == rhs.key && lhs.font == rhs.font && lhs.color == rhs.color && lhs.fontSmoothingBackgroundColor == rhs.fontSmoothingBackgroundColor && lhs.backgroundColor == rhs.backgroundColor
            }
        }
        
        @objc public func evict() {
            queue.async {
                for (key, value) in self.cachedImages {
                    if value.acquireCount <= 0 {
                        self.cachedImages.removeValue(forKey: key)
                    }
                }
            }
        }
        
        public func imageBox(forKey key: String, font:TRZFont, color:TRZColor, backgroundColor:TRZColor?, fontSmoothingBackgroundColor:TRZColor?) -> AcquireRelinquishBox<TRZImage>? {
            var box:AcquireRelinquishBox<TRZImage>?
            let cacheKey = CacheKey(key: key, font: font, color: color, backgroundColor: backgroundColor, fontSmoothingBackgroundColor: fontSmoothingBackgroundColor)
            queue.sync {
                box = self.cachedImages[cacheKey]
            }
            return box
        }
        
        
        public func setImage(_ image:TRZImage, forKey key:String, font:TRZFont, color:TRZColor, backgroundColor:TRZColor?, fontSmoothingBackgroundColor:TRZColor?) -> AcquireRelinquishBox<TRZImage> {
            let cacheKey = CacheKey(key: key, font: font, color: color, backgroundColor: backgroundColor, fontSmoothingBackgroundColor:fontSmoothingBackgroundColor)
            let newVal = AcquireRelinquishBox<TRZImage>(value: image)
            queue.sync {
                self.cachedImages[cacheKey] = newVal
            }
            return newVal
        }
        
    }
    
    static fileprivate let globalImageCache = DefaultImageCache()
    
    public var imageCache:NumberScrollLayerImageCache? {
        willSet {
            self.releaseCachedImages()
        }
    }
    
    public func setFont(_ font:TRZFont, textColor: TRZColor) {
        _textColor = textColor
        self.font = font
    }
    
    public var text: String = "0" {
        didSet {
            if text != oldValue {
                performWithoutImplicitAnimation() {
                    relayoutScrollLayers()
                    setScrollLayerContents()
                }
            }
        }
    }
    
    private func releaseCachedCharacterImages() {
        for box in _cachedCharacterImageBoxes {
            box.relinquish()
        }
        _cachedCharacterImageBoxes.removeAll()
    }
    
    private func releaseCachedDigitsImage() {
        _cachedDigitsImageBox?.relinquish()
        _cachedDigitsImageBox = nil
        _digitsImage = nil
    }
    
    private var _cachedDigitsImageBox:AcquireRelinquishBox<TRZImage>?
    private lazy var _cachedCharacterImageBoxes = [AcquireRelinquishBox<TRZImage>]()
    
    private var _textColor:TRZColor = TRZColor.black
    public var textColor:TRZColor {
        get { return _textColor }
        set {
            if _textColor != newValue {
                releaseCachedImages()
                _textColor = newValue
                if (!text.isEmpty) {
                    recolorScrollLayers()
                }
            }
        }
    }
    
    func releaseCachedImages() {
        releaseCachedCharacterImages()
        releaseCachedDigitsImage()
    }
    
    private var _font:TRZFont = TRZFont.systemFont(ofSize: 12).monospacedDigitsFont
    public var font:TRZFont {
        get { return _font }
        set {
            let newFont = newValue.monospacedDigitsFont
            if _font != newFont {
                releaseCachedImages()
                _font = newFont
                if (!text.isEmpty) {
                    performWithoutImplicitAnimation() {
                        contentLayers.forEach({ $0.removeFromSuperlayer() })
                        contentLayers.removeAll()
                        relayoutScrollLayers()
                        setScrollLayerContents()
                    }
                }
            }
        }
    }
    
    public var animationDuration:TimeInterval = 1.0
    lazy public var animationCurve:CAMediaTimingFunction = CAMediaTimingFunction(controlPoints: 0, 0, 0.1, 1)
    public var animationDirection:AnimationDirection = .up
    
    private var _digitsImage:TRZImage?
    public var digitsImage:TRZImage! {
        if (_digitsImage == nil) {
            _digitsImage = createDigitsImage(withFont: self.font)
        }
        return _digitsImage
    }
    
    private var digitsImageIndividualDigitSize:CGSize {
        return CGSize(width: digitsImage.size.width, height: digitsImage.size.height / CGFloat(10) / CGFloat(repetitions))
    }
    
    private func attributes(forFont font:TRZFont) -> [NSAttributedString.Key: AnyObject] {
        #if os(OSX)
            let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        #elseif os(iOS) || os(tvOS)
            let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        #endif
        style.alignment = .center
        style.lineBreakMode = .byClipping
        style.lineSpacing = 0
        return [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.foregroundColor: textColor
        ]
    }
    
    private let repetitions = 2
    
    #if os(OSX) && TRZNUMBERSCROLL_ENABLE_PRIVATE_API
    private typealias CGContextSetFontSmoothingBackgroundColorFunc = @convention(c) (CGContext?, CGColor) -> Void
    private static let CGContextSetFontSmoothingBackgroundColor:CGContextSetFontSmoothingBackgroundColorFunc? = {
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        let sym = dlsym(RTLD_DEFAULT, "CGContextSetFontSmoothingBackgroundColor")
        if sym != nil {
            return unsafeBitCast(sym, to: CGContextSetFontSmoothingBackgroundColorFunc.self)
        }
        return nil
    }()
    #endif
    
    private func configureFontAntialiasing(backgroundColorIsOpaque:Bool) {
        let ctx = self.currentGraphicsContext()
        #if os(OSX)
            if backgroundColorIsOpaque {
                ctx?.setShouldSmoothFonts(true)
                return
            }
            
            #if TRZNUMBERSCROLL_ENABLE_PRIVATE_API
                if let fontSmoothingBackgroundColor = self.fontSmoothingBackgroundColor {
                    NumberScrollLayer.CGContextSetFontSmoothingBackgroundColor?(ctx, fontSmoothingBackgroundColor.cgColor)
                    ctx?.setShouldSmoothFonts(true)
                } else {
                    ctx?.setShouldSmoothFonts(false)
                }
            #endif
        #elseif os(iOS) || os(tvOS)
            ctx?.setShouldSmoothFonts(false)
        #endif
    }
    
    private func createImage(forNonDigit character:Character, font:TRZFont) -> TRZImage {
        let cacheKey = String(describing: type(of: self)) + ".characters." + String(character)
        
        let backgroundColor:TRZColor? = {
            if let bkg = self.backgroundColor {
                if bkg.alpha == 1 {
                    return TRZColor(cgColor: bkg)
                }
            }
            return nil
        }()
        
        let fontSmoothingBackgroundColor:TRZColor?
        #if os(OSX) && TRZNUMBERSCROLL_ENABLE_PRIVATE_API
            fontSmoothingBackgroundColor = self.fontSmoothingBackgroundColor
        #else
            fontSmoothingBackgroundColor = nil
        #endif
        
        if let box = imageCache?.imageBox(forKey: cacheKey, font: font, color: self.textColor, backgroundColor: backgroundColor, fontSmoothingBackgroundColor: fontSmoothingBackgroundColor) {
            _cachedCharacterImageBoxes.append(box)
            return box.acquire()
        }
        
        let str = String(character) as NSString
        let fontAttributes = attributes(forFont: font)
        #if os(OSX)
        let size = str.size(withAttributes: fontAttributes)
        #elseif os(iOS) || os(tvOS)
        let size = str.size(withAttributes: fontAttributes)
        #endif
        
        var imageSize = digitsImageIndividualDigitSize
        imageSize.width = ceil(size.width)
        
        let drawingHandler = { (rect:CGRect) -> Bool in
            self.configureFontAntialiasing(backgroundColorIsOpaque: backgroundColor != nil)
            if let backgroundColor = backgroundColor {
                let ctx = self.currentGraphicsContext()
                ctx?.setFillColor(backgroundColor.cgColor)
                ctx?.fill(rect)
            }
            str.draw(in: CGRect(x: rect.origin.x, y: rect.origin.y + (imageSize.height - size.height) / 2, width: imageSize.width, height: size.height), withAttributes: fontAttributes)
            return true
        }
        
        #if os(OSX)
            let image = TRZImage(size: imageSize, flipped: true, drawingHandler: drawingHandler)
        #elseif os(iOS) || os(tvOS)
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            _ = drawingHandler(CGRect(origin: .zero, size: imageSize))
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        #endif
        
        
        if let box = imageCache?.setImage(image, forKey: cacheKey, font: font, color: self.textColor, backgroundColor: backgroundColor, fontSmoothingBackgroundColor: fontSmoothingBackgroundColor) {
            _cachedCharacterImageBoxes.append(box)
        }
        
        return image
    }
    
    private func currentGraphicsContext() -> CGContext? {
        #if os(OSX)
            return NSGraphicsContext.current?.cgContext
        #elseif os(iOS) || os(tvOS)
            return UIGraphicsGetCurrentContext()
        #endif
    }
    
    private func createDigitsImage(withFont font:TRZFont) -> TRZImage {
        let cacheKey = String(describing: type(of: self)) + ".digits"
        
        let backgroundColor:TRZColor? = {
            if let bkg = self.backgroundColor {
                if bkg.alpha == 1 {
                    return TRZColor(cgColor: bkg)
                }
            }
            return nil
        }()
        
        let fontSmoothingBackgroundColor:TRZColor?
        #if os(OSX) && TRZNUMBERSCROLL_ENABLE_PRIVATE_API
            fontSmoothingBackgroundColor = self.fontSmoothingBackgroundColor
        #else
            fontSmoothingBackgroundColor = nil
        #endif
        
        if let box = imageCache?.imageBox(forKey: cacheKey, font: font, color: self.textColor, backgroundColor: backgroundColor ,fontSmoothingBackgroundColor: fontSmoothingBackgroundColor) {
            _cachedDigitsImageBox = box
            return box.acquire()
        }
        
        let fontAttributes = attributes(forFont: font)
        let repetitions = self.repetitions
        var maxSize = CGSize.zero
        
        let digits = (0...9).map({String($0)})
        
        for digit in digits {
            #if os(OSX)
            maxSize = maxSize.union((digit as NSString).size(withAttributes: fontAttributes))
            #elseif os(iOS) || os(tvOS)
            maxSize = maxSize.union((digit as NSString).size(withAttributes: fontAttributes))
            #endif
        }
        
        maxSize = CGSize(width: ceil(maxSize.width), height: ceil(maxSize.height))
        
        let imageSize = CGSize(width: maxSize.width, height: maxSize.height * CGFloat(digits.count) * CGFloat(repetitions))
        
        let drawingHandler = { (rect:CGRect) -> Bool in
            self.configureFontAntialiasing(backgroundColorIsOpaque: backgroundColor != nil)
            if let backgroundColor = backgroundColor {
                let ctx = self.currentGraphicsContext()
                ctx?.setFillColor(backgroundColor.cgColor)
                ctx?.fill(rect)
            }
            let individualHeight = maxSize.height
            var currentRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: imageSize.width, height: individualHeight))
            for _ in 0..<repetitions {
                for digit in digits {
                    (digit as NSString).draw(in: currentRect, withAttributes: fontAttributes)
                    currentRect.origin.y += individualHeight
                }
            }
            return true
        }
        
        #if os(OSX)
            let image = TRZImage(size: imageSize, flipped: true, drawingHandler: drawingHandler)
        #elseif os(iOS) || os(tvOS)
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
            _ = drawingHandler(CGRect(origin: .zero, size: imageSize))
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        #endif
        
        if let box = imageCache?.setImage(image, forKey: cacheKey, font: font, color: self.textColor, backgroundColor: backgroundColor, fontSmoothingBackgroundColor: fontSmoothingBackgroundColor) {
            _cachedDigitsImageBox = box
        }
        
        return image
    }
    
    private var contentLayers = [CALayer]()
    
    public private(set) var boundingSize = CGSize.zero
    
    private func recolorScrollLayers() {
        if contentLayers.count != text.count {
            relayoutScrollLayers()
            setScrollLayerContents()
            return
        }
        
        var contentLayersIndex = contentLayers.startIndex
        var charactersIndex = text.startIndex
        
        while charactersIndex < text.endIndex {
            let char = text[charactersIndex]
            if let _ = Int(String(char)) {
                let scrollLayer = contentLayers[contentLayersIndex]
                let contentsLayer = scrollLayer.sublayers![0]
                
                #if os(OSX)
                    contentsLayer.contents = digitsImage
                #elseif os(iOS) || os(tvOS)
                    contentsLayer.contents = digitsImage.cgImage
                #endif
            } else {
                let contentsLayer = contentLayers[contentLayersIndex]
                
                let needsVerticallyCenteredColon = needsVerticallyCenteredColonForCharacterAtIndex(charactersIndex, characters: text)
                let font = needsVerticallyCenteredColon ? self.font.verticallyCenteredColonFont : self.font
                
                let image = createImage(forNonDigit: char, font: font)
                
                #if os(OSX)
                    contentsLayer.contents = image
                #elseif os(iOS) || os(tvOS)
                    contentsLayer.contents = image.cgImage
                #endif
            }
            
            contentLayersIndex = (contentLayersIndex + 1)
            charactersIndex = text.index(after: charactersIndex)
        }
    }
    
    private func needsVerticallyCenteredColonForCharacterAtIndex(_ index: String.Index, characters: String) -> Bool {
        guard characters[index] == ":" else { return false }
        
        if index != characters.startIndex {
            let nextIndex = characters.index(after: index)
            let prevIndex = characters.index(before: index)
            if nextIndex != characters.endIndex {
                let prevChar = String(characters[prevIndex])
                let nextChar = String(characters[nextIndex])
                
                let prevCharIsDigit = Int(prevChar) != nil
                let nextCharIsDigit = Int(nextChar) != nil
                
                let isUpperCase = { (str:String) in str.uppercased() == str && str.lowercased() != str }
                
                if (prevCharIsDigit && nextCharIsDigit) ||
                    (prevCharIsDigit && isUpperCase(nextChar)) ||
                    (nextCharIsDigit && isUpperCase(prevChar)) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func relayoutScrollLayers() {
        let individualSize = digitsImageIndividualDigitSize
        
        var currentOrigin = CGPoint.zero
        var boundingSize = CGSize.zero
        
        
        let contentLayers = self.contentLayers
        var newLayers = [CALayer]()
        
        var contentLayersIndex = contentLayers.startIndex
        var charactersIndex = text.startIndex
        
        while charactersIndex < text.endIndex {
            let char = text[charactersIndex]
            let currentLayer:CALayer? = (contentLayersIndex < contentLayers.endIndex) ? contentLayers[contentLayersIndex] : nil
            if let _ = Int(String(char)) {
                let scrollLayer:CALayer
                if currentLayer?.value(forKey: "myContents") as? String == "digits" {
                    scrollLayer = currentLayer!
                    scrollLayer.removeAllAnimations()
                    scrollLayer.frame.origin = currentOrigin
                } else {
                    currentLayer?.removeFromSuperlayer()
                    
                    let contentsLayer = CALayer()
                    
                    #if os(OSX)
                        contentsLayer.contents = digitsImage
                    #elseif os(iOS) || os(tvOS)
                        contentsLayer.contents = digitsImage.cgImage
                    #endif
                    
                    contentsLayer.frame = CGRect(origin: CGPoint.zero, size: digitsImage.size)
                    contentsLayer.masksToBounds = true
                    
                    scrollLayer = CALayer()
                    scrollLayer.masksToBounds = true
                    scrollLayer.frame = CGRect(origin: currentOrigin, size: individualSize)
                    scrollLayer.addSublayer(contentsLayer)
                    scrollLayer.setValue("digits", forKey: "myContents")
                    
                    self.addSublayer(scrollLayer)
                }
                
                newLayers.append(scrollLayer)
                
                currentOrigin.x += scrollLayer.bounds.width
                boundingSize.width += scrollLayer.bounds.width
                boundingSize.height = max(boundingSize.height, scrollLayer.bounds.height)
            } else {
                let charLayer:CALayer
                
                let needsVerticallyCenteredColon = needsVerticallyCenteredColonForCharacterAtIndex(charactersIndex, characters: text)
                let currentLayerMatches =
                    currentLayer?.value(forKey: "myContents") as? String == String(char) &&
                        currentLayer?.value(forKey: "verticallyCenteredColon") as? Bool == needsVerticallyCenteredColon
                
                if currentLayerMatches {
                    charLayer = currentLayer!
                    charLayer.removeAllAnimations()
                    charLayer.frame.origin = currentOrigin
                } else {
                    currentLayer?.removeFromSuperlayer()
                    
                    charLayer = CALayer()
                    
                    let font = needsVerticallyCenteredColon ? self.font.verticallyCenteredColonFont : self.font
                    let image = createImage(forNonDigit: char, font: font)
                    let imageSize = image.size
                    charLayer.setValue(String(char), forKey: "myContents")
                    charLayer.setValue(needsVerticallyCenteredColon, forKey: "verticallyCenteredColon")
                    
                    #if os(OSX)
                        charLayer.contents = image
                    #elseif os(iOS) || os(tvOS)
                        charLayer.contents = image.cgImage
                    #endif
                    
                    charLayer.frame = CGRect(origin: currentOrigin, size: imageSize)
                    
                    self.addSublayer(charLayer)
                }
                newLayers.append(charLayer)
                
                currentOrigin.x += charLayer.bounds.width
                boundingSize.width += charLayer.bounds.width
                boundingSize.height = max(boundingSize.height, charLayer.bounds.height)
            }
            
            contentLayersIndex = (contentLayersIndex + 1)
            charactersIndex = text.index(after: charactersIndex)
        }
        
        while contentLayersIndex < contentLayers.endIndex {
            contentLayers[contentLayersIndex].removeFromSuperlayer()
            contentLayersIndex = (contentLayersIndex + 1)
        }
        
        self.contentLayers = newLayers
        self.boundingSize = boundingSize
    }
    
    private func setScrollLayerContents() {
        for (i, char) in text.enumerated() {
            if let digit = Int(String(char)) {
                contentLayers[i].bounds.origin = upperRect(forDigit: digit).origin
            }
        }
    }
    
    private func lowerRect(forDigit digit:Int) -> CGRect {
        let imageSize = digitsImage.size
        
        var rect = upperRect(forDigit: digit)
        rect.origin.y += imageSize.height / 2
        return rect
    }
    
    private func upperRect(forDigit digit:Int) -> CGRect {
        let imageSize = digitsImage.size
        
        let individualHeight = digitsImageIndividualDigitSize.height
        let point = CGPoint(x: 0, y: CGFloat(digit) * individualHeight)
        return CGRect(origin: point, size: CGSize(width: imageSize.width, height: individualHeight))
    }
    
    @objc public enum AnimationDirection: Int {
        case up
        case down
    }
    
    public func playScrollAnimation(oldText: String, _ completion:(()->Void)? = nil) {
        if animationDuration == 0 { return }
        
        let durationOffset = animationDuration/Double(contentLayers.count + 1)
        var offset = durationOffset * 2

        var animationDirection = self.animationDirection
        if let oldInt = Int(oldText), let newInt = Int(text) {
            animationDirection = newInt > oldInt ? .up : .down
        }

        performWithoutImplicitAnimation() {
            CATransaction.setCompletionBlock(completion)
            for (i, char) in text.enumerated() {
                if let digit = Int(String(char)) {
                    if let index = oldText.index(oldText.startIndex, offsetBy: i, limitedBy: oldText.endIndex),
                       oldText[safe: index] == char {
                        continue
                    }

                    let scrollLayer = contentLayers[i]
                    let animation = CABasicAnimation(keyPath: "bounds.origin.y")
                    let upOrigin = upperRect(forDigit: digit).origin.y
                    let downOrigin = lowerRect(forDigit: digit).origin.y
                    scrollLayer.bounds.origin.y =  (animationDirection == .up) ? downOrigin : upOrigin
                    animation.fromValue = (animationDirection == .up) ? upOrigin : downOrigin
                    animation.timingFunction = self.animationCurve
                    animation.duration = offset
                    scrollLayer.add(animation, forKey: "scroll")
                }
                offset += durationOffset
            }
        }
    }
    
    public static func evictGlobalImageCache() {
        globalImageCache.evict()
    }
    
    #if os(OSX) && TRZNUMBERSCROLL_ENABLE_PRIVATE_API
    public var fontSmoothingBackgroundColor:TRZColor? {
        didSet {
            if fontSmoothingBackgroundColor != oldValue {
                releaseCachedImages()
                recolorScrollLayers()
            }
        }
    }
    #endif
    
    override public var backgroundColor:CGColor? {
        didSet {
            if backgroundColor != oldValue {
                releaseCachedImages()
                recolorScrollLayers()
            }
        }
    }
}

#if os(OSX)
    extension NumberScrollView: CALayerDelegate {}
#endif

private extension CGSize {
    func union(_ size:CGSize) -> CGSize {
        return CGSize(width: max(self.width, size.width), height: max(self.height, size.height))
    }
}

private extension TRZFont {
    var monospacedDigitsFont:TRZFont {
        let descriptor = self.fontDescriptor
        #if os(OSX)
        let TRZFontFeatureSettingsAttribute = NSFontDescriptor.AttributeName.featureSettings
        let TRZFontFeatureTypeIdentifierKey = NSFontDescriptor.FeatureKey.typeIdentifier
        let TRZFontFeatureSelectorIdentifierKey = NSFontDescriptor.FeatureKey.selectorIdentifier
        #elseif os(iOS) || os(tvOS)
        let TRZFontFeatureSettingsAttribute = UIFontDescriptor.AttributeName.featureSettings
        let TRZFontFeatureTypeIdentifierKey = UIFontDescriptor.FeatureKey.featureIdentifier
        let TRZFontFeatureSelectorIdentifierKey = UIFontDescriptor.FeatureKey.typeIdentifier
        #endif
        
        let attributes = [
            TRZFontFeatureSettingsAttribute: [
                [
                    TRZFontFeatureTypeIdentifierKey: kNumberSpacingType,
                    TRZFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
                ]
            ]
        ]
        let newDescriptor = descriptor.addingAttributes(attributes)
        #if os(OSX)
            return TRZFont(descriptor: newDescriptor, size: 0)!
        #elseif os(iOS) || os(tvOS)
            return TRZFont(descriptor: newDescriptor, size: 0)
        #endif
    }
    
    var verticallyCenteredColonFont:TRZFont {
        guard #available(iOS 9.0, OSX 10.11, *) else { return self }
        
        let descriptor = self.fontDescriptor
        #if os(OSX)
        guard self.familyName?.hasPrefix(".") == true else { return self }
        let TRZFontFeatureSettingsAttribute = NSFontDescriptor.AttributeName.featureSettings
        let TRZFontFeatureTypeIdentifierKey = NSFontDescriptor.FeatureKey.typeIdentifier
        let TRZFontFeatureSelectorIdentifierKey = NSFontDescriptor.FeatureKey.selectorIdentifier
        #elseif os(iOS) || os(tvOS)
        guard self.familyName.hasPrefix(".") == true else { return self }
        let TRZFontFeatureSettingsAttribute = UIFontDescriptor.AttributeName.featureSettings
        let TRZFontFeatureTypeIdentifierKey = UIFontDescriptor.FeatureKey.featureIdentifier
        let TRZFontFeatureSelectorIdentifierKey = UIFontDescriptor.FeatureKey.typeIdentifier
        #endif
        
        let attributes = [
            TRZFontFeatureSettingsAttribute: [
                [
                    TRZFontFeatureTypeIdentifierKey: kStylisticAlternativesType,
                    TRZFontFeatureSelectorIdentifierKey: kStylisticAltThreeOnSelector
                ]
            ]
        ]
        
        let newDescriptor = descriptor.addingAttributes(attributes)
        #if os(OSX)
            return TRZFont(descriptor: newDescriptor, size: 0)!
        #elseif os(iOS) || os(tvOS)
            return TRZFont(descriptor: newDescriptor, size: 0)
        #endif
    }
}
