//
// Copyright 2014-2018 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License").
// You may not use this file except in compliance with the
// License. A copy of the License is located at
//
//     http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, express or implied. See the License
// for the specific language governing permissions and
// limitations under the License.
//

import Alamofire
import AuthenticationServices
import AWSCognitoIdentityProvider
import AWSMobileClient
import Foundation
import JWTDecode
import SafariServices

class SignInViewController: UIViewController, AWSCognitoAuthDelegate {
    @IBOutlet var checkBox: UIButton!
    @IBOutlet var signInTopSpace: NSLayoutConstraint!
    @IBOutlet var signUpTopView: NSLayoutConstraint!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var topView: UIView!
    @IBOutlet var signUpView: UIView!
    @IBOutlet var signInView: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!
    @IBOutlet var githubLoginButton: UIButton!
    @IBOutlet var googleLoginButton: UIButton!
    @IBOutlet var appleLoginButton: UIButton!
    //    let passwordButtonRightView = UIButton(frame: CGRect(x: 0, y: 0, width: 22.0, height: 16.0))

    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?
    var user: AWSCognitoIdentityUser?

    @IBOutlet var registerPassword: UITextField!
    @IBOutlet var confirmPassword: UITextField!
    @IBOutlet var email: UITextField!

    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?
    var auth: AWSCognitoAuth = AWSCognitoAuth.default()
    var session: SFAuthenticationSession!
    var checked = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: animated)
        segmentControl.selectedSegmentIndex = 0
        changeSegment()
        password.text = ""
        username.text = ""
        registerPassword.text = ""
        confirmPassword.text = ""
        email.text = ""
        checked = false
        checkBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)

        githubLoginButton.layer.backgroundColor = UIColor.white.cgColor
        githubLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        githubLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        githubLoginButton.layer.shadowRadius = 0.5
        githubLoginButton.layer.shadowOpacity = 0.5
        githubLoginButton.layer.masksToBounds = false

        googleLoginButton.layer.backgroundColor = UIColor.white.cgColor
        googleLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        googleLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        googleLoginButton.layer.shadowRadius = 0.5
        googleLoginButton.layer.shadowOpacity = 0.5
        googleLoginButton.layer.masksToBounds = false

