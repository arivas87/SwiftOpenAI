//
//  File.swift
//  
//
//  Created by Arturo Rivas Arias on 17/3/23.
//

import Foundation
import OSLog

extension Logger {
    private static let name = "SwiftOpenAI"
    
    static let network = Logger(subsystem: name, category: "network")
}
