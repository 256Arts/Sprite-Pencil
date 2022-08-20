//
//  Document.swift
//  Pixel Canvas
//
//  Created by Jayden Irwin on 2018-09-29.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    var fileData: Data!
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return fileData as Any
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        if let fileContents = contents as? Data {
            fileData = fileContents
        }
    }
    
}

