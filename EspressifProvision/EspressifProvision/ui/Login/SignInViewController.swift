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
        password.text = nil
        username.text = usernameText
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        username.setBottomBorder()
        password.setBottomBorder()
        username.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        password.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        // Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let colors = Colors()
        topView.backgroundColor = UIColor.clear
        let backgroundLayer = colors.gl
        backgroundLayer!.frame = topView.frame
        topView.layer.insertSublayer(backgroundLayer!, at: 0)

        topView.layer.masksToBounds = false
        topView.layer.shadowOffset = CGSize(width: 0, height: 2)
        topView.layer.shadowRadius = 0.5
        topView.layer.shadowColor = UIColor.gray.cgColor
        topView.layer.shadowOpacity = 0.5

        formView.layer.masksToBounds = false
        formView.layer.shadowOffset = CGSize(width: 0, height: 0)
        formView.layer.shadowRadius = 0.5
        formView.layer.shadowColor = UIColor.gray.cgColor
        formView.layer.shadowOpacity = 1.0
    }

    @IBAction func signInPressed(_: AnyObject) {
        if username.text != nil, password.text != nil {
            let authDetails = AWSCognitoIdentityPasswordAuthenticationDetails(username: username.text!, password: password.text!)
            User.shared.username = username.text!
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
            if let error = error as NSError? {
                let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                        message: error.userInfo["message"] as? String,
                                                        preferredStyle: .alert)
                let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                alertController.addAction(retryAction)

                self.present(alertController, animated: true, completion: nil)
            } else {
                self.username.text = nil
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
                    formViewTopConstraint.constant = 150.0 - frameHeight - 25.0
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

class Colors {
    var gl: CAGradientLayer!
    var bg: CAGradientLayer!
    var hvl: CAGradientLayer!

    init() {
        let colorTop = UIColor(red: 243.0 / 255.0, green: 104.0 / 255.0, blue: 101.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 172.0 / 255.0, green: 14.0 / 255.0, blue: 13.0 / 255.0, alpha: 1.0).cgColor

        let bgcolorTop = UIColor(red: 241.0 / 255.0, green: 220.0 / 255.0, blue: 220.0 / 255.0, alpha: 1.0).cgColor
        let bgcolorBottom = UIColor(red: 249.0 / 255.0, green: 156.0 / 255.0, blue: 156.0 / 255.0, alpha: 1.0).cgColor

        let hvcolorTop = UIColor(red: 255.0 / 255.0, green: 201.0 / 255.0, blue: 202.0 / 255.0, alpha: 1.0).cgColor
        let hvcolorBottom = UIColor(red: 255.0 / 255.0, green: 97.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0).cgColor

        hvl = CAGradientLayer()
        hvl.colors = [hvcolorTop, hvcolorBottom]
        hvl.locations = [0.0, 1.0]
        bg = CAGradientLayer()
        bg.colors = [bgcolorTop, bgcolorBottom]
        bg.locations = [0.0, 1.0]
        gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.0, 1.0]
    }
}

extension UITextField {
    func setBottomBorder() {
        borderStyle = .none
        layer.backgroundColor = UIColor.white.cgColor

        layer.masksToBounds = false
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 0.0
    }
}
