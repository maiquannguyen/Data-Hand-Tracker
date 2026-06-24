//
//  HomeTabBarController.swift
//  HandsTracker
//
//  Created by Nguyễn Mai Quân on 23/6/26.
//

import UIKit

final class HomeTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        styleTabBar()
    }

    private func setupTabs() {
        let captureVC = GoCaptureViewController()
        captureVC.tabBarItem = UITabBarItem(
            title: "Go Capture",
            image: UIImage(systemName: "hand.raised.fill"),
            selectedImage: UIImage(systemName: "hand.raised.fill")
        )

        let listVC = ListVideosViewController()
        listVC.tabBarItem = UITabBarItem(
            title: "List Videos",
            image: UIImage(systemName: "video.fill"),
            selectedImage: UIImage(systemName: "video.fill")
        )

        let accountVC = AccountViewController()
        accountVC.tabBarItem = UITabBarItem(
            title: "Account",
            image: UIImage(systemName: "person.circle.fill"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )

        viewControllers = [
            UINavigationController(rootViewController: captureVC),
            UINavigationController(rootViewController: listVC),
            UINavigationController(rootViewController: accountVC)
        ]
        selectedIndex = 0
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.background

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = AppColors.primary
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: AppColors.primary,
            .font: AppFonts.caption(10)
        ]
        itemAppearance.normal.iconColor = AppColors.textSecondary
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: AppColors.textSecondary,
            .font: AppFonts.caption(10)
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = AppColors.primary
    }
}
