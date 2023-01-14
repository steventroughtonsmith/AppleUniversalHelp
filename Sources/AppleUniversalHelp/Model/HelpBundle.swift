//
//  HelpBundle.swift
//  
//
//  Created by Steven Troughton-Smith on 03/01/2023.
//

import Foundation

public class HelpItem: Hashable {
	private let identifier = UUID()
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
	}
	
	public static func == (lhs: HelpItem, rhs: HelpItem) -> Bool {
		return lhs.identifier == rhs.identifier
	}
}

public class HelpPage: HelpItem {
	
	var title = "Page"
	var url:URL
	var summary = ""
	var tags:[String] = []
	
	public init(url:URL) {
		self.url = url
		title = (url.lastPathComponent as NSString).deletingPathExtension
		
		let metadataURL = url.appendingPathExtension("json")
		guard let metadataPath = metadataURL.path.removingPercentEncoding else { return }
		
		if FileManager.default.fileExists(atPath: metadataPath) {
			do {
				let data = try Data(contentsOf: metadataURL)
				let metadata = try JSONDecoder().decode([String:[String]].self, from: data)
				
				summary = metadata["summary"]?.first ?? ""
				tags = metadata["tags"] ?? []
			}
			catch {
				
			}
		}
	}
}

public class HelpSection: HelpItem {
	
	var url:URL
	var title = "Section"
	var pages:[HelpPage]
	
	public init(url:URL) {
		self.url = url
		
		var _pages:[HelpPage] = []
		
		let nspath = url.path as NSString
		
		let data = try! Data(contentsOf: url.appendingPathComponent("index.json"))
		let indices = try! JSONDecoder().decode([String].self, from: data)

		for item in indices {
			
			let pagePath = nspath.appendingPathComponent(item)
			
			if FileManager.default.fileExists(atPath: pagePath) {
				_pages.append(HelpPage(url:URL(fileURLWithPath: pagePath)))
			}
			else {
				NSLog("[HELP] Missing page \(pagePath)")
			}
		}
		
		title = url.lastPathComponent
		pages = _pages
	}
	
}

public struct HelpBundle {
	private let identifier = UUID()
	
	var url:URL
	var rootItems:[HelpItem]
	
	public init(url:URL) {
		self.url = url
		
		var _rootItems:[HelpItem] = []
		
		let data = try! Data(contentsOf: url.appendingPathComponent("index.json"))
		let indices = try! JSONDecoder().decode([String].self, from: data)
		
		let nspath = url.path as NSString
		for item in indices {
			let itemPath = nspath.appendingPathComponent(item)

			if item.hasSuffix("html") {
				if FileManager.default.fileExists(atPath: itemPath) {
					_rootItems.append(HelpPage(url:URL(fileURLWithPath: itemPath)))
				}
				else {
					NSLog("[HELP] Missing item \(itemPath)")
				}
			}
			else {
				var isDirectory = ObjCBool(booleanLiteral: false)
				FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDirectory)
				
				if isDirectory.boolValue == true {
					_rootItems.append(HelpSection(url:URL(fileURLWithPath: itemPath)))
				}
			}
		}
		
		rootItems = _rootItems
	}
	
	func pagesMatchingSearchTerm(_ searchTerm:String) -> [HelpPage] {
		
		let searchComponents = searchTerm.components(separatedBy: .whitespacesAndNewlines)
		var results:[HelpPage] = []
		var relevance:[HelpPage:Int] = [:]
		
		func _matchPage(_ page:HelpPage, tags:[String]) {
			for match in tags {
				for searchComponent in searchComponents {
					if match.localizedCaseInsensitiveContains(searchComponent) {
						if !results.contains(page) {
							results.append(page)
							relevance[page] = 1
						}
						else {
							relevance[page] = (relevance[page] ?? 1) + 1
						}
					}
				}
			}
		}
		
		for item in rootItems {
			if let section = item as? HelpSection {
				for page in section.pages {
					let titleComponents = page.title.components(separatedBy: .whitespacesAndNewlines)
					let summaryComponents = page.summary.components(separatedBy: .whitespacesAndNewlines)
				
					_matchPage(page, tags: titleComponents)
					_matchPage(page, tags: summaryComponents)
					_matchPage(page, tags: page.tags)
				}
			}
			else if let page = item as? HelpPage {
				let titleComponents = page.title.components(separatedBy: .whitespacesAndNewlines)
				let summaryComponents = page.summary.components(separatedBy: .whitespacesAndNewlines)

				_matchPage(page, tags: titleComponents)
				_matchPage(page, tags: summaryComponents)
				_matchPage(page, tags: page.tags)
			}
		}
		
		return results.sorted { a, b in
			return (relevance[a] ?? 0) > (relevance[b] ?? 0)
		}
	}
}
