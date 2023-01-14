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
	let compactPageViewController = COREHelpPageViewController()
	let compactSearchViewController = COREHelpSearchViewController()
	
	let splitTOCViewController = COREHelpTableOfContentsViewController()
	let splitPageViewController = COREHelpPageViewController()
	let splitSearchViewController = COREHelpSearchViewController()
	
	// MARK: - Toolbar Items
	
	var sidebarItem:UIBarButtonItem!
	var backItem:UIBarButtonItem!
	var forwardItem:UIBarButtonItem!
	
	// MARK: -
	
	public var helpBundle:HelpBundle? {
		didSet {
			splitTOCViewController.helpBundle = helpBundle
			compactTOCViewController.helpBundle = helpBundle
			splitSearchViewController.helpBundle = helpBundle
			compactSearchViewController.helpBundle = helpBundle
			
			compactPageViewController.baseURL = helpBundle?.url
			splitPageViewController.baseURL = helpBundle?.url
		}
	}
	
	var searchVisible = false {
		didSet {
			if searchVisible == true {
				if splitSearchViewController.presentingViewController == nil {
					if view.window?.traitCollection.horizontalSizeClass == .compact {
						let nc = UINavigationController(rootViewController: compactSearchViewController)
						nc.view.tintColor = .systemPurple
						compactRootNavigationController.present(nc, animated: true)
					}
					else {
						let nc = UINavigationController(rootViewController: splitSearchViewController)
						nc.view.tintColor = .systemPurple
						nc.modalPresentationStyle = .overCurrentContext
						
						nc.isNavigationBarHidden = (UIDevice.current.userInterfaceIdiom == .mac)
						
						splitPageViewController.present(nc, animated: UIDevice.current.userInterfaceIdiom == .mac ? false : true)
						view.window?.windowScene?.title = NSLocalizedString("SEARCH_RESULTS", comment: "")
					}
				}
			}
			else {
				splitSearchViewController.presentingViewController?.dismiss(animated: UIDevice.current.userInterfaceIdiom == .mac ? false : true)
				
			}
		}
	}
	
	var searchString = "" {
		didSet {
			if searchString.isEmpty {
			}
			else {
				searchVisible = true
				splitSearchViewController.searchString = searchString
				compactSearchViewController.searchString = searchString
			}
		}
	}
	
	// MARK: -
	
	public init() {
		super.init(nibName: nil, bundle: nil)
		
		sidebarItem = UIBarButtonItem(image:UIImage(systemName: "sidebar.leading"), style:.plain, target: self, action: #selector(popToTableOfContents(_:)))
		backItem = UIBarButtonItem(image:UIImage(systemName: "chevron.left"), style:.plain, target: self, action: #selector(goBack(_:)))
		forwardItem = UIBarButtonItem(image:UIImage(systemName: "chevron.right"), style:.plain, target: self, action: #selector(goForward(_:)))
		
		
		splitTOCViewController.helpController = self
		compactTOCViewController.helpController = self
		splitSearchViewController.helpController = self
		compactSearchViewController.helpController = self
		
		rootSplitViewController.viewControllers = [splitTOCViewController, splitPageViewController]
		
		compactRootNavigationController.viewControllers = [compactTOCViewController]
		compactRootNavigationController.delegate = self
		
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
		
		validateNavigationButtons()
		
		NotificationCenter.default.addObserver(forName: .viewerDestinationChanged, object: nil, queue: nil) { [weak self] _ in
			DispatchQueue.main.async {
				self?.validateNavigationButtons()
			}
		}
		
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
		
		
		if traitCollection.horizontalSizeClass == .compact {
			viewController.toolbarItems = [.fixedSpace(UIFloat(20)), backItem, .fixedSpace(UIFloat(40)), forwardItem, .flexibleSpace()]
			viewController.navigationItem.leftBarButtonItems = [sidebarItem]
		}
		else {
			viewController.navigationItem.leftBarButtonItems = [backItem, forwardItem]
			viewController.toolbarItems = []
		}
		
		viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:)))
	}
	
	public func navigate(to page:HelpPage?) {
		splitPageViewController.navigate(to: page)
		view.window?.windowScene?.title = page?.title
		
		compactPageViewController.navigate(to: page)
		preparePageViewController(compactPageViewController)
		compactRootNavigationController.popToRootViewController(animated: false)
		compactRootNavigationController.pushViewController(compactPageViewController, animated: true)
		
		compactSearchViewController.presentingViewController?.dismiss(animated: true)
		
		searchVisible = false
	}
	
	open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		preparePageViewController(compactPageViewController)
	}
	
	// MARK: - Key Commands
	
	open override var keyCommands: [UIKeyCommand]? {
		let backCommand = UIKeyCommand(input: "[", modifierFlags: .command, action: NSSelectorFromString("goBack:"))
		let forwardCommand = UIKeyCommand(input: "]", modifierFlags: .command, action: NSSelectorFromString("goForward:"))
		let searchCommand = UIKeyCommand(input: "f", modifierFlags: .command, action: NSSelectorFromString("focusSearch:"))
		if #available(macCatalyst 15.0, *) {
			searchCommand.wantsPriorityOverSystemBehavior = true
		}
		
		let dismissCommand = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: NSSelectorFromString("dismissSearchOrSelf:"))

		return [backCommand, forwardCommand, searchCommand, dismissCommand]
	}
	
	@objc func focusSearch(_ sender:Any?) {
#if targetEnvironment(macCatalyst)
		NotificationCenter.default.post(name:.makeNSSearchFieldFirstResponder, object:nil)
#else
		if view.window?.traitCollection.horizontalSizeClass == .compact {
			compactRootNavigationController.popToRootViewController(animated: true)
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
				self?.compactTOCViewController._focusSearch(self)
			}
		}
		else {
			splitTOCViewController._focusSearch(self)
		}
