//
//  AppSettingsViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 30/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class AppSettingsViewController: UIViewController {
    @IBOutlet var colorPickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var crossButton: UIButton!
    @IBOutlet var colorPicker: ColorPickerView!
    @IBOutlet var colorPickerButton: UIButton!

    var imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        colorPicker.layoutDelegate = self
        // Do any additional setup after loading the view.
    }

    @IBAction func pickColor(_: Any) {
        UIView.animate(withDuration: 3.0) {
            self.colorPickerHeightConstraint.constant = 400
        }
        crossButton.isHidden = false
    }

    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func cancelClicked(_: Any) {
        crossButton.isHidden = true
        UIView.animate(withDuration: 3.0) {
            self.colorPickerHeightConstraint.constant = 0
        }
    }

    @IBAction func pickImage(_: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .savedPhotosAlbum
            present(imagePicker, animated: true, completion: nil)
        }
    }

    @IBAction func removeBackgrundImage(_: Any) {
        AppConstants.shared.appBGImage = nil
        UserDefaults.standard.removeObject(forKey: Constants.appBGKey)
        updateUIViews()
    }

    func updateUIViews() {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.uiViewUpdateNotification)))
        var currentBGColor: UIColor = UIColor(hexString: "#5330b9")
        if let color = AppConstants.shared.appThemeColor {
            PrimaryButton.appearance().backgroundColor = color
            TopBarView.appearance().backgroundColor = color
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                PrimaryButton.appearance().backgroundColor = UIColor(hexString: bgColor)
                TopBarView.appearance().backgroundColor = UIColor(hexString: bgColor)
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            PrimaryButton.appearance().setTitleColor(UIColor(hexString: "#5330b9"), for: .normal)
            BarButton.appearance().setTitleColor(UIColor(hexString: "#5330b9"), for: .normal)
        } else {
            PrimaryButton.appearance().setTitleColor(UIColor.white, for: .normal)
            BarButton.appearance().setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1), for: .normal)
        }
        for subview in view.subviews {
            subview.setNeedsDisplay()
            for item in subview.subviews {
                item.setNeedsDisplay()
            }
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

extension AppSettingsViewController: ColorPickerViewDelegate {
    func colorPickerView(_: ColorPickerView, didSelectItemAt _: IndexPath) {
        if let index = self.colorPicker.indexOfSelectedColor {
            AppConstants.shared.appThemeColor = colorPicker.colors[index]
            UserDefaults.standard.backgroundColor = colorPicker.colors[index]
            updateUIViews()
        } else {
            AppConstants.shared.appThemeColor = nil
            UserDefaults.standard.removeObject(forKey: Constants.appThemeKey)
        }
    }

    func colorPickerView(_: ColorPickerView, didDeselectItemAt _: IndexPath) {
        AppConstants.shared.appThemeColor = nil
        UserDefaults.standard.backgroundColor = nil
        updateUIViews()
    }
}

extension AppSettingsViewController: ColorPickerViewDelegateFlowLayout {
    func colorPickerView(_: ColorPickerView, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 10.0
    }

    func colorPickerView(_: ColorPickerView, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 10.0
    }

    func colorPickerView(_: ColorPickerView, sizeForItemAt _: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width - 90
        return CGSize(width: width / 6.0, height: width / 6.0)
    }
}

extension AppSettingsViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        AppConstants.shared.appBGImage = image
        UserDefaults.standard.setImage(image: image, forKey: Constants.appBGKey)
        updateUIViews()
    }
}

extension AppSettingsViewController: UINavigationControllerDelegate {}
