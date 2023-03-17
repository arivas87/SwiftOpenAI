//
//  File.swift
//  
//
//  Created by Arturo Rivas Arias on 17/3/23.
//

import Foundation

extension JSONDecoder {
    public static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension JSONEncoder {
    public static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}




