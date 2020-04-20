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
        
        generator = TCBBarcodeGenerator(transform: CGAffineTransform(scaleX: 10, y: 10))
    }

    @IBAction func generateBtn(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "Generate", message: "Choose Type", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "QRCode", style: .default, handler: { _ in
            self.generateCode(forType: .QRCode())
        }))
        
        alert.addAction(UIAlertAction(title: "AztecCode", style: .default, handler: { _ in
            self.generateCode(forType: .AztecCode())
        }))
        
        alert.addAction(UIAlertAction(title: "PDF417Code", style: .default, handler: { _ in
            self.generateCode(forType: .PDF417Code())
        }))
        
        alert.addAction(UIAlertAction(title: "DataMatrixCode", style: .default, handler: { _ in
            self.generateCode(forType: .DataMatrixCode)
        }))
        
        alert.addAction(UIAlertAction(title: "Code128", style: .default, handler: { _ in
            self.generateCode(forType: .Code128())
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func generateCode(forType type: TCBBarcodeGenerator.TCBBarcodeGeneratorType) {
        
        if let code = generator.generateCode(forType: type, source: inputeTxtFld.text!.cleanString) {
            
            imageView.image = code
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
}

extension String {
    
    var cleanString: String {
        let cleanedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedStr
    }
}

