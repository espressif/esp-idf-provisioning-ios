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

import AuthenticationServices
import AWSCognitoIdentityProvider
import AWSMobileClient
import Foundation
import JWTDecode
import SafariServices

class SignInViewController: UIViewController, AWSCognitoAuthDelegate {
    @IBOutlet var signInTopSpace: NSLayoutConstraint!
    @IBOutlet var signUpTopView: NSLayoutConstraint!
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var topView: UIView!
    @IBOutlet var signUpView: UIView!
    @IBOutlet var signInView: UIView!
    @IBOutlet var segmentControl: UISegmentedControl!

    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?

    @IBOutlet var registerPassword: UITextField!
    @IBOutlet var confirmPassword: UITextField!
    @IBOutlet var email: UITextField!

    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?
    var auth: AWSCognitoAuth = AWSCognitoAuth.default()
    var session: SFAuthenticationSession!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentationController?.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: animated)
        segmentControl.selectedSegmentIndex = 0
        changeSegment()
        password.text = nil
        username.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmSignUpViewController {
            signUpConfirmationViewController.sentTo = sentTo
            signUpConfirmationViewController.user = pool?.getUser(email.text!)
        }
    }

    @IBAction func segmentChange(sender _: UISegmentedControl) {
        changeSegment()
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

    @IBAction func loginWithGithub(_: Any) {
        githubLogin()
    }

    @IBAction func signUPWithGithub(_: Any) {
        githubLogin()
    }

    func githubLogin() {
        let githubLoginURL = Constants.githubURL + "?identity_provider=" + Constants.idProvider + "&redirect_uri=" + Constants.redirectURL + "&response_type=TOKEN&client_id="
        session = SFAuthenticationSession(url: URL(string: githubLoginURL + Constants.clientID)!, callbackURLScheme: "com.espressif.rainmaker.intsoftap://") { url, error in
            if error != nil {
                self.showAlert()
                return
            }
            let dict = [String: String]()
            if let responseURL = url?.absoluteString {
                let components = responseURL.components(separatedBy: "#")
                for item in components {
                    if item.contains("id_token") {
                        let tokens = item.components(separatedBy: "&")
                        for token in tokens {
                            if token.contains("id_token") {
                                let idTokenInfo = token.components(separatedBy: "=")
                                if idTokenInfo.count > 1 {
                                    User.shared.idToken = idTokenInfo[1]
                                    do {
                                        let jwt = try decode(jwt: User.shared.idToken!)
                                        if let userid = jwt.body["custom:user_id"] as? String {
                                            User.shared.userID = userid
                                            UserDefaults.standard.set(userid, forKey: Constants.userIDKey)
                                        }
                                        print(jwt)
                                    } catch {
                                        print("error")
                                    }
                                    self.dismiss(animated: true, completion: nil)
                                    return
                                }
                            }
                        }
                    }
                }
            }
            if let idToken = dict["id_token"] {
                User.shared.idToken = idToken
                print("idToken : " + idToken)
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.showAlert()
        }
        session.start()
    }

    func getViewController() -> UIViewController {
        return self
    }

    @IBAction func signInPressed(_: AnyObject) {
        dismissKeyboard()
        if username.text != nil, password.text != nil {
            signIn(username: username.text!, password: password.text!)
        } else {
            let alertController = UIAlertController(title: "Missing information",
                                                    message: "Please enter a valid user name and password",
                                                    preferredStyle: .alert)
            let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
            alertController.addAction(retryAction)
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
                self.signUpTopView.constant = -200.0
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
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)

                self.present(alertController, animated: true, completion: nil)
            } else {
                self.username.text = nil
                User.shared.updateDeviceList = true
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
