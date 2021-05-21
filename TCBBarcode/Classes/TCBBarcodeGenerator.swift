//
//  TCBBarcodeGenerator.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 4/18/20.
//

// https://help.accusoft.com/BarcodeXpressiOS/v12.1/html/barcodetypes.html

import Foundation

public class TCBBarcodeGenerator: NSObject {
    
    // MARK: - Declarations
    
    private var transform: CGAffineTransform = .identity
    
    public enum TCBBarcodeGeneratorType {
        
        public enum QRCodeLevel: String {
            case levelL = "L" /// 76
            case levelM = "M" /// 77
            case levelQ = "Q" /// 81
            case levelH = "H" /// 72
        }
        
        case `default`
        
        /**
         - Parameter level: QRCodeLevel
         */
        case QRCode(level: QRCodeLevel = .levelM)
        
        /**
         - Parameter layer: Valid values range from 1 to 32.
         */
        case AztecCode(layer: Int = 32)
        
        /**
         - Parameter minWidth: The minimum width of the generated barcode in pixels. Number. Min: 56.0 Max: 583.0
         - Parameter maxWidth: The maximum width of the generated barcode in pixels. Number. Min: 56.0 Max: 583.0
         - Parameter minHeight: The minimum height of the generated barcode in pixels. Number. Min: 13.0 Max: 283.0
         - Parameter maxHeight: The maximum height of the generated barcode in pixels. Number. Min: 13.0 Max: 283.0
         - Parameter dataColumns: The number of data columns in the generated barcode. Number. Min: 1.0 Max: 30.0
         - Parameter inputRows: The number of rows in the generated barcode. Number. Min: 3.0 Max: 90.0
         - Parameter preferredAspectRatio: The preferred aspect ratio of the generated barcode. Number. Min: 0.0
         - Parameter compactionMode: The compaction mode of the generated barcode.Number. Min: 0.0 Max: 3.0
         - Parameter compactStyle: Force a compact style Aztec code to @YES or @NO. Set to nil for automatic. Number. Min: 0.0 Max: 1.0
         - Parameter correctionLevel: The correction level ratio of the generated barcode. Number. Min: 0.0 Max: 8.0
         - Parameter alwaysSpecifyCompaction: Force compaction style to @YES or @NO. Set to nil for automatic. Number. Min: 0.0 Max: 1.0
        */
        case PDF417Code(minWidth: NSNumber = 56, maxWidth: NSNumber = 583, minHeight: NSNumber = 50, maxHeight: NSNumber = 100, dataColumns: NSNumber = 10, inputRows: NSNumber = 10, preferredAspectRatio: NSNumber = 3, compactionMode: NSNumber = 3, compactStyle: Bool? = nil, correctionLevel: NSNumber = 4, alwaysSpecifyCompaction: Bool? = nil)
        
        case DataMatrixCode
        
        /**
         - Parameter barcodeHeight: The height, in pixels, of the generated barcode.
         - Parameter quietSpace: The number of empty white pixels that should surround the barcode.
        */
        case Code128(barcodeHeight: NSNumber = 32, quietSpace: NSNumber = 7)

        var description: String {
            
            switch self {
                
            case .QRCode:
                return "CIQRCodeGenerator"
                
            case .AztecCode:
                return "CIAztecCodeGenerator"
                
            case .PDF417Code:
                return "CIPDF417BarcodeGenerator"
                
            case .Code128:
                return "CICode128BarcodeGenerator"
                
            default:
                return "CIBarcodeGenerator"
            }
        }
    }
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
    }
    
    convenience public init(transform t: CGAffineTransform = CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale)) {
        self.init()
        
        transform = t
    }
    
    // MARK: - Helpers
    
    internal func codeDescriptor(forType type: TCBBarcodeGeneratorType, data: Data) -> CIImage? {
        
        switch type {
        case .QRCode(let level):
            let params: [String : Any] = [
                "inputMessage": data,
                "inputCorrectionLevel": level.rawValue
            ]

            return filter(type: type, parameters: params)
            
        case .AztecCode(let layer):
             let params: [String : Any] = [
                "inputMessage": data,
                "inputLayers": layer
                ]
             
             return filter(type: type, parameters: params)
            
        case .PDF417Code(let minWidth, let maxWidth, let minHeight, let maxHeight, let dataColumns, let inputRows, let preferredAspectRatio, let compactionMode, let compactStyle, let correctionLevel, let alwaysSpecifyCompaction):
            
            var params: [String : Any] = [
                "inputMessage": data,
                "inputMinWidth": minWidth,
                "inputMaxWidth": maxWidth,
                "inputMinHeight": minHeight,
                "inputMaxHeight": maxHeight,
                "inputDataColumns": dataColumns,
                "inputRows": inputRows,
                "inputPreferredAspectRatio": preferredAspectRatio,
                "inputCompactionMode": compactionMode,
                "inputCorrectionLevel": correctionLevel
            ]
            
            if let compactStyle = compactStyle {
                params["inputCompactStyle"] = NSNumber(value: compactStyle)
            }
            
            if let specifyCompaction = alwaysSpecifyCompaction {
                params["inputAlwaysSpecifyCompaction"] = NSNumber(value: specifyCompaction)
            }
                        
            return filter(type: type, parameters: params)
            
        case .DataMatrixCode:
            
            let descriptor = CIDataMatrixCodeDescriptor(payload: data, rowCount: 90, columnCount: 30, eccVersion: .v200)
            let params = ["inputBarcodeDescriptor": descriptor]
            
            return filter(type: type, parameters: params as [String : Any])
            
        case .Code128(let barcodeHeight, let quietSpace):
            let params: [String : Any] = [
                "inputMessage": data,
                "inputQuietSpace": quietSpace,
                "inputBarcodeHeight": barcodeHeight
            ]
            
            return filter(type: type, parameters: params)
            
        default:
            return nil
        }
    }
    
    internal func filter(type: TCBBarcodeGeneratorType, parameters params: [String : Any]?) -> CIImage? {

        let filter = CIFilter(name: type.description, parameters: params)
        guard let output = filter?.outputImage else { return nil }
        let scaled = output.transformed(by: transform, highQualityDownsample: true)
        
        return scaled
    }
}

// MARK: - Public Controls
extension TCBBarcodeGenerator {
    public func generateCode(forType type: TCBBarcodeGeneratorType, source: String) -> UIImage? {
        
        guard let data = source.data(using: .ascii) else { return nil }
        guard let output = codeDescriptor(forType: type, data: data) else { return nil }
        
        return UIImage(ciImage: output)
    }
}
