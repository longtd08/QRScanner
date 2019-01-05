//
//  ViewController.swift
//  QRScanner
//
//  Created by Long DT on 8/11/2561 BE.
//  Copyright © 2561 Long DT. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var resultView: UITextView!
    
    var imagePickerController = UIImagePickerController()
    lazy var vision = Vision.vision()
    let options = VisionBarcodeDetectorOptions(formats: .all )
    let captureSession = AVCaptureSession()
    var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.delegate = self
        self.setupLiveCamera()
    }

    @IBAction func chooseImageButton(_ sender: Any) {
        imagePreview.isHidden = false
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func cameraButton(_ sender: Any) {
        self.resultView.text = ""
        imagePreview.isHidden = true
        videoPreviewLayer.isHidden = false
        self.startScanQRcode()
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }
        imagePreview.image = image
        let visionImage = VisionImage(image: image)
        self.detecCode(visionImage: visionImage)
        self.view.bringSubviewToFront(self.imagePreview)
        videoPreviewLayer.isHidden = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.startScanQRcode()
        self.resultView.text = ""
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
                    let password = barcode.wifi!.password ?? ""
                    self.resultView.text = "Wifi: \(ssid)\nPassword: \(password)"
                default:
                    self.resultView.text = rawValue
                }
            }
        })
    }
    
    private func metaObjectTypes() -> [AVMetadataObject.ObjectType] {
        return [.qr,
                .aztec,
                .code128,
                .code39,
                .code39Mod43,
                .code93,
                .dataMatrix,
                .ean13,
                .ean8,
                .face,
                .interleaved2of5,
                .itf14,
                .pdf417,
                .upce
        ]
    }
    
    func setupLiveCamera() {
        self.view.layoutIfNeeded()
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = self.metaObjectTypes()
            videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: self.imagePreview.frame.size.width, height: self.imagePreview.frame.size.height)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(videoPreviewLayer)
            if self.captureSession.isRunning == false {
                self.captureSession.startRunning()
            }
        } catch {
            
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        self.stopScanQRcode()
        if let metadataObject = metadataObjects.first{
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            guard let stringValue = readableObject.stringValue else {
                return
            }
            self.resultView.text = stringValue
        }
        
    }
    
    func startScanQRcode() {
        imagePreview.isHidden = true
        videoPreviewLayer.isHidden = false
        if self.captureSession.isRunning == false {
            self.captureSession.startRunning()
        }
    }
    
    func stopScanQRcode() {
        if self.captureSession.isRunning == true {
            self.captureSession.stopRunning()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    @IBAction func shareClick(_ sender: Any) {
        let productUrl = resultView.text
        let shareContent = [ productUrl ]
        let activityViewController = UIActivityViewController(activityItems: shareContent as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)

    }
}

