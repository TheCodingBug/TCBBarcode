//
//  TCBBarcodeObject.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 5/21/21.
//

import Foundation
import CoreImage

public class TCBBarcodeObject: NSObject {
    
    public enum TCBBarcodeObjectFillMode {
        case originalSize // image size is retained
        case aspectFit // contents scaled to fit with fixed aspect. remainder is transparent
        case aspectFill // contents scaled to fill with fixed aspect. some portion of content may be clipped.
    }
    
    private var ciCode: CIImage!
    private var transform: CGAffineTransform = .identity
    
    private override init() {
        super.init()
    }
    
    public var code: UIImage {
        let output = ciCode.transformed(by: transform, highQualityDownsample: true)
        return UIImage(ciImage: output)
    }
    
    convenience public init(barcode code: CIImage, transform t: CGAffineTransform) {
        self.init()
        ciCode = code
        transform = t
    }
}

// MARK: - Helpers
extension TCBBarcodeObject {
    fileprivate func getScale(forCanvas canvas: CGFloat, itemSize: CGFloat) -> CGFloat {
        
        return canvas / itemSize
    }
    
    fileprivate func getFitRatio(forCanvas canvas: CGSize, itemSize: CGSize) -> CGFloat {
        let ratio = getScale(forCanvas: canvas.width, itemSize: itemSize.width)
        
        // validate ratio to canvas size
        if ratio * itemSize.height > canvas.height { // invalid
            // flip values
            let flippedCanvas = CGSize(width: canvas.height, height: canvas.width)
            let flippedItemSize = CGSize(width: itemSize.height, height: itemSize.width)
            return getFitRatio(forCanvas: flippedCanvas, itemSize: flippedItemSize)
        }
        
        return ratio
    }
    
    fileprivate func getFillRatio(forCanvas canvas: CGSize, itemSize: CGSize) -> CGFloat {
        let ratio = getScale(forCanvas: canvas.width, itemSize: itemSize.width)
        
        // validate ratio to canvas size
        if ratio * itemSize.height < canvas.height { // invalid
            // flip values
            let flippedCanvas = CGSize(width: canvas.height, height: canvas.width)
            let flippedItemSize = CGSize(width: itemSize.height, height: itemSize.width)
            return getFillRatio(forCanvas: flippedCanvas, itemSize: flippedItemSize)
        }
        
        return ratio
    }
    
    fileprivate func getScale(for mode: TCBBarcodeObjectFillMode, withCanvas canvas: CGSize, itemSize: CGSize) -> CGFloat {
        switch mode {
        case .aspectFit:
            return getFitRatio(forCanvas: canvas, itemSize: itemSize)
        case .aspectFill:
            return getFillRatio(forCanvas: canvas, itemSize: itemSize)
        default:
            return 1.0
        }
    }
    
    fileprivate func applyCrop(for mode: TCBBarcodeObjectFillMode, imageCode: CIImage, itemSize: CGSize) -> CIImage {
        switch mode {
        case .aspectFill:
            let cropRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            let output = imageCode.cropped(to: cropRect)
            return output
        default:
            return imageCode
        }
    }
    
    fileprivate func setCodeTransparent(_ ciCode: CIImage) -> CIImage? {
        let params = [kCIInputImageKey: ciCode as Any]
        guard let filter = CIFilter(name: "CIMaskToAlpha", parameters: params),
              let output = filter.outputImage
        else { return nil }
        
        return output
    }
    
    fileprivate func setCodeColorInverted(_ ciCode: CIImage) -> CIImage? {
        let params = [kCIInputImageKey: ciCode as Any]
        guard let filter = CIFilter(name: "CIColorInvert", parameters: params),
              let output = filter.outputImage
        else { return nil }
        
        return output
    }
}

extension TCBBarcodeObject {
    
    public func applyTransparent() {
        if let output = setCodeTransparent(ciCode) {
            ciCode = output // update original
        }
    }
    
    public func applyInvert() {
        if let output = setCodeColorInverted(ciCode) {
            ciCode = output // update original
        }
    }
    
    public func applyTint(color: UIColor) {
        // apply color
        let ciColor = CIColor(color: color)
        let colorParams = [kCIInputColorKey: ciColor as Any]
        guard let colorFilter = CIFilter(name: "CIConstantColorGenerator", parameters: colorParams),
              let output = colorFilter.outputImage
        else { return }
        
        // if conversion fails, original code will not be affected
        guard let inverted = setCodeColorInverted(ciCode) else { return } // flip color
        guard let transparent = setCodeTransparent(inverted) else { return } // make solid color transparent
        
        // apply composite
        let compositeParams = [
            kCIInputImageKey: transparent as Any,
            kCIInputBackgroundImageKey: output as Any
        ]
        guard let compositeFilter = CIFilter(name: "CIMultiplyCompositing", parameters: compositeParams),
              let output2 = compositeFilter.outputImage
        else { return }
        
        ciCode = output2 // update original
    }
    
    public func applyBlend(withImage img: CGImage, fillMode mode: TCBBarcodeObjectFillMode = .aspectFill) {
        let image = CIImage(cgImage: img)
        let scale = getScale(for: mode, withCanvas: ciCode.extent.size, itemSize: image.extent.size)
        let reScaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let reScaledImage = image.transformed(by: reScaleTransform)
        
        let params = [
            kCIInputMaskImageKey: ciCode as Any,
            kCIInputBackgroundImageKey: reScaledImage as Any
        ]
        guard let filter = CIFilter(name: "CIBlendWithMask", parameters: params),
              let output = filter.outputImage
        else { return }
        
        let cropped = applyCrop(for: mode, imageCode: output, itemSize: ciCode.extent.size)
        ciCode = cropped // update original
    }
    
    public func applyLogo(withImage img: CGImage, fillMode mode: TCBBarcodeObjectFillMode = .aspectFill) {
        let image = CIImage(cgImage: img)
        let scale = getScale(for: mode, withCanvas: ciCode.extent.size, itemSize: image.extent.size) * 0.18 // set to 20% of the canvas
        let reScaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let reScaledLogo = image.transformed(by: reScaleTransform)
        let logoMidX = reScaledLogo.extent.width / 2
        let logoMidY = reScaledLogo.extent.height / 2
        
        let midX = ciCode.extent.midX - logoMidX
        let midY = ciCode.extent.midY - logoMidY
        let imageTransform = CGAffineTransform(translationX: midX, y: midY)
        let logo = reScaledLogo.transformed(by: imageTransform, highQualityDownsample: true)
        
        let params = [
            kCIInputImageKey: logo as Any,
            kCIInputBackgroundImageKey: ciCode as Any
        ]
        guard let filter = CIFilter(name: "CISourceOverCompositing", parameters: params),
              let output = filter.outputImage
        else { return }
        
        ciCode = output // update original
    }
}
