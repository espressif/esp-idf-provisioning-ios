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

    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!

    @IBOutlet var phone: UITextField!
    @IBOutlet var email: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        username.setBottomBorder()
        password.setBottomBorder()
        phone.setBottomBorder()
        email.setBottomBorder()
        username.layer.borderColor = UIColor.lightGray.cgColor
        username.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        password.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        phone.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        email.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let signUpConfirmationViewController = segue.destination as? ConfirmSignUpViewController {
            signUpConfirmationViewController.sentTo = sentTo
            signUpConfirmationViewController.user = pool?.getUser(username.text!)
        }
    }

    @IBAction func signUp(_ sender: AnyObject) {
        guard let userNameValue = self.username.text, !userNameValue.isEmpty,
            let passwordValue = self.password.text, !passwordValue.isEmpty else {
            let alertController = UIAlertController(title: "Missing Required Fields",
                                                    message: "Username / Password are required for registration.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }

        var attributes = [AWSCognitoIdentityUserAttributeType]()

        if let phoneValue = self.phone.text, !phoneValue.isEmpty {
            let phone = AWSCognitoIdentityUserAttributeType()
            phone?.name = "phone_number"
            phone?.value = phoneValue
            attributes.append(phone!)
        }

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
