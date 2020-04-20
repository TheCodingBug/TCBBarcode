//
//  TCBBarcodeScanner.swift
//  TCBBarcode
//
//  Created by Neil Francis Hipona on 4/19/20.
//

// https://help.accusoft.com/BarcodeXpressiOS/v12.1/html/barcodetypes.html

import Foundation
import AVFoundation

public protocol TCBBarcodeScannerDelegate: NSObjectProtocol {
    
    func scanner(scanner: TCBBarcodeScanner, setupDidFail error: Error)
    func scanner(scanner: TCBBarcodeScanner, didOutputCode code: String)
}

public class TCBBarcodeScanner: NSObject {
    
    internal var session: AVCaptureSession!
    internal var previewLayer: AVCaptureVideoPreviewLayer!
    
    internal lazy var queue: DispatchQueue = {
        DispatchQueue(label: "com.TCBBarcodeScanner.queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: .global())
    }()
    
    public static let availableTypes: [AVMetadataObject.ObjectType] = [
        .upce,
        .code39,
        .code39Mod43,
        .ean13,
        .ean8,
        .code93,
        .code128,
        .pdf417,
        .qr,
        .aztec,
        .interleaved2of5,
        .itf14,
        .dataMatrix
    ]
    
    public weak var delegate: TCBBarcodeScannerDelegate!
    public var supportedTypes: [AVMetadataObject.ObjectType] = []
    public var playSound: Bool = true
    
    private override init() {
        super.init()
    }
    
    convenience public init(supportedTypes types: [AVMetadataObject.ObjectType] = availableTypes, playSoundOnSuccess play: Bool = true, delegate d: TCBBarcodeScannerDelegate!) {
        self.init()
        
        supportedTypes = types
        playSound = play
        delegate = d
    }
    
    internal func setupSession() {
        
        session = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            let error = TCBBarcodeError.createCustomError(errorMessage: "Capture device not found")
            delegate.scanner(scanner: self, setupDidFail: error)
            return
        }
        
        guard let inputDevice = try? AVCaptureDeviceInput(device: captureDevice) else {
            let error = TCBBarcodeError.createCustomError(errorMessage: "Input capture device not found")
            delegate.scanner(scanner: self, setupDidFail: error)
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(inputDevice) {
            session.addInput(inputDevice)
        }else{
            let error = TCBBarcodeError.createCustomError(errorMessage: "Input device configuration failed")
            delegate.scanner(scanner: self, setupDidFail: error)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
            metadataOutput.metadataObjectTypes = supportedTypes
        }else{
            let error = TCBBarcodeError.createCustomError(errorMessage: "Metadata configuration failed")
            delegate.scanner(scanner: self, setupDidFail: error)
        }
        
        session.commitConfiguration()
    }
}

// MARK: - Actions

extension TCBBarcodeScanner {
    
    public var isRunning: Bool {
        if let _ = session {
            return session.isRunning
        }
        
        return false
    }
    
    public func previewLayer(withFrame frame: CGRect, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> AVCaptureVideoPreviewLayer! {
        
        guard let _ = session else { return nil } // no active session

        if previewLayer == nil { // create preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
        }
        
        previewLayer.videoGravity = videoGravity
        previewLayer.frame = frame
        
        return previewLayer
    }
    
    public func run() {
        
        if let _ = session {
            session.startRunning()
        }
    }
    
    public func stop() {
        
        if let _ = session {
            session.stopRunning()
            session = nil
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension TCBBarcodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let readableCode = readableObject.stringValue else { return }
            
            if playSound {
                let soundID = SystemSoundID(kSystemSoundID_Vibrate)
                AudioServicesPlayAlertSound(soundID)
            }
            
            // process readableCode
            delegate.scanner(scanner: self, didOutputCode: readableCode)
            stop()
        }
    }
}
