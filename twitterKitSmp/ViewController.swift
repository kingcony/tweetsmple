//
//  ViewController.swift
//  twitterKitSmp
//
//  Created by KingCony on 2019/01/26.
//  Copyright © 2019 KingCony. All rights reserved.
//

import UIKit
import TwitterKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }


  @IBAction func tapTweet(_ sender: Any) {
    sndTweet()
  }
  
  func sndTweet() {
    if TWTRTwitter.sharedInstance().sessionStore.hasLoggedInUsers() {
      sndTweetExec()
    } else {
      TWTRTwitter.sharedInstance().logIn(with: self, completion: { (session, error) in
        if let sess = session {
          print("Signed in as \(sess.userName)")
          self.sndTweetExec()
        } else {
          print("login error: \(error?.localizedDescription)")
        }
      })
    }
  }
  
  func sndTweetExec() {
    let str:String = "サンプルツィート"
    let comp = TWTRComposerViewController.init(initialText: str, image: nil, videoData: nil)
    comp.delegate = self
    present(comp, animated: true, completion: nil)
  }
  
  func tweetAlert(memo:String) {
    let alert:UIAlertController = UIAlertController(title: "TwitterKitサンプル", message: memo, preferredStyle: UIAlertController.Style.alert)
    let defAct:UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    alert.addAction(defAct)
    self.present(alert, animated: true, completion: nil)
  }
}

extension ViewController: TWTRComposerViewControllerDelegate {
  func composerDidCancel(_ controller: TWTRComposerViewController) {
    print("Cancel")
  }
  
  func composerDidFail(_ controller: TWTRComposerViewController, withError error: Error) {
    print("Error")
    let store = TWTRTwitter.sharedInstance().sessionStore
    if let userID = store.session()?.userID {
      store.logOutUserID(userID)
    }
    dismiss(animated: false, completion: nil)
    DispatchQueue.main.async {
      self.tweetAlert(memo:"Twitterに投稿に失敗しました")
    }
  }
  
  func composerDidSucceed(_ controller: TWTRComposerViewController, with tweet: TWTRTweet) {
    print("Ok")
    dismiss(animated: false, completion: nil)
    DispatchQueue.main.async {
      self.tweetAlert(memo: "Twitterに投稿しました。\nご協力ありがとうございます。")
    }
  }

}
