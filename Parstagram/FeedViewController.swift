//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Kunwar Sahni on 2/23/20.
//  Copyright © 2020 purdue. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    let commentBar = MessageInputBar()
    
    var posts = [PFObject]()
    var showsCommentBar = false
    var selectedPost: PFObject!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillBeHidden (note: Notification) {
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let comment = PFObject(className: "Comments")
        
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!
        
        selectedPost.add(comment, forKey: "comments")
        
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved")
            }
            else {
                print("Error saving comment: \(String(describing: error))")
            }
        }
        tableView.reloadData()
        
        // clear input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }

    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    /*
    // MARK: - Navigation
    */

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments =  (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.section]
          let comments =  (post["comments"] as? [PFObject]) ?? []
          
          if indexPath.row == 0
          {
              let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell2") as! PostCell2
              let user = post["author"] as! PFUser
              let imageFile = post["image"] as! PFFileObject
              let urlString = imageFile.url!
              let url = URL(string: urlString)!
              
              cell.usernameLabel.text = user.username
              cell.captionLabel.text = post["caption"] as? String
              cell.photoView.af_setImage(withURL: url )
              
              return cell
          }
          else if indexPath.row <= comments.count {
              let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
              
              let comment = comments[indexPath.row - 1]
              cell.commentLabel.text = comment["text"]  as? String
              
              let user = comment["author"] as! PFUser
              cell.nameLabel.text = user.username
              
              return cell
          }
          else {
              let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
              
              return cell
          }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments =  (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1
        {
            showsCommentBar =  true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        
        let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
        
        sceneDelegate.window?.rootViewController = loginViewController
    }
}
