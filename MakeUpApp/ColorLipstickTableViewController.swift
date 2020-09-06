//
//  ColorLipstickTableViewController.swift
//  MakeUpApp
//
//  Created by kashee kushwaha on 01/06/20.
//  Copyright © 2020 kashee kushwaha. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Table View Data Source

let allLipstickSeries: [(brand: String, name: String, lipsticks: [Lipstick])] = {
    struct Wrapper: Decodable {
        let brands: [Lipstick.Brand]
    }
    let url = Bundle.main.url(forResource: "lipstick", withExtension: "json")!
    let all = try! JSONDecoder().decode(Wrapper.self, from: Data(contentsOf: url))
    return all.brands.flatMap { brand in
        brand.series.map { series in
            return (brand: brand.name, name: series.name, lipsticks: series.lipsticks)
        }
    }
}()

class ColorLipstickTableViewController: UITableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return allLipstickSeries.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allLipstickSeries[section].lipsticks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let lipstick = allLipstickSeries[indexPath.section].lipsticks[indexPath.row]
        cell.textLabel!.text = "#\(lipstick.id)" + (lipstick.name.isEmpty ? "" : " \(lipstick.name)")
        cell.textLabel!.textColor = .white
        cell.backgroundColor = lipstick.color
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let series = allLipstickSeries[section]
        return "\(series.brand)\(series.name)"
    }
    
    // MARK: - Styling
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if useFallbackImplementation { return }
        view.layer.cornerRadius = 40
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
    }
    
    // MARK: - Table View Delegate
    
    weak var delegate: LipstickChooserDelegate?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didChooseLipstick(allLipstickSeries[indexPath.section].lipsticks[indexPath.row])
    }
}

protocol LipstickChooserDelegate: AnyObject {
    func didChooseLipstick(_ lipstick: Lipstick)
}
