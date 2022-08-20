//
//  AppNotificationView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-05-08.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit

class AppNotificationView: UIView {
    
    static let shadowRadius: CGFloat = 40.0
    
    var offScreenConstraint: NSLayoutConstraint?
    var onScreenConstraint: NSLayoutConstraint?
    
    let titleLabel = UILabel()
    let colorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        
        let blurView = UIVisualEffectView()
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.effect = UIBlurEffect(style: .systemMaterial)
        blurView.layer.masksToBounds = true
        blurView.layer.cornerRadius = frame.height / 2.0
        addSubview(blurView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        blurView.contentView.addSubview(titleLabel)
        
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.cornerRadius = (frame.height - 16.0) / 2.0
        colorView.layer.borderWidth = 0.5
        colorView.layer.borderColor = UIColor.systemGray5.cgColor
        blurView.contentView.addSubview(colorView)
        
        let parallax: UIMotionEffectGroup = {
            let amount = 5
            let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            horizontal.minimumRelativeValue = -amount
            horizontal.maximumRelativeValue = amount
            let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            vertical.minimumRelativeValue = -amount
            vertical.maximumRelativeValue = amount
            let parallax = UIMotionEffectGroup()
            parallax.motionEffects = [horizontal, vertical]
            return parallax
        }()
        addMotionEffect(parallax)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leftAnchor.constraint(equalTo: leftAnchor),
            blurView.rightAnchor.constraint(equalTo: rightAnchor),
            
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            
            colorView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            colorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            colorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            colorView.widthAnchor.constraint(equalTo: colorView.heightAnchor)
        ])
        
        // Dismiss gesture
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(dismissNotification))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
        isUserInteractionEnabled = true
    }
    
    convenience init(request: AppNotificationRequest) {
        let size = CGSize(width: 170, height: 60)
        self.init(frame: CGRect(origin: .zero, size: size))
        layer.cornerRadius = size.height / 2.0
        layer.shadowRadius = 40.0
        
        titleLabel.text = request.title
        if let color = request.color {
            colorView.backgroundColor = color
        } else {
            colorView.removeFromSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func dismissNotification(_ sender: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
            self.offScreenConstraint?.isActive = true
            self.onScreenConstraint?.isActive = false
            self.superview?.layoutIfNeeded()
        }, completion: { (done) in
            self.removeFromSuperview()
        })
    }
    
}
