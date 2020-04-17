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

class ConfirmSignUpViewController: UIViewController {
    var sentTo: String?
    var user: AWSCognitoIdentityUser?
    var confirmExistingUser = false

    @IBOutlet var sentToLabel: UILabel!
    @IBOutlet var code: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        sentToLabel.text = user!.username
        sentToLabel.text = "Code sent to: \(sentTo!)"
        code.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.title = ""
        navigationItem.backBarButtonItem?.tintColor = UIColor(red: 234.0 / 255.0, green: 92.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)
        code.setBottomBorder()
    }

    // MARK: IBActions

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    // handle confirm sign up
    @IBAction func confirm(_: AnyObject) {
        guard let confirmationCodeValue = self.code.text, !confirmationCodeValue.isEmpty else {
            let alertController = UIAlertController(title: "Confirmation code missing.",
                                                    message: "Please enter a valid confirmation code.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }
        Utility.showLoader(message: "", view: view)
        user?.confirmSignUp(code.text!, forceAliasCreation: true).continueWith { [weak self] (task: AWSTask) -> AnyObject? in
            DispatchQueue.main.async {
                if let viewContainer = self?.view {
                    Utility.hideLoader(view: viewContainer)
                }
            }
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)

                    strongSelf.present(alertController, animated: true, completion: nil)
                } else {
                    if strongSelf.confirmExistingUser {
                        strongSelf.confirmExistingUser = false
                        let alertController = UIAlertController(title: "Success",
                                                                message: "User has been confirmed. Please enter your credentials in login page to sign in with this user.",
                                                                preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                            strongSelf.navigationController?.popToRootViewController(animated: true)
                        }

                        alertController.addAction(okAction)

                        strongSelf.present(alertController, animated: true, completion: nil)
                    } else {
                        User.shared.automaticLogin = true
                        _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
            return nil
        }
    }

    // handle code resend action
    @IBAction func resend(_: AnyObject) {
        user?.resendConfirmationCode().continueWith { [weak self] (task: AWSTask) -> AnyObject? in
            guard let _ = self else { return nil }
            DispatchQueue.main.async {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)

                    self?.present(alertController, animated: true, completion: nil)
                } else if let result = task.result {
                    let alertController = UIAlertController(title: "Code Resent",
                                                            message: "Code resent to \(result.codeDeliveryDetails?.destination! ?? " no message")",
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    self?.present(alertController, animated: true, completion: nil)
                }
            }
            return nil
        }
    }
}

extension ConfirmSignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        code.resignFirstResponder()
        confirm(textField)
        return true
    }
}
