//
//  AppNotification.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-05-07.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit

extension UIWindow {
    
    func showAppNotification(_ request: AppNotificationRequest) {
        let appNotificationView = AppNotificationView(request: request)
        appNotificationView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appNotificationView)
        
        appNotificationView.offScreenConstraint = appNotificationView.bottomAnchor.constraint(equalTo: topAnchor, constant: -AppNotificationView.shadowRadius)
        appNotificationView.onScreenConstraint = appNotificationView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            appNotificationView.offScreenConstraint!,
            appNotificationView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0),
            appNotificationView.widthAnchor.constraint(equalToConstant: appNotificationView.frame.size.width),
            appNotificationView.heightAnchor.constraint(equalToConstant: appNotificationView.frame.size.height)
        ])
        
        appNotificationView.superview?.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction], animations: {
            appNotificationView.offScreenConstraint?.isActive = false
            appNotificationView.onScreenConstraint?.isActive = true
            appNotificationView.superview?.layoutIfNeeded()
        }, completion: { (done) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25, execute: { // Not using delay since it cancels swipes
                guard appNotificationView.superview != nil else { return }
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction], animations: {
                    appNotificationView.offScreenConstraint?.isActive = true
                    appNotificationView.onScreenConstraint?.isActive = false
                    appNotificationView.superview?.layoutIfNeeded()
                }, completion: { (done) in
                    appNotificationView.removeFromSuperview()
                })
            })
            
        })
    }
    
}
