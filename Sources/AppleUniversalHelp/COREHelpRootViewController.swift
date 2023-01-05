//
//  COREHelpRootViewController.swift
//
//
//  Created by Steven Troughton-Smith on 02/01/2023.
//

import UIKit
import AppleUniversalCore

extension NSNotification.Name {
	static let toggleTableOfContents = NSNotification.Name("toggleTableOfContents")
	static let viewerDestinationChanged = NSNotification.Name("viewerDestinationChanged")
}

open class COREHelpRootViewController: UIViewController, UINavigationControllerDelegate {
	
	let rootSplitViewController = UISplitViewController(style: .doubleColumn)
	let compactRootNavigationController = UINavigationController()
	
	let compactTOCViewController = COREHelpTableOfContentsViewController()
	let splitTOCViewController = COREHelpTableOfContentsViewController()
	let splitPageViewController = COREHelpPageViewController()
	
	let splitSearchViewController = COREHelpSearchViewController()
	var lastNavigationWasFromSearchPage = false
	
	public var helpBundle:HelpBundle? {
		didSet {
			splitTOCViewController.helpBundle = helpBundle
			compactTOCViewController.helpBundle = helpBundle
			splitSearchViewController.helpBundle = helpBundle
		}
	}
	
	var searchVisible = false {
		didSet {
			if searchVisible == true {
				if splitSearchViewController.presentingViewController == nil {
					splitPageViewController.present(splitSearchViewController, animated: false)
					view.window?.windowScene?.title = NSLocalizedString("SEARCH_RESULTS", comment: "")
				}
			}
			else {
				splitSearchViewController.presentingViewController?.dismiss(animated: false)

			}
		}
	}
	
	var searchString = "" {
		didSet {
			if searchString.isEmpty {
				searchVisible = false
			}
			else {
				searchVisible = true
				splitSearchViewController.searchString = searchString
			}
		}
	}
	
	// MARK: -
	
	public init() {
		super.init(nibName: nil, bundle: nil)
		
		splitTOCViewController.helpController = self
		compactTOCViewController.helpController = self
		splitSearchViewController.helpController = self

		rootSplitViewController.viewControllers = [splitTOCViewController, splitPageViewController]
		
		compactRootNavigationController.viewControllers = [compactTOCViewController]
		rootSplitViewController.setViewController(compactRootNavigationController, for: .compact)
		
		rootSplitViewController.primaryBackgroundStyle = .sidebar
		rootSplitViewController.preferredPrimaryColumnWidth = UIFloat(300)
		
		preparePageViewController(splitPageViewController)
		
#if targetEnvironment(macCatalyst)
		[splitTOCViewController, splitPageViewController].forEach {
			$0.navigationController?.isNavigationBarHidden = true
		}
#endif
		
		addChild(rootSplitViewController)
		view.addSubview(rootSplitViewController.view)
		
		NotificationCenter.default.addObserver(forName: .toggleTableOfContents, object: nil, queue: nil) { [weak self] _ in
			
			DispatchQueue.main.async {
				
				if self?.rootSplitViewController.traitCollection.horizontalSizeClass == .compact {
					self?.compactRootNavigationController.popToRootViewController(animated: true)
				}
				else {
					UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.7) {
						
						if self?.rootSplitViewController.preferredDisplayMode != .secondaryOnly {
							self?.rootSplitViewController.preferredDisplayMode = .secondaryOnly
							
						}
						else {
							self?.rootSplitViewController.preferredDisplayMode = .oneBesideSecondary
						}
					}
				}
			}
			
		}
	}
	
	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	open override func viewDidLayoutSubviews() {
		rootSplitViewController.view.frame = view.bounds
	}
	
	// MARK: -
	
	func preparePageViewController(_ viewController:COREHelpPageViewController) {
		
		let sidebarItem = UIBarButtonItem(image:UIImage(systemName: "sidebar.leading"), style:.plain, target: self, action: #selector(popToTableOfContents(_:)))
		
		let backItem = UIBarButtonItem(image:UIImage(systemName: "chevron.left"), style:.plain, target: self, action: #selector(goBack(_:)))
		let forwardItem = UIBarButtonItem(image:UIImage(systemName: "chevron.right"), style:.plain, target: self, action: #selector(goForward(_:)))
		
		viewController.navigationItem.leftBarButtonItems = [backItem, forwardItem]
		
		if traitCollection.horizontalSizeClass == .compact {
			viewController.navigationItem.leftBarButtonItems?.insert(sidebarItem, at: 0)
		}
		
		viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:)))
	}
	
	func navigate(to page:HelpPage?) {
		splitPageViewController.navigate(to: page)
		view.window?.windowScene?.title = page?.title
		
		let vc = COREHelpPageViewController()
		vc.navigate(to: page)
		preparePageViewController(vc)
		compactRootNavigationController.popToRootViewController(animated: false)
		compactRootNavigationController.pushViewController(vc, animated: true)
		
		searchVisible = false
	}
	
	// MARK: -
	
	@objc func dismiss(_ sender: Any?) {
		presentingViewController?.dismiss(animated: true)
	}
	
	// MARK: - Navigation
	
	open override func responds(to aSelector: Selector!) -> Bool {
		
		if aSelector == NSSelectorFromString("goBack:") {
			
			if searchVisible == true {
				return true
			}
			
			if traitCollection.horizontalSizeClass == .compact {
				if let pageVC = compactRootNavigationController.viewControllers.last as? COREHelpPageViewController {
					return pageVC.webView.canGoBack
				}
			}
			
			return splitPageViewController
				.webView.canGoBack
		}
		
		if aSelector == NSSelectorFromString("goForward:") {
			if traitCollection.horizontalSizeClass == .compact {
				if let pageVC = compactRootNavigationController.viewControllers.last as? COREHelpPageViewController {
					return pageVC.webView.canGoForward
				}
			}
			
			return splitPageViewController
				.webView.canGoForward
		}
		
		return super.responds(to: aSelector)
	}
	
	@objc func goBack(_ sender: Any?) {
		
		if lastNavigationWasFromSearchPage == true {
			searchVisible = true
			lastNavigationWasFromSearchPage = false
			return
		}
		
		if searchVisible == true {
			searchVisible.toggle()
		}
		
		if traitCollection.horizontalSizeClass == .compact {
			guard let pageVC = compactRootNavigationController.viewControllers.last as? COREHelpPageViewController else { return }
			pageVC.webView.goBack()
		}
		else {
			splitPageViewController.webView.goBack()
		}
	}
	
	@objc func goForward(_ sender: Any?) {
		if traitCollection.horizontalSizeClass == .compact {
			guard let pageVC = compactRootNavigationController.viewControllers.last as? COREHelpPageViewController else { return }
			pageVC.webView.goForward()
		}
		else {
			splitPageViewController.webView.goForward()
		}
	}
	
	@objc func popToTableOfContents(_ sender: Any?) {
		compactRootNavigationController.popToRootViewController(animated: true)
	}
}
