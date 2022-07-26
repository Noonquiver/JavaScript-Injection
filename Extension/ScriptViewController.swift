//
//  ScriptViewController.swift
//  Extension
//
//  Created by Camilo Hernández Guerrero on 25/07/22.
//

import UIKit

class ScriptViewController: UITableViewController {
    static var userScripts = Array<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Your scripts"
        guard let scripts = UserDefaults.standard.object(forKey: "userScripts") as? [String] else { return }
        ScriptViewController.userScripts = scripts
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ScriptViewController.userScripts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Name", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = ScriptViewController.userScripts[indexPath.row]
        cell.contentConfiguration = configuration
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let actionViewController = storyboard?.instantiateViewController(withIdentifier: "ActionViewController") as? ActionViewController {
            actionViewController.script = UITextView()
            actionViewController.scriptName = ScriptViewController.userScripts[indexPath.row]
            
            navigationController?.pushViewController(actionViewController, animated: true)
        }
    }
}
