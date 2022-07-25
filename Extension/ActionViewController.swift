//
//  ActionViewController.swift
//  Extension
//
//  Created by Camilo Hernández Guerrero on 24/07/22.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Scripts", style: .plain, target: self, action: #selector(selectScript))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        let defaults = UserDefaults.standard
        guard let codeKey = defaults.url(forKey: "URL") else { return }
        script.text = defaults.string(forKey: codeKey.path)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier) {
                    [weak self] (dictionary, error) in
                    guard let itemDictionary = dictionary as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    
                    self?.pageURL = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    let URL = URL(string: self!.pageURL)!
                    UserDefaults.standard.set(URL, forKey: self!.pageURL)
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
    }

    @IBAction func done() {
        let defaults = UserDefaults.standard
        guard let URLKey = defaults.url(forKey: pageURL) else { return }
        defaults.set(script.text, forKey: URLKey.path)
                
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text!]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: UTType.propertyList.identifier)
        
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
    }
    
    @objc func selectScript() {
        let alertController = UIAlertController(title: "Select a script", message: nil, preferredStyle: .actionSheet)
        
        let showTitle = UIAlertAction(title: "Show webpage title", style: .default) { [weak self] _ in
            self?.insertScript(attribute: "title")
        }
        
        let showURL = UIAlertAction(title: "Show webpage URL", style: .default) {
            [weak self] _ in
            self?.insertScript(attribute: "URL")
        }
        
        alertController.addAction(showTitle)
        alertController.addAction(showURL)
        
        present(alertController, animated: true)
    }
    
    func insertScript(attribute: String) {
        let prewrittenScript = "alert(document.\(attribute));"
        
        if script.text == "" {
            script.text = prewrittenScript
        } else {
            script.text += "\n\(prewrittenScript)"
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, to: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        script.scrollIndicatorInsets = script.contentInset
        script.scrollRangeToVisible(script.selectedRange)
    }
}
