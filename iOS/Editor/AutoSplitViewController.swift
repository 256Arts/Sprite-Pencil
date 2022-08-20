//
//  AutoSplitViewController.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-03-07.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import UIKit

class SplitChildViewController: UIViewController {
    var autoSplitViewController: AutoSplitViewController?
    func setupForSplit(_ axis: NSLayoutConstraint.Axis) { }
}

class AutoSplitViewController: UIViewController {
    
    let splitStack = UIStackView()
    var showDetail = UserDefaults.standard.bool(forKey: UserDefaults.Key.showPalette) {
        didSet {
            UIView.animate(withDuration: 0.3) {
                self.detailWidthConstraint?.constant = self.showDetail ? self.standardWidthConstraintConstant : 0
                self.detailHeightConstraint?.constant = self.showDetail ? self.standardHeightConstraintConstant : 0
                self.view.layoutIfNeeded()
            }
        }
    }
    var detailWidthConstraint: NSLayoutConstraint?
    var detailHeightConstraint: NSLayoutConstraint?
    let standardWidthConstraintConstant: CGFloat = 280
    var standardHeightConstraintConstant: CGFloat {
        switch view.bounds.height {
        case ...700: // iPhone 8
            return 176
        case ...750: // iPhone 8 Plus
            return 206
        default:
            return 300
        }
    }
    let border = CALayer()
    
    var leadingViewController: UINavigationController?
    var trailingViewController: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        splitStack.translatesAutoresizingMaskIntoConstraints = false
        splitStack.alignment = .fill
        view.addSubview(splitStack)
        NSLayoutConstraint.activate([
            splitStack.topAnchor.constraint(equalTo: view.topAnchor),
            splitStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splitStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        guard let leadingVC = leadingViewController else { return }
        addChild(leadingVC)
        leadingVC.view.translatesAutoresizingMaskIntoConstraints = false
        (leadingVC.viewControllers.first as? SplitChildViewController)?.autoSplitViewController = self
        splitStack.addArrangedSubview(leadingVC.view!)
        leadingVC.didMove(toParent: self)
        
        guard let trailingVC = trailingViewController else { return }
        addChild(trailingVC)
        (trailingVC.viewControllers.first as? SplitChildViewController)?.autoSplitViewController = self
        trailingVC.view.translatesAutoresizingMaskIntoConstraints = false
        splitStack.addArrangedSubview(trailingVC.view!)
        trailingVC.didMove(toParent: self)
        
        detailWidthConstraint = trailingVC.view.widthAnchor.constraint(equalToConstant: standardWidthConstraintConstant)
        detailHeightConstraint = trailingVC.view.heightAnchor.constraint(equalToConstant: standardHeightConstraintConstant)
        
        let screenScale = view.window?.screen.scale ?? UIScreen.main.scale
        border.frame = CGRect(x: 0, y: 0, width: 1.0/screenScale, height: 9999.0)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupForSize(view.bounds.size)
        border.backgroundColor = UIColor.opaqueSeparator.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupChildrenForSize(view.bounds.size)
    }
    
    func setupForSize(_ size: CGSize) {
        if size.width < size.height {
            splitStack.axis = .vertical
            detailWidthConstraint?.isActive = false
            detailHeightConstraint?.isActive = true
            
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = .systemBackground
            trailingViewController?.navigationBar.standardAppearance = navBarAppearance
            border.removeFromSuperlayer()
        } else {
            splitStack.axis = .horizontal
            detailWidthConstraint?.isActive = true
            detailHeightConstraint?.isActive = false
            
            trailingViewController?.navigationBar.standardAppearance = UINavigationBarAppearance()
            trailingViewController?.view.layer.addSublayer(border)
        }
    }
    
    func setupChildrenForSize(_ size: CGSize) {
        if size.width < size.height {
            (leadingViewController?.viewControllers.first as? SplitChildViewController)?.setupForSplit(.vertical)
            (trailingViewController?.viewControllers.first as? SplitChildViewController)?.setupForSplit(.vertical)
        } else {
            (leadingViewController?.viewControllers.first as? SplitChildViewController)?.setupForSplit(.horizontal)
            (trailingViewController?.viewControllers.first as? SplitChildViewController)?.setupForSplit(.horizontal)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupForSize(size)
        setupChildrenForSize(size)
    }
    
}
