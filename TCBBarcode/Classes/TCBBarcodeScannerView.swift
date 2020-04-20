//
//  TCBBarcodeScannerView.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 4/20/20.
//

import Foundation
import AVFoundation
import NFImageView

public protocol TCBBarcodeScannerViewDelegate: NSObjectProtocol {
    
    func scannerView(scannerView: TCBBarcodeScannerView, setupDidFail error: Error)
    func scannerView(scannerView: TCBBarcodeScannerView, didOutputCode code: String)
    
}

public class TCBBarcodeScannerView: UIView {
    
    @IBOutlet weak private var previewView: UIView!
    @IBOutlet weak private var codeLbl: UILabel!
    
    // MARK: - Declarations
    
    fileprivate var scanner: TCBBarcodeScanner!
    
    public weak var delegate: TCBBarcodeScannerViewDelegate!
    
    public var cornerRadius: CGFloat = 4.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            previewView.layer.cornerRadius = cornerRadius
        }
    }
    
    // MARK: - Initializers
    
    public class func instance(frame: CGRect, delegate: TCBBarcodeScannerViewDelegate!, supportedTypes types: [AVMetadataObject.ObjectType] = TCBBarcodeScanner.availableTypes, playSoundOnSuccess play: Bool = true) -> TCBBarcodeScannerView {
        
        let bundle = Bundle(for: TCBBarcodeScannerView.self)
        let nib = UINib(nibName: "TCBBarcodeScannerView", bundle: bundle)
        let scanner = nib.instantiate(withOwner: nil, options: nil).first as! TCBBarcodeScannerView
        
        scanner.frame = frame
        scanner.setup(frame: frame, delegate: delegate, supportedTypes: types, playSoundOnSuccess: play)
        
        return scanner
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    fileprivate func setup(frame: CGRect, delegate d: TCBBarcodeScannerViewDelegate!, supportedTypes types: [AVMetadataObject.ObjectType] = TCBBarcodeScanner.availableTypes, playSoundOnSuccess play: Bool = true) {
        
        delegate = d
        scanner = TCBBarcodeScanner(supportedTypes: types, playSoundOnSuccess: play, delegate: self)
        
        let previewFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - 30)
        if let previewLayer = scanner.previewLayer(withFrame: previewFrame) {
            previewView.layer.addSublayer(previewLayer)
        }else{
            let error = TCBBarcodeError.createCustomError(errorMessage: "Scanner preview configuration failed")
            delegate.scannerView(scannerView: self, setupDidFail: error)
        }
    }
}

// MARK: - Internal Controls

extension TCBBarcodeScannerView {
    
    fileprivate func prepareView() {
        
        clipsToBounds = true
        previewView.clipsToBounds = true
        
        layer.cornerRadius = cornerRadius
        previewView.layer.cornerRadius = cornerRadius
        
        codeLbl.text = ""
        codeLbl.textAlignment = .center
        codeLbl.textColor = .gray
    }
}

// MARK: - TCBBarcodeScannerDelegate

extension TCBBarcodeScannerView: TCBBarcodeScannerDelegate {
    
    public func scanner(scanner: TCBBarcodeScanner, setupDidFail error: Error) {
        
        delegate.scannerView(scannerView: self, setupDidFail: error)
    }
    
    public func scanner(scanner: TCBBarcodeScanner, didOutputCode code: String) {
        
        codeLbl.text = code
        delegate.scannerView(scannerView: self, didOutputCode: code)
    }
}

// MARK: - Controls

extension TCBBarcodeScannerView {
    
    public func scan() {
        
        scanner.start()
    }
    
    public func preferredInterfaceOrientation() -> UIInterfaceOrientationMask {
        
        return .portrait
    }
    
    public class func scannerFrameSizeFor(previewFrameSize size: CGSize) -> CGSize {
        
        return CGSize(width: size.width, height: size.height + 30)
    }
}
