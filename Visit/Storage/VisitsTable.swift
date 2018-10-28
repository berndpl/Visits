//
//  ProgressTableViewController.swift
//  Memo
//
//  Created by Bernd Plontsch on 04.12.17.
//  Copyright © 2017 Bernd Plontsch. All rights reserved.
//

import UIKit

class VisitsTable:UITableViewController {
    
    var visits:[Visit]! {
        didSet {
            tableView.reloadData()
        }
    }

    @IBAction func didTapDeleteButton(_ sender: Any) {
        Storage.save(state: [Visit]())
        visits = Storage.load()
    }
    
    @IBAction func didTapDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
//        visits = [LocationResult(title: "1", distance: 0.1, isCurrentLocation: false, latitude: 0.0, longitude: 0.0),
//                       LocationResult(title: "2", distance: 0.2, isCurrentLocation: false, latitude: 0.0, longitude: 0.0),
//                       LocationResult(title: "3", distance: 0.3, isCurrentLocation: false, latitude: 0.0, longitude: 0.0),
//                       LocationResult(title: "4", distance: 0.4, isCurrentLocation: true, latitude: 0.0, longitude: 0.0),
//                       LocationResult(title: "5", distance: 0.5, isCurrentLocation: false, latitude: 0.0, longitude: 0.0)]
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visits.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visitCell", for: indexPath) as! VisitTableCell
        cell.visit = visits[indexPath.row]
        cell.configure()
        return cell
    }
    
}

extension Date {
    var short:String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        return dateFormatter.string(from: self)
    }

    var shortRelativeWithTime:String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        return dateFormatter.string(from: self)
    }

    var shortRelative:String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        
        return dateFormatter.string(from: self)
    }
}
