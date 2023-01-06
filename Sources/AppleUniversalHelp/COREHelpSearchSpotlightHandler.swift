//
//  File.swift
//  
//
//  Created by Steven Troughton-Smith on 06/01/2023.
//

import Foundation

/**

~~~
 
 /*  Sample registration & invocation from client app: */
 func setupHelp() {
	 #if targetEnvironment(macCatalyst)
	 
	 let helpBundle = HelpBundle(url:Bundle.main.url(forResource: "Help", withExtension: "help")!)
	let handler = COREHelpSearchSpotlightHandler(helpBundle:helpBundle)
	 
	/* When a help item is triggered, launch the help window scene and navigate to corresponding page */
	handler.actionHandler = { [weak self] page in
		 let activity = NSUserActivity(activityType: "com.highcaffeinecontent.broadcasts.help")
		 UIApplication.shared.requestSceneSessionActivation(self?.helpSession, userActivity: activity, options: nil)
		 
		 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			 guard let helpScene = self?.helpSession?.scene?.delegate as? COREHelpWindowSceneDelegate else { return }
			 helpScene.helpRootController.navigate(to: page)
		 }
	 }
	 
	 handler.registerWithSystem()
	 
	 self.helpSearchHandler = handler
	 #endif
 }
 ~~~
 
 */
open class COREHelpSearchSpotlightHandler: NSObject {

	var helpBundle:HelpBundle!
	public var actionHandler:(HelpPage) -> Void = { _ in }
	
	// MARK: -
	
	public init(helpBundle: HelpBundle!) {
		self.helpBundle = helpBundle
	}
	
	// MARK: - Registration
	
	public func registerWithSystem() {
		guard let nsApp = NSClassFromString("NSApplication") else { return }
		guard let sharedApplication = nsApp.value(forKeyPath: "sharedApplication") as? AnyObject else { return }
		
		let _ = sharedApplication.perform(NSSelectorFromString("registerUserInterfaceItemSearchHandler:"), with: self)
	}
	
	// MARK: - NSUserInterfaceItemSearching
	
	@objc(searchForItemsWithSearchString:resultLimit:matchedItemHandler:) func searchForItems(withSearch: String, resultLimit: Int, matchedItemHandler: ([Any]) -> Void) {
		
		matchedItemHandler(helpBundle.pagesMatchingSearchTerm(withSearch))
	}
	
	@objc(localizedTitlesForItem:) func localizedTitles(forItem: Any) -> [String] {
		
		if let page = forItem as? HelpPage {
			return [page.title]
		}
		
		return []
	}
	
	@objc(performActionForItem:) func performAction(forItem: Any) {
		if let page = forItem as? HelpPage {
			actionHandler(page)
		}
	}
}
