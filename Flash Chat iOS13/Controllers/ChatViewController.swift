//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    var messages : [Message] = []
    var listener : ListenerRegistration? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        let messageCellNib = UINib(nibName: K.cellNibName, bundle: nil)
        tableView.register(messageCellNib, forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages(){
        let collection = db.collection(K.FStore.collectionName).order(by: K.FStore.dateField)
        listener = collection.addSnapshotListener { (querySnapshot, error) in
            self.messages = []
            if let e = error{
                print("There was a problem fetching data from firestore, error: \(e)")
            }
            if let snapshotDocuments = querySnapshot?.documents{
                for doc in snapshotDocuments{
                    let messageData = doc.data()
                    if let messageSender = messageData[K.FStore.senderField] as? String,
                       let messageBody = messageData[K.FStore.bodyField] as? String{
                        let message = Message(sender: messageSender, body: messageBody)
                        self.messages.append(message)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text,
           let messageSender = Auth.auth().currentUser?.email {
            let messageData =
            [K.FStore.senderField: messageSender,
             K.FStore.bodyField: messageBody,
             K.FStore.dateField: String(Date().timeIntervalSince1970)]
            db.collection(K.FStore.collectionName)
                .addDocument(data: messageData) { error in
                    if let e = error{
                        print("There was a problem saving data to firestore, error: \(e)")
                        return
                    }
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
        }
    }
    
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        listener?.remove()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

extension ChatViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let messageSender = message.sender
        let currentUser = Auth.auth().currentUser?.email
        let isMessageFromCurrentUser = currentUser == messageSender
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.lable.text = message.body
        
        cell.rightImageView.isHidden = isMessageFromCurrentUser
        cell.leftImageView.isHidden = !isMessageFromCurrentUser
        if isMessageFromCurrentUser{
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.lable.textColor = UIColor(named: K.BrandColors.purple)
        }
        else{
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.lable.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        return cell
    }
}
