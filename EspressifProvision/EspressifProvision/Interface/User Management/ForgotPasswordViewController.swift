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

class ForgotPasswordViewController: UIViewController {
    var pool: AWSCognitoIdentityUserPool?
    var user: AWSCognitoIdentityUser?

    @IBOutlet var username: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let newPasswordViewController = segue.destination as? ResetPasswordViewController {
            newPasswordViewController.user = user
        }
    }

    @IBAction func cancelPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - IBActions

    // handle forgot password
    @IBAction func forgotPassword(_ sender: AnyObject) {
        guard let username = self.username.text, !username.isEmpty else {
            let alertController = UIAlertController(title: "Missing UserName",
                                                    message: "Please enter a valid user name.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }

        user = pool?.getUser(self.username.text!)
        user?.forgotPassword().continueWith { [weak self] (task: AWSTask) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async {
                if let error = task.error as NSError? {
                    let alertController = UIAlertController(title: error.userInfo["__type"] as? String,
                                                            message: error.userInfo["message"] as? String,
                                                            preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    alertController.addAction(okAction)

                    self?.present(alertController, animated: true, completion: nil)
                } else {
                    strongSelf.performSegue(withIdentifier: "confirmForgotPasswordSegue", sender: sender)
                }
            }
            return nil
        }
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        username.resignFirstResponder()
        forgotPassword(textField)
        return true
    }
}
