//
//  ViewController.swift
//  FirebaseLoginApp
//
//  Created by 田中勇輝 on 2020/12/20.
//

import UIKit
import Firebase
import PKHUD

class ViewController: UIViewController{

    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
    }
    
    /**
        View関連
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // ナビゲーションバーを隠す
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setupViews() {
        // ボタンの色変える
        registerButton.layer.cornerRadius = 10
        
        // 初めはボタンを押せなくする
        registerButton.isEnabled = false
        registerButton.backgroundColor = UIColor.rgb(red: 255, green: 221, blue: 187)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
        
        // キーボードが表示された時に通知がいく
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        // キーボードの表示が終了した時に通知がいく
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    /**
        登録関連
     */
    // 登録ボタンが押されたときの処理
    @IBAction func tappedRegisterButton(_ sender: Any) {
        handleAuthToFirebase()
    }
    
    // 認証情報の保存（登録）
    private func handleAuthToFirebase(){
        HUD.show(.progress, onView: view)
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let name = usernameTextField.text else { return }
    
        // 会員登録を行う
        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in
            // 会員登録に失敗した場合
            if let err = err {
                print("認証情報の保存に失敗しました。\(err)")
                // 失敗マーク
                HUD.hide { (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
        }
        self.addUserInfoTpFirestore(email: email, name: name)
        
    }
    // 登録後の会員情報（登録情報）の取得
    private func addUserInfoTpFirestore(email: String, name: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let docData = ["email": email, "name": name, "createdAt": Timestamp()] as [String : Any]
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        // Cloud Firestoreに登録時に登録する
        userRef.setData(docData) { (err) in
            // Cloud Firestoreへの登録が失敗した場合
            if let err = err {
                print("Firestoreへの保存に失敗しました。\(err)")
                // 失敗マーク
                HUD.hide { (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            
            print("Firestoreへの保存に成功しました。")
            
            // Cloud Firestoreへの登録が成功した場合
            userRef.getDocument { (snapshot, err) in
                if let err = err {
                    // 失敗マーク
                    print("ユーザー情報の取得に失敗しました。\(err)")
                    HUD.hide { (_) in
                        HUD.flash(.error, delay: 1)
                    }
                }
                
                // 登録した情報の取得
                guard let data = snapshot?.data() else { return }
                let user = User.init(dic: data) // モデルに値してモデルから取得
                print("ユーザー情報の取得ができました。\(user.name)")
                // 成功マーク
                HUD.hide { (_) in
                    //HUD.flash(.success, delay: 1)
                    HUD.flash(.success, onView: self.view, delay: 1) { (_) in
                        self.presentToHomeViewController(user: user)
                    }
                }
                
            }
        }
    }
    // 登録後画面に遷移
    private func presentToHomeViewController(user: User) {
        let storyBoard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = storyBoard.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
        homeViewController.user = user // 値を持っていく
        homeViewController.modalPresentationStyle = .fullScreen
        self.present(homeViewController, animated: true, completion: nil) // 画面遷移
    }
    
    // ログイン画面へ遷移
    @IBAction func tappedAlreadyHaveAccountButton(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyBoard.instantiateViewController(identifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    /**
        キーボード関連
     */
    // キーボードが表示されたときの処理
    @objc func showKeyboard(notification: Notification){
        // キーボードの位置を取得
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        // キーボードの上の位置を取得
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        // 登録ボタンの一番下の位置取得
        let registerButtonMaxY = registerButton.frame.maxY
        
        // どのくらいの差があるか取得
        let distance = registerButtonMaxY - keyboardMinY + 20
        
        // 動きをつける
        let transform = CGAffineTransform(translationX: 0, y: -distance)
        // アニメーション
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: { self.view.transform = transform
        })
    }
    // キーボードの表示が終了したときの処理
    @objc func hideKeyboard(){
        // アニメーション（元の位置に戻る）
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: { self.view.transform = .identity
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}


extension ViewController: UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // それぞれのテキストフィールドが空かどうか判断する（空ならTrueを返す）
        // ?? はテキストフィールドがnullなら自動的にtrueを返す
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? true
        
        // テキストフィールドが空ならボタンを押せなくする
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty{
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 221, blue: 187)
        }else{
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 255, green: 141, blue: 0)
        }
    }
    
    
}

