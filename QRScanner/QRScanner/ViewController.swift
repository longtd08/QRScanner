//
//  ViewController.swift
//  QRScanner
//
//  Created by Long DT on 8/11/2561 BE.
//  Copyright © 2561 Long DT. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imagePicker: UIImageView!
    @IBOutlet weak var resultView: UITextView!
    
    var imagePickerController = UIImagePickerController()
    lazy var vision = Vision.vision()
    
    let options = VisionBarcodeDetectorOptions(formats: .all )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.delegate = self
        
    }

    @IBAction func chooseImageButton(_ sender: Any) {
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func cameraButton(_ sender: Any) {
        imagePickerController.sourceType = .camera
        present(imagePickerController, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        imagePicker.image = image
        let visionImage = VisionImage(image: image)
        self.detecCode(visionImage: visionImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func detecCode(visionImage: VisionImage) {
        let barcodeDetector = vision.barcodeDetector(options: options)
        barcodeDetector.detect(in: visionImage, completion: { (barcodes, error) in
            guard error == nil, let barcodes = barcodes , !barcodes.isEmpty else {
                self.dismiss(animated: true, completion: nil)
                self.resultView.text = "No Barcode Detected"
                return
            }
            
            for barcode in barcodes {
                let rawValue = barcode.rawValue!
                let valueType = barcode.valueType
                
                switch valueType {
                case .URL:
                    let title = barcode.url!.title ?? ""
                    let url = barcode.url!.url ?? ""
                    self.resultView.text = "\(title)\nURL: \(url)"
                case .phone:
                    self.resultView.text = "Phone number: \(rawValue)"
                case .wiFi:
                    let ssid = barcode.wifi!.ssid ?? ""
                    let password = barcode.wifi!.password ?? "No password"
                    self.resultView.text = "Wifi: \(ssid)\nPassword: \(password)"
                default:
                    self.resultView.text = rawValue
                }
            }
        })
    }
    
}

