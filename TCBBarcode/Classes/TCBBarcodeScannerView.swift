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
    func scannerView(scannerView: TCBBarcodeScannerView, didOutputCode code: String, codeType type: String)
    
}

public class TCBBarcodeScannerView: UIView {
    
    @IBOutlet weak private var previewView: UIView!
    @IBOutlet weak private var detectView: UIView!
    @IBOutlet weak private var codeLbl: UILabel!
    
    // MARK: - Declarations
    
    public enum CodeDetectType {
        case `default`
        case box
        case line
    }
    
    fileprivate static let codeLblHeight: CGFloat = 40
    fileprivate var scanner: TCBBarcodeScanner!
    
    public weak var delegate: TCBBarcodeScannerViewDelegate!
    
    public var cornerRadius: CGFloat = 4.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            previewView.layer.cornerRadius = cornerRadius
        }
    }
    
    public var codeTextColor: UIColor = .gray {
        didSet {
            codeLbl.textColor = codeTextColor
        }
    }
    
    public var detectType: CodeDetectType = .default
    
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
        
        prepareView()
    }
    
    fileprivate func setup(frame: CGRect, delegate d: TCBBarcodeScannerViewDelegate!, supportedTypes types: [AVMetadataObject.ObjectType] = TCBBarcodeScanner.availableTypes, playSoundOnSuccess play: Bool = true) {
        
        delegate = d
        scanner = TCBBarcodeScanner(supportedTypes: types, playSoundOnSuccess: play, delegate: self)
        
        let previewFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height - TCBBarcodeScannerView.codeLblHeight)
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
        
        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        
        clipsToBounds = true
        previewView.clipsToBounds = true
        previewView.backgroundColor = .clear
        previewView.layer.cornerRadius = cornerRadius
        
        detectView.clipsToBounds = true
        detectView.backgroundColor = .clear
        detectView.isHidden = true
        
        codeLbl.text = ""
        codeLbl.textAlignment = .center
        codeLbl.textColor = .gray
        codeLbl.backgroundColor = .clear
        codeLbl.font = UIFont.systemFont(ofSize: 12)
    }
    
    fileprivate func resetDetectView() {
        
        detectView.isHidden = true
        
        for view in detectView.subviews {
            view.removeFromSuperview()
        }
        
        if let sublayers = detectView.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    fileprivate func showBox(frame: CGRect) {
        resetDetectView()
        
        let codeBox = UIView(frame: frame)
        codeBox.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        previewView.addSubview(codeBox)
    }
    
    fileprivate func showLine(corners: [CGPoint]) {
        resetDetectView()
        
        let bezierPath = UIBezierPath(rect: previewView.frame)

        for (idx, point) in corners.enumerated() {
            if idx > 0 {
                bezierPath.addLine(to: point)
            }else{
                bezierPath.move(to: point)
            }
        }
        
        bezierPath.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        shapeLayer.strokeColor = UIColor.orange.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.fillColor = nil
        
        previewView.layer.addSublayer(shapeLayer)
    }
}

// MARK: - TCBBarcodeScannerDelegate

extension TCBBarcodeScannerView: TCBBarcodeScannerDelegate {
    
    public func scanner(scanner: TCBBarcodeScanner, setupDidFail error: Error) {
        
        delegate.scannerView(scannerView: self, setupDidFail: error)
    }
    
    public func scanner(scanner: TCBBarcodeScanner, didOutputCodeObject codeObject: TCBBarcodeScanner.CodeObject) {
        codeLbl.text = "\(codeObject.type): \(codeObject.code)"
        
        switch detectType {
        case .box:
            showBox(frame: codeObject.bounds)
            
        case .line:
            showLine(corners: codeObject.corners)
            
        default:
            resetDetectView()
        }
        
        delegate.scannerView(scannerView: self, didOutputCode: codeObject.code, codeType: codeObject.type)
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
        
        return CGSize(width: size.width, height: size.height + codeLblHeight)
    }
}
