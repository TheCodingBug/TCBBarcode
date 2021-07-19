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
    
    /// Scanner set up did fail with error
    func scanner(scanner: TCBBarcodeScanner, setupDidFail error: Error)
    
    /// Scanner did output code object
    func scanner(scanner: TCBBarcodeScanner, didOutputCodeObject codeObject: TCBBarcodeScanner.CodeObject)
}

public protocol TCBBarcodePhotoScannerDelegate: TCBBarcodeScannerDelegate {
    
    /// This callback is always delivered first for a particular capture request. It is delivered as soon as possible after you call -capturePhotoWithSettings:delegate:, so you can know what to expect in the remainder of your callbacks.
    func scanner(willBeginCaptureForPhotoScanner scanner: TCBBarcodeScanner)
    
    /// The timing of this callback is analogous to AVCaptureStillImageOutput's capturingStillImage property changing from NO to YES. The callback is delivered right after the shutter sound is heard (note that shutter sounds are suppressed when Live Photos are being captured).
    func scanner(willCaptureForPhotoScanner scanner: TCBBarcodeScanner)
    
    /// The timing of this callback is analogous to AVCaptureStillImageOutput's capturingStillImage property changing from YES to NO.
    func scanner(didCapturePhotoForPhotoScanner scanner: TCBBarcodeScanner)
    
    /// This callback fires resolvedSettings.expectedPhotoCount number of times for a given capture request. Note that the photo parameter is always non nil, even if an error is returned. The delivered AVCapturePhoto's rawPhoto property can be queried to know if it's a RAW image or processed image.
    func scanner(didFinishProcessingPhotoForPhotoScanner scanner: TCBBarcodeScanner, photo: UIImage?, error: Error?)
    
    /// This callback always fires last and when it does, you may clean up any state relating to this photo capture.
    func scanner(didFinishCaptureForPhotoScanner scanner: TCBBarcodeScanner, error: Error?)
}

public class TCBBarcodeScanner: NSObject {
    
    public struct CodeObject {
        var code: String
        var type: String
        
        var bounds: CGRect
        var corners: [CGPoint]
        
        var referenceBounds: CGRect
        var referenceCorners: [CGPoint]
    }
    
    public enum TCBBarcodeCaptureType {
        case barcode, photo
    }
    
    // MARK: - Declarations
    internal var captureType: TCBBarcodeScanner.TCBBarcodeCaptureType = .barcode
    internal var session: AVCaptureSession!
    internal var previewLayer: AVCaptureVideoPreviewLayer!

    internal lazy var queue: DispatchQueue = {
        DispatchQueue(label: "com.TCBBarcodeScanner.queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .workItem, target: .main)
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
    
    public var isRunning: Bool {
        if let _ = session {
            return session.isRunning
        }
        
        return false
    }
    
    // MARK: - Initializers
    
    private override init() {
        super.init()
    }
    
    convenience public init(supportedTypes types: [AVMetadataObject.ObjectType] = availableTypes, position: AVCaptureDevice.Position = .unspecified, playSoundOnSuccess play: Bool = true, delegate d: TCBBarcodeScannerDelegate!) {
        self.init()
        
        supportedTypes = types
        playSound = play
        delegate = d
        
        setupSession(position: position)
    }
    
    internal func setupSession(position: AVCaptureDevice.Position) {
        
        let captureDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: captureDeviceTypes, mediaType: .video, position: position)
        
        guard let captureDevice = bestDevice(in: position, discoverySession: discoverySession) else {
            let error = TCBBarcodeError.createCustomError(errorMessage: "Missing capture devices")
            delegate.scanner(scanner: self, setupDidFail: error)
            return
        }
        
        guard let inputDevice = try? AVCaptureDeviceInput(device: captureDevice) else {
            let error = TCBBarcodeError.createCustomError(errorMessage: "Input capture device not found")
            delegate.scanner(scanner: self, setupDidFail: error)
            return
        }
        
        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        
        if session.canAddInput(inputDevice) {
            session.addInput(inputDevice)
        }else{
            let error = TCBBarcodeError.createCustomError(errorMessage: "Input device configuration failed")
            delegate.scanner(scanner: self, setupDidFail: error)
        }
        
        // add metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
            metadataOutput.metadataObjectTypes = supportedTypes
        }else{
            let error = TCBBarcodeError.createCustomError(errorMessage: "Metadata configuration failed")
            delegate.scanner(scanner: self, setupDidFail: error)
        }
        
        // add photo output for still images
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
    }
    
