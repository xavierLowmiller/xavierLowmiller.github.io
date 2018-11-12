//
//  ViewController.swift
//  BuildtimesConfigurationDemo
//
//  Created by Xaver Lohmüller on 18.11.18.
//  Copyright © 2018 Xaver Lohmüller. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(Configuration.backendUrl)
        print(Configuration.analyticsKey)
        print(Configuration.redesignedLoginEnabled)
    }
}

