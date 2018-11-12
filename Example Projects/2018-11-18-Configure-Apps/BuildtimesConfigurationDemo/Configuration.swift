//
//  Configuration.swift
//  BuildtimesConfigurationDemo
//
//  Created by Xaver Lohmüller on 18.11.18.
//  Copyright © 2018 Xaver Lohmüller. All rights reserved.
//

import UIKit

enum Configuration {
    private static let json: NSDictionary = {
        guard let data = NSDataAsset(name: "Config")?.data,
            let json = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary
            else { fatalError("Malformed config.json file") }

        return json
    }()
}

extension Configuration {
    static var backendUrl: URL {
        guard let urlString = json["backendUrl"] as? String,
            let url = URL(string: urlString)
            else { fatalError("Invalid/missing backend URL") }

        return url
    }

    static var analyticsKey: String {
        guard let analyticsKey = json["analyticsKey"] as? String
            else { fatalError("Invalid/missing analytics key") }

        return analyticsKey
    }

    static var redesignedLoginEnabled: Bool {
        guard let redesignedLoginEnabled = json["redesignedLoginEnabled"] as? Bool
            else { fatalError("Invalid/missing feature toggle") }

        return redesignedLoginEnabled
    }
}
