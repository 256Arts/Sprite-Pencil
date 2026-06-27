//
//  MessagesViewController.swift
//  messages
//
//  Created by 256 Arts Developer on 2018-10-15.
//  Copyright © 2018 256 Arts Developer. All rights reserved.
//

import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = UIHostingController(
            rootView: MessagesView(insertFile: { fileURL in
                do {
                    let sticker = try MSSticker(contentsOfFileURL: fileURL, localizedDescription: "Custom Sprite")
                    self.activeConversation?.insert(sticker) { (error) in
                        if let error = error {
                            print(error)
                        } else {
                            self.requestPresentationStyle(.compact)
                        }
                    }
                } catch {
                    print(error)
                }
            })
        )
        vc.view.tintColor = UIColor(named: "AccentColor")
        
        // Add the hosting controller as a child view controller
        addChild(vc)
        view.addSubview(vc.view)
        
        // Set up constraints to fill the entire view
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: view.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Notify the child view controller it has been moved to the parent
        vc.didMove(toParent: self)
    }

}
