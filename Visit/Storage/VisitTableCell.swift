//
//  ProgressTableCell.swift
//  Memo
//
//  Created by Bernd Plontsch on 04.12.17.
//  Copyright © 2017 Bernd Plontsch. All rights reserved.
//

import UIKit

class VisitTableCell: UITableViewCell {
    
    var visit:Visit!
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var distance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        configure()
    }
    
    func configure() {
        name.text = visit.title
        date.text = visit.date.shortRelativeWithTime
        distance.text = visit.distance.distanceString()
        self.backgroundColor = visit.isCurrentLocation ? UIColor.red.withAlphaComponent(0.2) : UIColor.clear
    }
    
}