    internal func bestDevice(in position: AVCaptureDevice.Position, discoverySession: AVCaptureDevice.DiscoverySession) -> AVCaptureDevice? {
        
        let devices = discoverySession.devices
        guard !devices.isEmpty else { return nil }
        
        let cameraDevice = position == .unspecified ? devices.first : devices.first(where: { device in device.position == position })
        guard let captureDevice = cameraDevice else { return nil }
        
        return captureDevice
    }
    
    internal func outputs(forType type: AnyObject.Type, in outputs: [AVCaptureOutput]) -> AVCaptureOutput? {
        
        guard let captureOutput = outputs.first(where: { output in output.isKind(of: type) }) else { return nil }
        return captureOutput
    }
}

// MARK: - Controls

extension TCBBarcodeScanner {
    
    public func previewLayer(withFrame frame: CGRect, videoGravity: AVLayerVideoGravity = .resizeAspectFill, videoOrientation: AVCaptureVideoOrientation = .portrait, isVideoMirrored: Bool = false, isVideoStabilized: AVCaptureVideoStabilizationMode = .auto) -> AVCaptureVideoPreviewLayer! {
        
        guard let session = session, session.inputs.count > 0 else { return nil } // no active session
        // guard let metadataOutput = session.outputs.first as? AVCaptureMetadataOutput else { return nil }
        guard let captureOutput = outputs(forType: AVCaptureMetadataOutput.self, in: session.outputs) as? AVCaptureMetadataOutput else { return nil }

        if previewLayer == nil { // create preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
        }

        previewLayer.frame = frame
        previewLayer.videoGravity = videoGravity
        
        // get videw connection
        if let videoConnection = previewLayer.connection {
            // set preferred video orientation -- if video orientation is supported
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = videoOrientation
            }
            
            // set preferred video mirroring -- if mirroring is supported & automatic adjust is not set
            if videoConnection.isVideoMirroringSupported && !videoConnection.automaticallyAdjustsVideoMirroring {
                videoConnection.isVideoMirrored = isVideoMirrored
            }
            
            // set preferred video stabilization mode -- if video stabilization is supported
            if videoConnection.isVideoStabilizationSupported {
                videoConnection.preferredVideoStabilizationMode = isVideoStabilized
            }
        }

