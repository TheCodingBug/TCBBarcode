//
//  ScannerViewController.swift
//  TCBBarcode_Example
//
//  Created by Neil Francis Hipona on 4/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import TCBBarcode

class ScannerViewController: UIViewController {
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var detectTypeControl: UISegmentedControl!
    
    var scannerView: TCBBarcodeScannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenFrame = UIScreen.main.bounds
        let previewSize = CGSize(width: screenFrame.width - 40, height: 300)
        let scannerSize = TCBBarcodeScannerView.scannerFrameSizeFor(previewFrameSize: previewSize)
        let scannerFrame = CGRect(x: 20, y: 80, width: scannerSize.width, height: scannerSize.height)
        
        //scannerView = TCBBarcodeScannerView.instance(frame: scannerFrame, delegate: self, forCaptureType: .barcode)
        scannerView = TCBBarcodeScannerView.instance(frame: scannerFrame, delegate: self, forCaptureType: .photo)
        view.addSubview(scannerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func detectTypeControl(_ sender: UISegmentedControl) {
        scannerView.detectType = TCBBarcodeScannerView.CodeDetectType(rawValue: sender.selectedSegmentIndex) ?? .default
    }
    
    @IBAction func scanButton(_ sender: Any) {
        scannerView.scan()
    }
    
    @IBAction func captureButton(_ sender: Any) {
        scannerView.capture()
    }
}

extension ScannerViewController: TCBBarcodeScannerViewDelegate {
    
    func scannerView(scannerView: TCBBarcodeScannerView, setupDidFail error: Error) {
        
    }
    
    func scannerView(scannerView: TCBBarcodeScannerView, didOutputCode code: String, codeType type: String) {
        print("Readable Type: \(type) -- Code: \(code)")
    }
}

extension ScannerViewController: TCBBarcodePhotoScannerViewDelegate {
    
    func scanner(willBeginCaptureForPhotoScanner scanner: TCBBarcodeScanner) {
        captureButton.isEnabled = false
    }
    
    func scanner(willCaptureForPhotoScanner scanner: TCBBarcodeScanner) {
 
    }

    func scanner(didCapturePhotoForPhotoScanner scanner: TCBBarcodeScanner) {
        
    }
    
    func scanner(didFinishProcessingPhotoForPhotoScanner scanner: TCBBarcodeScanner, photo: UIImage?, error: Error?) {
        print("didFinishCaptureForPhotoScanner photo: \(photo) -- error: ", error)
        
        guard let photo = photo else { return }
        UIImageWriteToSavedPhotosAlbum(photo, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func scanner(didFinishCaptureForPhotoScanner scanner: TCBBarcodeScanner, error: Error?) {
        print("didFinishCaptureForPhotoScanner error: ", error)
        captureButton.isEnabled = true
    }
}

extension ScannerViewController {
    private func savePhotoCapture(inView: UIView) {
        guard let snapshot = inView.toImage(scale: 10) else { return }
        UIImageWriteToSavedPhotosAlbum(snapshot, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func saveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("saveImage error: ", error)
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Photo Saved", message: "Check your Photo in your camera roll.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}

extension UIView {
    func toImage(opaque: Bool = true, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, opaque, scale)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshot
    }
}
