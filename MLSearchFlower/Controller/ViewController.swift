//
//  ViewController.swift
//  MLSearchFlower
//
//  Created by 大容 林 on 2018/1/23.
//  Copyright © 2018年 DjangoCode. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController ,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    @IBAction func cameraButton(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var wikiLabel: UILabel!
    let imagePicker = UIImagePickerController()
    let wikiUrl = "https://en.wikipedia.org/w/api.php"
    var parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : "",
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500"
        ]
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        // Do any additional setup after loading the view, typically from a nib.
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImg = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = pickedImg
            guard let ciimage = CIImage(image: pickedImg) else {
                fatalError("Error line 33.")
            }
            detect(sourceImage: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    func detect(sourceImage: CIImage){
        guard let model = try? VNCoreMLModel (for: FlowerClassifier().model) else {
            fatalError("Error line 41.")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else{
                fatalError("Error line 45.")
            }
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier
                self.parameters["titles"] = firstResult.identifier
                self.GetUrlDataFromInternet(targetUrl: URL(string: self.wikiUrl)!, httpMethod: .get, para: self.parameters, completionHandler: { (json) in
                    let pageId = json["query"]["pageids"][0].stringValue
                    let desc = json["query"]["pages"][pageId]["extract"].stringValue
                    let flowerUrl = json["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                    self.imageView.sd_setImage(with: URL(string: flowerUrl), completed: nil)
                    self.wikiLabel.text = desc
                })
            }
            
        }
        let handler = VNImageRequestHandler(ciImage: sourceImage)
        do {
            try handler.perform([request])
        }catch{
            print("Error line 56.")
        }
        
    }
    func GetUrlDataFromInternet(targetUrl : URL , httpMethod :HTTPMethod, para : [String:String], completionHandler: @escaping (JSON) -> ()) {
        Alamofire.request( targetUrl , method : httpMethod, parameters: para)
            .responseJSON { response in
                if response.result.isSuccess {
                    let data : JSON = JSON(response.result.value!)
                    completionHandler(data)
                    print(data)
                } else {
                    print("Error: \(String(describing: response.result.error))")
                    completionHandler(JSON.null)
                }
        }
    }
    
}

