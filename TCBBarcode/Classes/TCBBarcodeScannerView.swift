//
//  TCBBarcodeScannerView.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 4/20/20.
//

import Foundation
import AVFoundation

public protocol TCBBarcodeScannerViewDelegate: NSObjectProtocol {
    
    func scannerView(scannerView: TCBBarcodeScannerView, setupDidFail error: Error)
    func scannerView(scannerView: TCBBarcodeScannerView, didOutputCode code: String)
    
}

public class TCBBarcodeScannerView: UIView {
    
    // MARK: - Declarations
    fileprivate var scanner: TCBBarcodeScanner!
    
    public weak var delegate: TCBBarcodeScannerViewDelegate!
    
    // MARK: - Initializers
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.init()
        
    }
    
    override public func encode(with aCoder: NSCoder) {
        
    }
    
    convenience public init(frame: CGRect, delegate d: TCBBarcodeScannerViewDelegate!, supportedTypes types: [AVMetadataObject.ObjectType] = TCBBarcodeScanner.availableTypes, playSoundOnSuccess play: Bool = true) {
        self.init(frame: frame)
        
        delegate = d
        scanner = TCBBarcodeScanner(supportedTypes: types, playSoundOnSuccess: play, delegate: self)
        
        let previewFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        if let previewLayer = scanner.previewLayer(withFrame: previewFrame) {
            layer.addSublayer(previewLayer)
        }else{
            let error = TCBBarcodeError.createCustomError(errorMessage: "Scanner preview configuration failed")
            delegate.scannerView(scannerView: self, setupDidFail: error)
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}


extension TCBBarcodeScannerView: TCBBarcodeScannerDelegate {
    
    public func scanner(scanner: TCBBarcodeScanner, setupDidFail error: Error) {
        
        delegate.scannerView(scannerView: self, setupDidFail: error)
    }
    
    public func scanner(scanner: TCBBarcodeScanner, didOutputCode code: String) {
        
        delegate.scannerView(scannerView: self, didOutputCode: code)
    }
}
