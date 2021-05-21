//
//  TCBBarcodeObject.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 5/21/21.
//

import Foundation

public class TCBBarcodeObject: NSObject {
   
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
    
    public func applyTransparent() -> TCBBarcodeObject {
        let params = [kCIInputImageKey: ciCode as Any]
        if let filter = CIFilter(name: "CIMaskToAlpha", parameters: params),
           let output = filter.outputImage {
            ciCode = output // update original
        }

        return self
    }
    
    public func applyInvert() -> TCBBarcodeObject {
        let params = [kCIInputImageKey: ciCode as Any]
        if let filter = CIFilter(name: "CIColorInvert", parameters: params),
           let output = filter.outputImage {
            ciCode = output // update original
        }
        
        return self
    }
    
    public func applyTint(color: UIColor) -> TCBBarcodeObject {
        // apply color
        let colorParams = [kCIInputColorKey: color.ciColor as Any]
        if let colorFilter = CIFilter(name: "CIConstantColorGenerator", parameters: colorParams),
           let colorOutput = colorFilter.outputImage {
            
            // apply composite
            let compositeParams = [
                kCIInputImageKey: ciCode as Any,
                kCIInputBackgroundImageKey: colorOutput as Any
            ]
            if let compositeFilter = CIFilter(name: "CIMultiplyCompositing", parameters: compositeParams),
               let compositeOutput = compositeFilter.outputImage {
                ciCode = compositeOutput // update original
            }
        }
        
        return self
    }
    
    public func applyBlend(withImage image: CGImage) -> TCBBarcodeObject {
        let params = [
            kCIInputMaskImageKey: ciCode as Any,
            kCIInputBackgroundImageKey: image as Any
        ]
        if let filter = CIFilter(name: "CIBlendWithMask", parameters: params),
           let output = filter.outputImage {
            ciCode = output // update original
        }
        
        return self
    }
    
    public func applyLogo(withImage image: CIImage) -> TCBBarcodeObject {
        
        let midX = ciCode.extent.midX - image.extent.size.width * 0.2 // 20%
        let midY = ciCode.extent.midY - image.extent.size.height * 0.2 // 20%
        let imageTransform = CGAffineTransform(translationX: midX, y: midY)
        let logo = image.transformed(by: imageTransform, highQualityDownsample: true)
        
        let params = [
            kCIInputImageKey: logo as Any,
            kCIInputBackgroundImageKey: ciCode as Any
        ]
        if let filter = CIFilter(name: "CISourceOverCompositing", parameters: params),
           let output = filter.outputImage {
            ciCode = output // update original
        }
        
        return self
    }
}
