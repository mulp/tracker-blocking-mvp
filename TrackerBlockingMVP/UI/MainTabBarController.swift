//
//  MainTabBarController.swift
//  TrackerBlockingMVP
//
//  Created by FC on 24/2/25.
//


import UIKit

class MainTabBarController: UITabBarController {
    private var browserVC: BrowserViewController?
    private var allowlistVC: AllowlistViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let allowListManager = AllowlistManager()
        let browserViewController = BrowserViewController.compose(allowListManager: allowListManager)
        
        let browserVC = UINavigationController(rootViewController: browserViewController)
        browserVC.tabBarItem = UITabBarItem(title: "Browser", image: UIImage(systemName: "globe"), tag: 0)

        let allowListViewController = AllowlistViewController(with: allowListManager)
        allowListViewController.delegate = browserViewController
        let allowlistVC = UINavigationController(rootViewController: allowListViewController)
        allowlistVC.tabBarItem = UITabBarItem(title: "Allowlist", image: UIImage(systemName: "checkmark.shield"), tag: 1)

        viewControllers = [browserVC, allowlistVC]
    }
}