#endif
	}
	
	// MARK: -
	
	@objc func dismissSearchOrSelf(_ sender: Any?) {
		if searchVisible == true {
			searchVisible.toggle()
		}
		else {
			dismiss(sender)
		}
	}
	
	@objc func dismiss(_ sender: Any?) {
		presentingViewController?.dismiss(animated: true)
	}
	
	// MARK: - Navigation
	
	open override func responds(to aSelector: Selector!) -> Bool {
		
		if aSelector == NSSelectorFromString("goBack:") {
			
			if searchVisible == true {
				return false
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
			if searchVisible == true {
				return false
			}
			
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
		
		if traitCollection.horizontalSizeClass == .compact {
			guard let pageVC = compactRootNavigationController.viewControllers.last as? COREHelpPageViewController else { return }
			pageVC.webView.goBack()
		}
		else {
			splitPageViewController.webView.goBack()
		}
		
		validateNavigationButtons()
	}
	
	@objc func goForward(_ sender: Any?) {
		if traitCollection.horizontalSizeClass == .compact {
			guard let pageVC = compactRootNavigationController.viewControllers.last as? COREHelpPageViewController else { return }
			pageVC.webView.goForward()
		}
		else {
			splitPageViewController.webView.goForward()
		}
		
		validateNavigationButtons()
	}
	
	@objc func popToTableOfContents(_ sender: Any?) {
		compactRootNavigationController.popToRootViewController(animated: true)
	}
	
	func validateNavigationButtons() {
		backItem?.isEnabled = responds(to: NSSelectorFromString("goBack:"))
		forwardItem?.isEnabled = responds(to: NSSelectorFromString("goForward:"))
	}
	
	// MARK: - Navigation Delegate
	
	public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		
		guard traitCollection.horizontalSizeClass == .compact else { return }
		
		if navigationController.viewControllers.count == 1 {
			compactRootNavigationController.isToolbarHidden = true
		}
		else {
			compactRootNavigationController.isToolbarHidden = false
		}
	}
}
