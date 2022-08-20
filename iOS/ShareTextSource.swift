//
//  ShareActivityItemSource.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-05-10.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import UIKit
import LinkPresentation

class ShareTextSource: NSObject, UIActivityItemSource {
    
    var image: UIImage?
    var documentURL: URL
    
    init(image: UIImage?, documentURL: URL) {
        self.image = image
        self.documentURL = documentURL
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        NSLocalizedString("Created in Sprite Pencil.", comment: "")
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .postToTwitter {
            return NSLocalizedString("Created in @SpritePencil.", comment: "twitter share text")
        } else {
            return NSLocalizedString("Created in Sprite Pencil.", comment: "")
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        NSLocalizedString("Pixel Art", comment: "email subject")
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = documentURL
        metadata.url = documentURL
        metadata.title = documentURL.deletingPathExtension().lastPathComponent
        if let image = image {
            metadata.imageProvider = NSItemProvider(object: image)
        }
        return metadata
    }
    
}
