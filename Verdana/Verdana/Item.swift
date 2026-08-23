//
//  Item.swift
//  Verdana
//
//  Created by Ivanna Torres Mora on 22/08/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
