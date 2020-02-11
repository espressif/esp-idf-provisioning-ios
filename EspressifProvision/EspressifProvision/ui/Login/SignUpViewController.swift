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

class SignUpViewController: UIViewController {
    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?

    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var password: UITextField!
    @IBOutlet var confirmPassword: UITextField!

    @IBOutlet var email: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        password.setBottomBorder()
        confirmPassword.setBottomBorder()
        email.setBottomBorder()
        confirmPassword.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        password.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        email.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        email.text = ""
        confirmPassword.text = ""
        password.text = ""
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmSignUpViewController {
            signUpConfirmationViewController.sentTo = sentTo
            signUpConfirmationViewController.user = pool?.getUser(email.text!)
        }
    }

    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)

        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets

        var aRect: CGRect = view.frame
        aRect.size.height -= keyboardSize!.height
        if let activeField = self.signUpButton {
            if !aRect.contains(activeField.frame.origin) {
                scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
        scrollView.isScrollEnabled = false
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        var info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -keyboardSize!.height, right: 0.0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        view.endEditing(true)
        scrollView.isScrollEnabled = false
    }

    @IBAction func signUp(_ sender: AnyObject) {
        dismissKeyboard()
        guard let userNameValue = self.email.text, !userNameValue.isEmpty,
            let passwordValue = self.password.text, !passwordValue.isEmpty else {
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

//        if let phoneValue = self.phone.text, !phoneValue.isEmpty {
//            let phone = AWSCognitoIdentityUserAttributeType()
//            phone?.name = "phone_number"
//            phone?.value = phoneValue
//            attributes.append(phone!)
//        }

        if let emailValue = self.email.text, !emailValue.isEmpty {
            let email = AWSCognitoIdentityUserAttributeType()
            email?.name = "email"
            email?.value = emailValue
            attributes.append(email!)
        }

        // sign up the user
        pool?.signUp(userNameValue, password: passwordValue, userAttributes: attributes, validationData: nil).continueWith { [weak self] (task) -> Any? in
            guard let strongSelf = self else { return nil }
            Utility.hideLoader(view: strongSelf.view)
            DispatchQueue.main.async {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let retryAction = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    alertController.addAction(retryAction)

                    self?.present(alertController, animated: true, completion: nil)
                } else if let result = task.result {
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
