# TCBBarcode

#### Demo
- [Demo Video](https://youtu.be/HvGyX19VH8Y)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Features

- [x] Barcode Scanner
- [x] Barcode Scanner View
- [x] Barcode Generator

## Requirements

- iOS 13.0+
- Xcode 11.0+

## Installation

#### CocoaPods
TCBBarcode is available through [CocoaPods](https://cocoapods.org). To install `TCBBarcode`, simply add the following line to your `Podfile`:

```ruby
pod 'TCBBarcode'
```
## Usage

#### Generator
```swift

let generator = TCBBarcodeGenerator(transform: CGAffineTransform(scaleX: 10, y: 10))

// .QRCode(level: .levelH)
if let code = generator.generateCode(forType: .QRCode(), source: inputeTxtFld.text!.cleanString) {
    
    imageView.image = code
}

```

#### Scanner
```swift

var previewView: UIView!
var scanner: TCBBarcodeScanner!

func setupScanner(frame: CGRect) {
    scanner = TCBBarcodeScanner(supportedTypes: TCBBarcodeScanner.availableTypes, playSoundOnSuccess: true
    , delegate: self)
    
    let previewFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - TCBBarcodeScannerView.codeLblHeight)
    if let previewLayer = scanner.previewLayer(withFrame: previewFrame) {
        previewView.layer.addSublayer(previewLayer)
    }else{
        let error = TCBBarcodeError.createCustomError(errorMessage: "Scanner preview configuration failed")
        print(error)
    }
}

func scan() {
    
    scanner.start()
}

func stop() {

    scanner.stop()
}

// MARK: - TCBBarcodeScannerDelegate

public func scanner(scanner: TCBBarcodeScanner, setupDidFail error: Error) {
    
    print(error)
}

public func scanner(scanner: TCBBarcodeScanner, didOutputCodeObject codeObject: TCBBarcodeScanner.CodeObject) {
    
    let codeStr = "\(codeObject.type): \(codeObject.code)"
    print(codeStr)
    
    switch detectType {
    case .box:
        showBox(frame: codeObject.bounds)
        
    case .line:
        showLine(corners: codeObject.corners)
        
    default:
        resetDetectView()
    }
}

// MARK: - Controls

func resetDetectView() {
    
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

func showBox(frame: CGRect) {
    resetDetectView()
    
    let codeBox = UIView(frame: frame)
    codeBox.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    detectView.addSubview(codeBox)
    detectView.isHidden = false
}

func showLine(corners: [CGPoint]) {
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
    shapeLayer.fillRule = .evenOdd
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.borderColor = UIColor.clear.cgColor
    shapeLayer.borderWidth = 0
    
    detectView.layer.addSublayer(shapeLayer)
    detectView.isHidden = false
}

```

#### Scanner View
```swift

var scannerView: TCBBarcodeScannerView!

func prepareScannerView() {
    
    let screenFrame = UIScreen.main.bounds
    let previewSize = CGSize(width: screenFrame.width - 40, height: 300)
    let scannerSize = TCBBarcodeScannerView.scannerFrameSizeFor(previewFrameSize: previewSize)
    let scannerFrame = CGRect(x: 20, y: 80, width: scannerSize.width, height: scannerSize.height)
    
    scannerView = TCBBarcodeScannerView.instance(frame: scannerFrame, delegate: self)
    view.addSubview(scannerView)
}

func changeDetectType() {

    scannerView.detectType = .line
}

func startScan() {

    scannerView.scan()
}

// MARK: - TCBBarcodeScannerViewDelegate

func scannerView(scannerView: TCBBarcodeScannerView, setupDidFail error: Error) {
    
}

func scannerView(scannerView: TCBBarcodeScannerView, didOutputCode code: String, codeType type: String) {
    print("Readable Type: \(type) -- Code: \(code)")
}

```

## Author

nferocious76, nferocious76@gmail.com

## License

TCBBarcode is available under the MIT license. See the [LICENSE](https://github.com/TheCodingBug/TCBBarcode/blob/master/LICENSE) file for more info.
