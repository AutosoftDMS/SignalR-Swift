//
//  ViewController.swift
//  SignalR-Swift-Example
//
//  Created by Jordan Camara on 1/12/17.
//  Copyright © 2017 Jordan Camara. All rights reserved.
//

import UIKit
import SignalRSwift

class ViewController: UIViewController {

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var startButton: UIBarButtonItem!

    var chatHub: HubProxy!
    var connection: HubConnection!
    var name: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        connection = HubConnection(withUrl: "http://swiftr.azurewebsites.net") //SignalR("http://swiftr.azurewebsites.net")
        //        connection.signalRVersion = .v2_2_0

        chatHub = HubProxy(connection: self.connection, hubName: "chatHub") //Hub("chatHub")
        _ = chatHub.on(eventName: "broadcastMessage") { (args) in
            if let name = args[0] as? String, let message = args[1] as? String, let text = self.chatTextView.text {
                self.chatTextView.text = "\(text)\n\n\(name): \(message)"
            }
        }

        //        connection.addHub(chatHub)

        // SignalR events

        connection.started = { [unowned self] in
            self.statusLabel.text = "Started..."
        }

        connection.reconnecting = { [unowned self] in
            self.statusLabel.text = "Reconnection..."
        }

        connection.reconnected = { [unowned self] in
            self.statusLabel.text = "Reconnected"
            self.startButton.isEnabled = true
            self.startButton.title = "Stop"
            self.sendButton.isEnabled = true
        }

        connection.closed = { [unowned self] in
            self.statusLabel.text = "Disconnected"
            self.startButton.isEnabled = true
            self.startButton.title = "Start"
            self.sendButton.isEnabled = false
        }

        connection.connectionSlow = { print("Connection slow...") }

        connection.error = { [unowned self] error in
            let anError = error as NSError
            if anError.code == NSURLErrorTimedOut {
                self.connection.start()
            }
        }

        connection.start()
    }

    override func viewDidAppear(_ animated: Bool) {
        let alertController = UIAlertController(title: "Name", message: "Please enter your name", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.name = alertController.textFields?.first?.text

            if let name = self?.name , name.isEmpty {
                self?.name = "Anonymous"
            }

            alertController.textFields?.first?.resignFirstResponder()
        }

        alertController.addTextField { textField in
            textField.placeholder = "Your Name"
        }

        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func send(_ sender: AnyObject?) {
        if let hub = chatHub, let message = messageTextField.text {
            hub.invoke(method: "send", withArgs: [name, message])
        }
        messageTextField.resignFirstResponder()
    }

    @IBAction func startStop(_ sender: AnyObject?) {
        if startButton.title == "Start" {
            connection.start()
        } else {
            connection.stop()
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
