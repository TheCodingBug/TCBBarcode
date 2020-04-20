//
//  ScannerViewController.swift
//  TCBBarcode_Example
//
//  Created by Neil Francis Hipona on 4/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import TCBBarcode

class ScannerViewController: ViewController {
    
    @IBOutlet weak var scanButton: UIButton!
    
    var scannerView: TCBBarcodeScannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenFrame = UIScreen.main.bounds
        let previewSize = CGSize(width: screenFrame.size.width - 40, height: 300)
        let scannerSize = TCBBarcodeScannerView.scannerFrameSizeFor(previewFrameSize: previewSize)
        let scannerFrame = CGRect(x: 20, y: 80, width: scannerSize.width, height: scannerSize.height)
        
        scannerView = TCBBarcodeScannerView.instance(frame: scannerFrame, delegate: self)
        view.addSubview(scannerView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func scanButton(_ sender: Any) {
        
        scannerView.scan()
    }
    
}

extension ScannerViewController: TCBBarcodeScannerViewDelegate {
    
    func scannerView(scannerView: TCBBarcodeScannerView, setupDidFail error: Error) {
        
    }
    
    func scannerView(scannerView: TCBBarcodeScannerView, didOutputCode code: String, codeType type: String) {
        print("Readable Type: \(type) -- Code: \(code)")
    }
}
