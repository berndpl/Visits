//
//  RoundedVisualEffectView.swift
//  Visit
//
//  Created by Bernd Plontsch on 27.10.18.
//  Copyright © 2018 Bernd Plontsch. All rights reserved.
//

import UIKit

class RoundedVisualEffectView: UIVisualEffectView {
    
    init(effect: UIVisualEffect, intensity: CGFloat) {
        super.init(effect: nil)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        layer.cornerRadius = self.bounds.height / 2.0
        layer.masksToBounds = true
    }
}
