//
//  TestSwift.swift
//  Runner
//
//  Created by Marian Gieseler on 04.06.19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Flutter
import UIKit
import Social

public class SwiftFlutterSharePlugin: NSObject, FlutterPlugin, UIDocumentInteractionControllerDelegate {

    var interaction:UIDocumentInteractionController!
    var flutterResult: FlutterResult!
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_share", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.flutterResult = result;
        switch call.method {
            case "copyToClippboard" :
                self.copyToClippboard(arguments: call.arguments, result: result)
            case "text" :
                self.text(arguments: call.arguments)
            case "file" :
                self.file(arguments: call.arguments)
            case "files":
                self.files(arguments: call.arguments)
            case "facebookInstalled":
                result(facebookInstalled())
            case "instagramInstalled":
                result(instagramInstalled())
            case "twitterInstalled":
                result(twitterInstalled())
            case "whatsappInstalled":
                result(whatsappInstalled())    
            default:
                break
        }
    }

    func facebookInstalled() -> Bool{
        var components = URLComponents()
        components.scheme = "fbauth2"
        components.path = "/"
        return UIApplication.shared.canOpenURL(components.url!)
    }

    func instagramInstalled() -> Bool{
        return UIApplication.shared.canOpenURL(URL(string: "instagram://app")!)
    }

    func twitterInstalled() -> Bool{
        return UIApplication.shared.canOpenURL(URL(string:"twitter://")!)
    }

    func whatsappInstalled() -> Bool{
        return UIApplication.shared.canOpenURL(URL(string:"whatsapp://")!)
    }
    
    func copyToClippboard(arguments:Any?, result: FlutterResult){
        let pasteboard = UIPasteboard.general
        pasteboard.string = (arguments as! NSDictionary).value(forKey: "text") as! String
        result(true)
    }

    func text(arguments:Any?) -> Void {
        let argsMap = arguments as! NSDictionary
        let text:String = argsMap.value(forKey: "text") as! String

        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        // present the view controller
        let controller = UIApplication.shared.keyWindow!.rootViewController as! FlutterViewController
        activityViewController.popoverPresentationController?.sourceView = controller.view
        activityViewController.completionWithItemsHandler = {(activityType, completed: Bool, returnedItems: [Any]?, error: Error?) in
            self.doneSharingHandler(activityType:activityType, completed: completed, returnedItems: returnedItems, error: error)
        }

        controller.show(activityViewController, sender: self)
    }

    func file(arguments: Any?) -> Void {
        let argsMap = arguments as! NSDictionary
        let name = argsMap.value(forKey: "name") as! String
        let text = argsMap.value(forKey: "text") as? String
        // load the file
        let docsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask , true).first!
        let contentUri = NSURL(fileURLWithPath: docsPath).appendingPathComponent(name)

        guard let imageData = try?  Data(contentsOf:  contentUri!.absoluteURL) else {
            print("There was an error!")
            return;
        }

        let controller = UIApplication.shared.keyWindow!.rootViewController as! FlutterViewController
        let content = text == nil ?  [contentUri!] :  [contentUri!, text!];
        let activityViewController = UIActivityViewController(activityItems: content, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = controller.view
        activityViewController.completionWithItemsHandler = {(activityType, completed: Bool, returnedItems: [Any]?, error: Error?) in
            self.doneSharingHandler(activityType: activityType, completed: completed, returnedItems: returnedItems, error: error)
        }
        
        let shareType = argsMap.value(forKey: "shareType") as? String

        if(shareType == "instagram"){

            interaction = UIDocumentInteractionController.init(url: contentUri!)
            interaction.delegate = self
            interaction.uti = "com.instagram.exlusivegram"
            interaction.annotation = ["InstagramCaption": text]
            interaction.presentOpenInMenu(from: CGRect.zero, in: controller.view, animated: true)

        }else if(shareType == "facebook"){

            let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook)!
            if(text != nil){
                vc.title = shareType
            }
            vc.add(UIImage(data: imageData)!)

           // presentViewController(vc, animated: true, completion: nil)
    
            controller.show(vc, sender: self)
          //  vc.present(activityViewController, animated: true)
            
            
        }else if(shareType == "twitter"){
            let vc = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            
            if(text != nil){
                vc?.title = shareType
            }
            vc?.add(UIImage(data: imageData)!)
            controller.show(vc!, sender: self)
         }else if(shareType == "whatsapp"){


           //not implemented! 

            interaction = UIDocumentInteractionController.init(url: contentUri!)
            interaction.delegate = self
            interaction.annotation = ["text": text]
            interaction.presentOpenInMenu(from: CGRect.zero, in: controller.view, animated: true)
           
        } else{

           print("share any")
           
           controller.show(activityViewController, sender: self)
        }
    }

    func files(arguments:Any?) -> Void {
        let argsMap = arguments as! NSDictionary
        let names:[String] = argsMap.value(forKey: "names") as! [String]

        var contentUris:[URL] = [];

        // load the files
        for name in names {
            let docsPath:String = NSSearchPathForDirectoriesInDomains(.cachesDirectory,.userDomainMask , true).first!;
            contentUris.append(NSURL(fileURLWithPath: docsPath).appendingPathComponent(name)!);
        }

        // set up activity view controller
        let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: contentUris, applicationActivities: nil)

        // present the view controller
        let controller = UIApplication.shared.keyWindow!.rootViewController as! FlutterViewController
        activityViewController.popoverPresentationController?.sourceView = controller.view
        
        if #available(iOS 13.0, *) {
            activityViewController.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        activityViewController.completionWithItemsHandler = {(activityType, completed: Bool, returnedItems: [Any]?, error: Error?) in
            self.doneSharingHandler(activityType:activityType, completed: completed, returnedItems: returnedItems, error: error)
        }
        controller.show(activityViewController, sender: self)
    }
    
    func doneSharingHandler(activityType: Any?, completed: Bool, returnedItems: [Any]!, error: Error!) {
        //Return if cancelled
        
        
        flutterResult(completed)
        
        print("Shared completed: \(completed)")
        if (!completed) {
            return
        }
       
        //If here, log which activity occurred
        print("Shared success activity: \(String(describing: activityType))")
    }

    private func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.keyWindow!.rootViewController as! FlutterViewController
    }
    private func documentInteractionControllerDidEndPreview(controller: UIDocumentInteractionController) {
        interaction = nil
    }

}
