// Copyright 2024 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ThreadSuccessViewController+ScanThread.swift
//  ESPRainMaker
//

import UIKit

@available(iOS 16.4, *)
extension ThreadSuccessViewController {
    
    /// Start updating UI for thread network scanning
    func startUIUpdateForThreadNetworkScanning() {
        DispatchQueue.main.async {
            self.step1Image.isHidden = true
            self.activityIndicator1.isHidden = false
            self.activityIndicator1.startAnimating()
        }
    }
    
    /// Update UI for network scan success
    func updateUIForThreadNetworkScanSuccess() {
        DispatchQueue.main.async {
            self.activityIndicator1.stopAnimating()
            self.activityIndicator1.isHidden = true
            self.step1Image.image = UIImage(named: "checkbox_checked")
            self.step1Image.isHidden = false
        }
    }
    
    /// Update UI for network scan failure
    func updateUIForNetworkScanFailure(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator1.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            self.step1Error.text = message
            self.step1Error.isHidden = false
        }
    }
}

