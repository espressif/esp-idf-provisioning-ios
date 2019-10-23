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

import AWSCognitoIdentityProvider
import Foundation

class SignInViewController: UIViewController {
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var topView: UIView!
    @IBOutlet var cognitoImageView: UIImageView!
    @IBOutlet var formView: UIView!
    @IBOutlet var formViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var formViewTopConstraint: NSLayoutConstraint!
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>?
    var usernameText: String?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentationController?.delegate = self
//        presentationController?.delegate = self
        password.text = nil
        username.text = ""
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        username.setBottomBorder()
        password.setBottomBorder()
        username.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        password.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        // Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)

//        topView.layer.masksToBounds = false
        topView.layer.shadowOffset = CGSize(width: 0, height: 2)
        topView.layer.shadowRadius = 0.5
        topView.layer.shadowColor = UIColor.gray.cgColor
        topView.layer.shadowOpacity = 0.5

//        formView.layer.masksToBounds = false
        formView.layer.shadowOffset = CGSize(width: 0, height: 0)
        formView.layer.shadowRadius = 0.5
        formView.layer.shadowColor = UIColor.gray.cgColor
        formView.layer.shadowOpacity = 1.0

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        if #available(iOS 13.0, *) {
            isModalInPresentation = false
        } else {
            // Fallback on earlier versions
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let colors = Colors()
        topView.backgroundColor = UIColor.clear
        let backgroundLayer = colors.gl
        backgroundLayer!.frame = topView.frame
        topView.layer.insertSublayer(backgroundLayer!, at: 0)
    }

    @IBAction func signInPressed(_: AnyObject) {
        dismissKeyboard()
        if username.text != nil, password.text != nil {
            Utility.showLoader(message: "Signing in", view: view)
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: username.text!, password: password.text!)
            User.shared.username = username.text!
            UserDefaults.standard.setValue(User.shared.username, forKey: Constants.usernameKey)
            passwordAuthenticationCompletion?.set(result: authDetails)
        } else {
            let alertController = UIAlertController(title: "Missing information",
                                                    message: "Please enter a valid user name and password",
                                                    preferredStyle: .alert)
            let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
            alertController.addAction(retryAction)
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

    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                formViewBottomConstraint.constant = 150.0
                formViewTopConstraint.constant = -30.0
            } else {
                if let frameHeight = endFrame?.size.height, frameHeight > 100 {
                    formViewBottomConstraint.constant = frameHeight + 25.0
                    formViewTopConstraint.constant = 150.0 - frameHeight - 50.0
                } else {
                    formViewBottomConstraint.constant = 150.0
                    formViewTopConstraint.constant = -30.0
                }
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

extension UITextField {
    func setBottomBorder() {
        borderStyle = .none
        layer.backgroundColor = UIColor.clear.cgColor

        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: frame.height - 1, width: frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor(red: 255.0 / 255.0, green: 97.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0).cgColor
        borderStyle = UITextField.BorderStyle.none
        layer.addSublayer(bottomLine)
    }
}

extension SignInViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.fullScreen
    }
}