        // add point of interest
        let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: frame)
        captureOutput.rectOfInterest = rectOfInterest
        
        return previewLayer
    }
    
    /// Scan area should be relative to preview frame
    public func updateScanArea(frame: CGRect) {

        guard let session = session, session.inputs.count > 0 else { return } // no active session
        guard let captureOutput = outputs(forType: AVCaptureMetadataOutput.self, in: session.outputs) as? AVCaptureMetadataOutput else { return }
        
        // add point of interest
        let rectOfInterest = previewLayer.metadataOutputRectConverted(fromLayerRect: frame)
        captureOutput.rectOfInterest = rectOfInterest
    }
    
    /// Start session and start scanning
    public func start(forCaptureType type: TCBBarcodeScanner.TCBBarcodeCaptureType = .barcode) {
        captureType = type
        
        if let _ = session {
            session.startRunning()
        }
    }
    
    /// Stop scanning
    public func stop() {
        if let _ = session {
            session.stopRunning()
        }
    }
    
    /// Stop scanning and removes session
    public func purge() {
        if let _ = session {
            session.stopRunning()
            session = nil
        }
    }
    
    public func capturePhoto(flashMode: AVCaptureDevice.FlashMode = .auto) {
        
        guard let session = session, session.inputs.count > 0 else { return } // no active session
        guard let captureOutput = outputs(forType: AVCapturePhotoOutput.self, in: session.outputs) as? AVCapturePhotoOutput else { return }
        
        let hasHEVC = captureOutput.availablePhotoCodecTypes.contains(.hevc)
        let photoSettings = hasHEVC ? AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc]) : AVCapturePhotoSettings()
        photoSettings.flashMode = flashMode
        
        captureOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension TCBBarcodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if captureType == .barcode {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let codeObject = previewLayer.transformedMetadataObject(for: readableObject) as? AVMetadataMachineReadableCodeObject else { return }
                guard let readableCode = readableObject.stringValue else { return }
                
                if playSound {
                    let soundID = SystemSoundID(kSystemSoundID_Vibrate)
                    AudioServicesPlayAlertSound(soundID)
                }
                
                let codeObj = CodeObject(code: readableCode, type: codeObject.type.rawValue, bounds: codeObject.bounds, corners: codeObject.corners, referenceBounds: readableObject.bounds, referenceCorners: readableObject.corners)
                delegate.scanner(scanner: self, didOutputCodeObject: codeObj)
                
                stop()
            }
        }
    }
}

// MARK: AVCapturePhotoCaptureDelegate

extension TCBBarcodeScanner: AVCapturePhotoCaptureDelegate {
    
    // This callback is always delivered first for a particular capture request. It is delivered as soon as possible after you call -capturePhotoWithSettings:delegate:, so you can know what to expect in the remainder of your callbacks.
    public func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
        guard let delegate = delegate as? TCBBarcodePhotoScannerDelegate else { return }
        delegate.scanner(willBeginCaptureForPhotoScanner: self)
    }
    
    // The timing of this callback is analogous to AVCaptureStillImageOutput's capturingStillImage property changing from NO to YES. The callback is delivered right after the shutter sound is heard (note that shutter sounds are suppressed when Live Photos are being captured).
    public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        guard let delegate = delegate as? TCBBarcodePhotoScannerDelegate else { return }
        delegate.scanner(willCaptureForPhotoScanner: self)
    }
    
    // The timing of this callback is analogous to AVCaptureStillImageOutput's capturingStillImage property changing from YES to NO.
    public func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        guard let delegate = delegate as? TCBBarcodePhotoScannerDelegate else { return }
        delegate.scanner(didCapturePhotoForPhotoScanner: self)
    }
    
    // This callback fires resolvedSettings.expectedPhotoCount number of times for a given capture request. Note that the photo parameter is always non nil, even if an error is returned. The delivered AVCapturePhoto's rawPhoto property can be queried to know if it's a RAW image or processed image.
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {

        guard let delegate = delegate as? TCBBarcodePhotoScannerDelegate else { return }
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData, scale: UIScreen.main.scale)
        else {
            let cError = TCBBarcodeError.createCustomError(errorMessage: "Can't process capture photo")
            delegate.scanner(didFinishProcessingPhotoForPhotoScanner: self, photo: nil, error: cError)
            return }
        
        if playSound {
            let soundID = SystemSoundID(kSystemSoundID_Vibrate)
            AudioServicesPlayAlertSound(soundID)
        }
        
        delegate.scanner(didFinishProcessingPhotoForPhotoScanner: self, photo: image, error: error)
    }
    
    // This callback always fires last and when it does, you may clean up any state relating to this photo capture.
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        guard let delegate = delegate as? TCBBarcodePhotoScannerDelegate else { return }
        delegate.scanner(didFinishCaptureForPhotoScanner: self, error: error)
    }
}
