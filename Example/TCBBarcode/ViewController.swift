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
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    var generator: TCBBarcodeGenerator!
    var codeObject: TCBBarcodeObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        imageView.image = UIImage(named: "nf-logo")
        generator = TCBBarcodeGenerator(transform: CGAffineTransform(scaleX: 10, y: 10))
        
        segmentControl.setTitle("Apply Tint", forSegmentAt: 0)
        segmentControl.setTitle("Apply Blend", forSegmentAt: 1)
        segmentControl.setTitle("Apply Logo", forSegmentAt: 2)
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
    
    @IBAction func segment(_ sender: UISegmentedControl) {
        guard let codeObject = codeObject else { return }
        let logoImage = UIImage(named: "nf-logo")!
        let image = logoImage.cgImage!
        
        switch sender.selectedSegmentIndex {
        case 0:
            codeObject.applyTint(color: .green)
        case 1:
            codeObject.applyBlend(withImage: image)
        case 2:
            codeObject.applyLogo(withImage: image)
        default:
            break
        }
        
        // apply new code
        imageView.image = codeObject.code
    }
    
    func generateCode(forType type: TCBBarcodeGenerator.TCBBarcodeGeneratorType) {
        if let codeObject = generator.generateCode(forType: type, source: inputeTxtFld.text!.cleanString) {
            self.codeObject = codeObject
            imageView.image = codeObject.code
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

