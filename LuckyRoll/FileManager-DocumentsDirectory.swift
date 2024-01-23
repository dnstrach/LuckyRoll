//
//  FileManager-DocumentsDirectory.swift
//  LuckyRoll
//
//  Created by Dominique Strachan on 1/22/24.
//

import Foundation

// for codable
extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
