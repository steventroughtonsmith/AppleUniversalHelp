//
//  COREHelpWindowSceneDelegate.swift
//  
//
//  Created by Steven Troughton-Smith on 03/01/2023.
//

#if targetEnvironment(macCatalyst)
import UIKit
import AppKit
import AppleUniversalCore

extension NSToolbarItem.Identifier {
	static let back = NSToolbarItem.Identifier("com.help.back")
	static let forward = NSToolbarItem.Identifier("com.help.forward")
	static let navigation = NSToolbarItem.Identifier("com.help.navigation")
	static let share = NSToolbarItem.Identifier("com.help.share")
	static let search = NSToolbarItem.Identifier("com.help.search")
}


extension NSNotification.Name {
	static let makeNSSearchFieldFirstResponder = NSNotification.Name("COREHelpMakeNSSearchFieldFirstResponder")
}

extension NSObject {
	@objc func addItemWithTitle(_ string:String, action:Selector?, keyEquivalent:String) -> NSObject? {
		
		return nil
	}
	
	@objc func addItem(_ item:NSObject?) {
		
	}
	
	@objc class func separatorItem() -> NSObject? {
		return nil
	}

}

extension COREHelpWindowSceneDelegate: NSToolbarDelegate {
	
	func items()  -> [NSToolbarItem.Identifier] {
		return [.toggleSidebar, .back, .forward, .search]
	}
	
	public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return items()
	}
	
	public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return items()
	}
	
	public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		
		if itemIdentifier == .back {
			let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: [UIImage(systemName: "chevron.left")!], selectionMode: .momentary, labels: nil, target: helpRootController, action: NSSelectorFromString("goBack:"))
			item.isNavigational = true
			
			return item
		}
		else if itemIdentifier == .forward {
			let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: [UIImage(systemName: "chevron.right")!], selectionMode: .momentary, labels: nil, target: helpRootController, action: NSSelectorFromString("goForward:"))
			item.isNavigational = true
			
			return item
		}
		else if itemIdentifier == .share {
			let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: [UIImage(systemName: "square.and.arrow.up")!], selectionMode: .momentary, labels: nil, target: self, action: nil)
			
			return item
		}
		else if itemIdentifier == .search {
			
			let NSSearchToolbarItem = NSClassFromString("NSSearchToolbarItem") as! NSToolbarItem.Type
			
			let item = NSSearchToolbarItem.init(itemIdentifier: itemIdentifier)
			item.target = self
			item.action = NSSelectorFromString("toolbarSearch:")
			
			if let searchField = item.value(forKey: "searchField") as? NSObject {
				searchField.setValue("help.search.recents", forKey: "recentsAutosaveName")
				searchField.setValue(true, forKey: "sendsWholeSearchString")

				if let NSMenu = NSClassFromString("NSMenu") as? NSObject.Type {
					let menu = NSMenu.init()
					
					let NSSearchFieldRecentsTitleMenuItemTag = 1000
					let NSSearchFieldRecentsMenuItemTag = 1001
					let NSSearchFieldClearRecentsMenuItemTag = 1002
					let NSSearchFieldNoRecentsMenuItemTag = 1003
					
					/* Build Recents Menu Template */
					if let NSMenuItem = NSClassFromString("NSMenuItem") as? NSObject.Type {
						do {
							let item = menu.addItemWithTitle(NSLocalizedString("SEARCH_RECENTS_TITLE", comment: ""), action: nil, keyEquivalent: "")
							item?.setValue(NSSearchFieldRecentsTitleMenuItemTag, forKey: "tag")
						}
						
						do {
							let item = menu.addItemWithTitle("", action: nil, keyEquivalent: "")
							item?.setValue(NSSearchFieldRecentsMenuItemTag, forKey: "tag")
						}
						
						menu.addItem(NSMenuItem.separatorItem())
						
						do {
							let item = menu.addItemWithTitle(NSLocalizedString("SEARCH_RECENTS_CLEAR", comment: ""), action: nil, keyEquivalent: "")
							item?.setValue(NSSearchFieldClearRecentsMenuItemTag, forKey: "tag")
						}
						
						do {
							let item = menu.addItemWithTitle(NSLocalizedString("SEARCH_RECENTS_NO_RECENTS", comment: ""), action: nil, keyEquivalent: "")
							item?.setValue(NSSearchFieldNoRecentsMenuItemTag, forKey: "tag")
						}
					}
					
					searchField.setValue(menu, forKey: "searchMenuTemplate")
					
					
				}
				
				NotificationCenter.default.addObserver(forName: .makeNSSearchFieldFirstResponder, object: nil, queue: nil) { _ in
					let selector = NSSelectorFromString("becomeFirstResponder")
					
					if searchField.responds(to: selector) {
						DispatchQueue.main.async {
							searchField.perform(selector)
						}
					}
				}
			}
			
			return item
		}
		
		return NSToolbarItem(itemIdentifier: itemIdentifier)
	}
	
	@objc func toolbarSearch(_ sender:NSObject?) {
		guard sender?.responds(to: NSSelectorFromString("stringValue")) ?? false else { return }
		guard let searchString = sender?.value(forKey: "stringValue") as? String else { return }
		
		helpRootController.searchString = searchString
	}
	
}
#endif
