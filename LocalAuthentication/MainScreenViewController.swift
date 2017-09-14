//
//  MainScreenViewController.swift
//  LocalAuthenticationDemo
//
//  Created by Farley Caesar on 2017-09-14.
//  Copyright © 2017 AppObject. All rights reserved.
//

import UIKit

class MainScreenViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func tryAgainPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
