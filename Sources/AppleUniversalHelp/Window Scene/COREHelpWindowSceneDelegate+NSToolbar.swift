//
//  COREHelpWindowSceneDelegate.swift
//  
//
//  Created by Steven Troughton-Smith on 03/01/2023.
//

#if targetEnvironment(macCatalyst)
import UIKit
import AppKit

extension NSToolbarItem.Identifier {
	static let back = NSToolbarItem.Identifier("com.help.back")
	static let forward = NSToolbarItem.Identifier("com.help.forward")
	static let navigation = NSToolbarItem.Identifier("com.help.navigation")
	static let share = NSToolbarItem.Identifier("com.help.share")
	static let search = NSToolbarItem.Identifier("com.help.search")
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
			let item = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: [UIImage(systemName: "magnifyingglass")!], selectionMode: .momentary, labels: nil, target: self, action: nil)
			
			return item
		}
		
		return NSToolbarItem(itemIdentifier: itemIdentifier)
	}
}
#endif
