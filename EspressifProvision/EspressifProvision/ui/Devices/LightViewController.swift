//
//  LightViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 12/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class LightViewController: UIViewController {
    var device: Device?
    var brightnessCell: SliderTableViewCell?
    var filter: CIFilter?
    var filteredImage: CIImage?
    let context = CIContext(options: nil)

    @IBOutlet var tableView: UITableView!
    @IBOutlet var lightImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        lightImageView.image = UIImage(named: "light_bulb")
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
    @objc func setBrightness(_ sender: UISlider) {
        brightnessCell?.sliderValue.text = "Brightness: \(Int(sender.value))"
        lightImageView.alpha = CGFloat(sender.value / 100) + 0.1
    }
}

extension LightViewController: UITableViewDelegate {}

extension LightViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
        cell.sliderValue.text = "Brightness: \(cell.slider.value)"
        cell.slider.addTarget(self, action: #selector(setBrightness(_:)), for: .valueChanged)
        brightnessCell = cell
        return cell
    }
}