//        appleLoginButton.layer.backgroundColor = UIColor.lightGray.cgColor
        appleLoginButton.layer.shadowColor = UIColor.lightGray.cgColor
        appleLoginButton.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        appleLoginButton.layer.shadowRadius = 0.5
        appleLoginButton.layer.shadowOpacity = 0.5
        appleLoginButton.layer.masksToBounds = false

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        var currentBGColor: UIColor!
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            currentBGColor = UIColor(hexString: "#5330b9")
        }
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any], for: .normal)
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: currentBGColor as Any], for: .selected)
        segmentControl.changeUnderlineColor(color: currentBGColor)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if User.shared.automaticLogin {
            User.shared.automaticLogin = false
            password.text = User.shared.password
            username.text = User.shared.username
            signIn(username: User.shared.username, password: User.shared.password)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        // Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        } else {
            // Fallback on earlier versions
        }
        segmentControl.addUnderlineForSelectedSegment()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmSignUpViewController {
            signUpConfirmationViewController.sentTo = sentTo
            signUpConfirmationViewController.user = pool?.getUser(email.text!)
        }
    }

    @IBAction func segmentChange(sender _: UISegmentedControl) {
        changeSegment()
    }

    @IBAction func clickOnAgree(_: Any) {
        checked = !checked
        if checked {
            checkBox.setImage(UIImage(named: "checkbox_checked"), for: .normal)
        } else {
            checkBox.setImage(UIImage(named: "checkbox_unchecked"), for: .normal)
        }
    }

    func changeSegment() {
        if segmentControl.selectedSegmentIndex == 1 {
            UIView.animate(withDuration: 0.5) {
                self.signInView.isHidden = true
                self.signUpView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.signInView.isHidden = false
                self.signUpView.isHidden = true
            }
        }
        segmentControl.changeUnderlinePosition()
    }

    @IBAction func loginWithGoogle(_: Any) {
        loginWith(idProvider: "Google")
    }

    @IBAction func loginWithApple(_: Any) {
        loginWith(idProvider: "SignInWithApple")
    }

    @IBAction func loginWithGithub(_: Any) {
        loginWith(idProvider: "Github")
    }

    func loginWith(idProvider: String) {
        let currentKeys = Keys.current
        let githubLoginURL = Constants.githubURL + "authorize" + "?identity_provider=" + idProvider + "&redirect_uri=" + Constants.redirectURL + "&response_type=CODE&client_id="
        session = SFAuthenticationSession(url: URL(string: githubLoginURL + currentKeys.clientID!)!, callbackURLScheme: Constants.redirectURL) { url, error in
            if error != nil {
                self.showAlert()
                return
            }
            let dict = [String: String]()
            if let responseURL = url?.absoluteString {
                print(responseURL)
                let components = responseURL.components(separatedBy: "#")
                for item in components {
                    if item.contains("code") {
                        let tokens = item.components(separatedBy: "&")
                        for token in tokens {
                            if token.contains("code") {
                                let idTokenInfo = token.components(separatedBy: "=")
                                if idTokenInfo.count > 1 {
                                    let code = idTokenInfo[1]
                                    self.requestToken(code: code)
                                    // self.dismiss(animated: true, completion: nil)
                                    return
                                }
                            }
                        }
                    }
                }
            }
            self.showAlert()
        }
        session.start()
    }

    func requestToken(code: String) {
        let url = Constants.githubURL + "token"
        let currentKeys = Keys.current
        let parameters = ["grant_type": "authorization_code", "client_id": currentKeys.clientID!, "code": code, "redirect_uri": Constants.redirectURL]
        let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        NetworkManager.shared.genericRequest(url: url, method: .post, parameters: parameters, encoding: URLEncoding.default,
                                             headers: headers) { response in
            if let json = response {
                if let idToken = json["id_token"] as? String, let refreshToken = json["refresh_token"] as? String, let accessToken = json["access_token"] as? String {
                    self.getUserInfo(token: idToken, provider: .other)
                    let refreshTokenInfo = ["token": refreshToken, "time": Date(), "expire_in": json["expires_in"] as? Int ?? 3600] as [String: Any]
                    User.shared.accessToken = accessToken
                    UserDefaults.standard.set(refreshTokenInfo, forKey: Constants.refreshTokenKey)
                    UserDefaults.standard.set(accessToken, forKey: Constants.accessTokenKey)
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                print(response)
            }
        }
    }

    func getViewController() -> UIViewController {
        return self
    }

    @IBAction func signInPressed(_: AnyObject) {
        dismissKeyboard()
        if Utility.isConnected(view: view) {
            guard let usernameValue = username.text, !usernameValue.isEmpty, let password = password.text, !password.isEmpty else {
                let alertController = UIAlertController(title: "Missing information",
                                                        message: "Please enter a valid user name and password",
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)
                present(alertController, animated: true, completion: nil)
                return
            }
            signIn(username: usernameValue, password: password)
        }
    }

    func signIn(username: String, password: String) {
        Utility.showLoader(message: "Signing in", view: view)
        let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: username, password: password)
        User.shared.username = username
        UserDefaults.standard.setValue(User.shared.username, forKey: Constants.usernameKey)
        passwordAuthenticationCompletion?.set(result: authDetails)
    }

    func showAlert() {
        let alertController = UIAlertController(title: "Failure",
                                                message: "Failed to login. Please try again.",
                                                preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func signUp(_ sender: AnyObject) {
        dismissKeyboard()
        if Utility.isConnected(view: view) {
            guard let userNameValue = self.email.text, !userNameValue.isEmpty,
                let passwordValue = self.registerPassword.text, !passwordValue.isEmpty else {
                let alertController = UIAlertController(title: "Missing Required Fields",
                                                        message: "Username / Password are required for registration.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)

                present(alertController, animated: true, completion: nil)
                return
            }

            if let confirmPasswordValue = confirmPassword.text, confirmPasswordValue != passwordValue {
                let alertController = UIAlertController(title: "Mismatch",
                                                        message: "Re-entered password do not match.",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)

                present(alertController, animated: true, completion: nil)
                return
            }

            if !checked {
                let alertController = UIAlertController(title: "Error!!",
                                                        message: "Please accept our terms and condition before signing up",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)

                present(alertController, animated: true, completion: nil)
                return
            }
            Utility.showLoader(message: "", view: view)

            var attributes = [AWSCognitoIdentityUserAttributeType]()

            if let emailValue = self.email.text, !emailValue.isEmpty {
                let email = AWSCognitoIdentityUserAttributeType()
                email?.name = "email"
                email?.value = emailValue
                attributes.append(email!)
            }

            // sign up the user
            pool?.signUp(userNameValue, password: passwordValue, userAttributes: attributes, validationData: nil).continueWith { [weak self] (task) -> Any? in
                guard let strongSelf = self else { return nil }
                DispatchQueue.main.async {
                    Utility.hideLoader(view: strongSelf.view)
                    if let error = task.error as NSError? {
                        let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                                message: error.userInfo["message"] as? String,
                                                                preferredStyle: .alert)
                        let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                        alertController.addAction(retryAction)

                        self?.present(alertController, animated: true, completion: nil)
                    } else if let result = task.result {
                        User.shared.username = userNameValue
                        User.shared.password = passwordValue
                        // handle the case where user has to confirm his identity via email / SMS
                        if result.user.confirmedStatus != AWSCognitoIdentityUserStatus.confirmed {
                            strongSelf.sentTo = result.codeDeliveryDetails?.destination
                            strongSelf.performSegue(withIdentifier: "confirmSignUpSegue", sender: sender)
                        } else {
                            _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
                return nil
            }
        }
    }

    @objc func keyboardNotification(notification _: NSNotification) {}

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification _: NSNotification) {
        if signUpView.isHidden {
            UIView.animate(withDuration: 0.45, animations: {
                self.signInTopSpace.constant = -100.0
            })
        } else {
            UIView.animate(withDuration: 0.45, animations: {
                self.signUpTopView.constant = -50.0
            })
        }
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        if signUpView.isHidden {
            UIView.animate(withDuration: 0.45, animations: {
                self.signInTopSpace.constant = 0
            })
        } else {
            UIView.animate(withDuration: 0.45, animations: {
                self.signUpTopView.constant = 0
            })
        }
    }

    @IBAction func openPrivacy(_: Any) {
        showDocumentVC(url: "https://rainmaker.espressif.com/docs/privacy-policy.html")
    }

    @IBAction func openDocumentation(_: Any) {
        showDocumentVC(url: "https://rainmaker.espressif.com")
    }

    @IBAction func openTC(_: Any) {
        showDocumentVC(url: "https://rainmaker.espressif.com/docs/terms-of-use.html")
    }

    func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
    }

    func getUserInfo(token: String, provider: ServiceProvider) {
        do {
            let json = try decode(jwt: token)
            User.shared.userInfo.username = json.body["cognito:username"] as? String ?? ""
            User.shared.userInfo.email = json.body["email"] as? String ?? ""
            User.shared.userInfo.userID = json.body["custom:user_id"] as? String ?? ""
            User.shared.userInfo.loggedInWith = provider
            User.shared.userInfo.saveUserInfo()
        } catch {
            print("error parsing token")
        }
        User.shared.updateDeviceList = true
    }

    func goToConfirmUserScreen() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let confirmUserVC = storyboard.instantiateViewController(withIdentifier: "confirmSignUpVC") as! ConfirmSignUpViewController
        confirmUserVC.confirmExistingUser = true
        confirmUserVC.user = user
        confirmUserVC.sentTo = username.text ?? ""
        navigationController?.pushViewController(confirmUserVC, animated: true)
    }

    func resendConfirmationCode() {
        user = pool?.getUser(username.text ?? "")
        user?.resendConfirmationCode().continueWith { [weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)

                    self?.present(alertController, animated: true, completion: nil)
                } else if task.result != nil {
                    strongSelf.goToConfirmUserScreen()
                }
            }
            return nil
        }
    }
}

extension SignInViewController: AWSCognitoIdentityPasswordAuthentication {
    public func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        passwordAuthenticationCompletion = passwordAuthenticationCompletionSource

        DispatchQueue.main.async {
            if self.usernameText == nil {
                self.usernameText = authenticationInput.lastKnownUsername
            }
        }
    }

    public func didCompleteStepWithError(_ error: Error?) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            if let error = error as NSError? {
                if error.code == 33 {
                    self.resendConfirmationCode()
                    return
                }
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)

                self.present(alertController, animated: true, completion: nil)
            } else {
                self.username.text = nil
                self.password.text = nil
                User.shared.updateUserInfo = true
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension SignInViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.fullScreen
    }
}

extension SignInViewController: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case username:
            password.becomeFirstResponder()
        case password:
            password.resignFirstResponder()
            signInPressed(textField)
        case email:
            registerPassword.becomeFirstResponder()
        case registerPassword:
            confirmPassword.becomeFirstResponder()
        case confirmPassword:
            confirmPassword.resignFirstResponder()
        default:
            return true
        }
        return true
    }
}
