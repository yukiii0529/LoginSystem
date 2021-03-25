//
//  HomeViewController.swift
//  FirebaseLoginApp
//
//  Created by 田中勇輝 on 2020/12/22.
//

import Foundation
import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    var user: User?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoutButton.layer.cornerRadius = 10
        
        if let user = user {
            nameLabel.text = user.name + "さんようこそ"
            emailLabel.text = user.email
            let dateString = dateFormatterForCreatedAt(date: user.createdAt.dateValue())
            dateLabel.text = "作成日：" + dateString
        }
    }
    
    // 日付を変換する
    private func dateFormatterForCreatedAt(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // ログアウトボタン押されたとき
    @IBAction func tappedLogoutButton(_ sender: Any) {
        handleLogout()
    }
    
    // ログイン中かどうか判断
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        confirmLoggedInUser()
    }
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil || user == nil {
            presentToMainViewController()
        }
    }
    
    // ViewControllerに遷移
    private func presentToMainViewController() {
        let storyBoard = UIStoryboard(name: "SignUp", bundle: nil)
        let viewController = storyBoard.instantiateViewController(identifier: "ViewController") as! ViewController
        let navController = UINavigationController(rootViewController: viewController)
        viewController.modalPresentationStyle = .fullScreen

        self.present(navController, animated: true, completion: nil) // 画面遷移
    }
    
    // ログアウト処理
    private func handleLogout(){
        // Cloud Firestore からログアウト
        do {
            try Auth.auth().signOut()
            presentToMainViewController()
        } catch(let err) {
            print("ログアウトに失敗しました")
        }
    }
}
