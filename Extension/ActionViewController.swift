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
    var scriptName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let prewrittenScriptsButton = UIBarButtonItem(title: "Sample scripts", style: .plain, target: self, action: #selector(selectScript))
        let userScriptsButton = UIBarButtonItem(title: "Your scripts", style: .plain, target: self, action: #selector(showUserScripts))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbarItems = [prewrittenScriptsButton, spacer, userScriptsButton]
        navigationController?.isToolbarHidden = false
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier) {
                    [weak self] (dictionary, error) in
                    let defaults = UserDefaults.standard
                    guard let itemDictionary = dictionary as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        if let scriptName = self?.scriptName {
                            self?.title = scriptName
                            self?.script.text = defaults.string(forKey: scriptName)
                        } else {
                            guard let codeKey = defaults.url(forKey: self!.pageURL) else { return }
                            self?.script.text = defaults.string(forKey: codeKey.host!)
                            self?.title = self?.pageTitle
                        }
                    }
                }
            }
        }
        
        if scriptName == nil {
            let alertController = UIAlertController(title: "New script", message: "Do you want to name your script?", preferredStyle: .alert)
            alertController.addTextField()
            alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: {
                [weak self, weak alertController] _ in
                guard let scriptName = alertController?.textFields?[0].text else { return }
                
                ScriptViewController.userScripts.append(scriptName)
                UserDefaults.standard.set(ScriptViewController.userScripts, forKey: "userScripts")
                
                self?.scriptName = scriptName
                
                DispatchQueue.main.async {
                    self?.title = self?.scriptName
                }
            }))
            
            alertController.addAction(UIAlertAction(title: "No", style: .cancel))
            present(alertController, animated: true)
        }
    }

    @IBAction func done() {
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text!]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: UTType.propertyList.identifier)
        
        item.attachments = [customJavaScript]
        extensionContext?.completeRequest(returningItems: [item])
        
        if let scriptName = scriptName {
            saveScript(using: scriptName, wasNamed: true)
        } else {
            saveScript(using: pageURL, wasNamed: false)
        }
    }
    
    func saveScript(using key: String, wasNamed: Bool) {
        let defaults = UserDefaults.standard
        
        if wasNamed {
            defaults.set(script.text, forKey: key)
        } else {
            guard let URLKey = defaults.url(forKey: key) else { return }
            defaults.set(script.text, forKey: URLKey.host!)
        }
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
    
    @objc func showUserScripts(){
        if let scriptViewController = storyboard?.instantiateViewController(withIdentifier: "ScriptViewController") as? ScriptViewController {
            navigationController?.pushViewController(scriptViewController, animated: true)
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
