//
//  ViewController.swift
//  TCBBarcode
//
//  Created by nferocious76 on 04/18/2020.
//  Copyright (c) 2020 nferocious76. All rights reserved.
//

import UIKit
import TCBBarcode

class ViewController: UIViewController {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var inputeTxtFld: UITextField!
    @IBOutlet weak var generateBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var generator: TCBBarcodeGenerator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        generator = TCBBarcodeGenerator()
    }

    @IBAction func generateBtn(_ sender: UIButton) {
        
        if let code = generator.generateCode(forType: .Code128(barcodeHeight: 100, quietSpace: 2), source: inputeTxtFld.text!.cleanString) {
            
            imageView.image = code
        }
    }
    
}

extension String {
    
    var cleanString: String {
        let cleanedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedStr
    }
}

