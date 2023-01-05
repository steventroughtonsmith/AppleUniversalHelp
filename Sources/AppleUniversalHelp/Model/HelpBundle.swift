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
		
		do {
			let nspath = url.path as NSString
			let contents = try FileManager.default.contentsOfDirectory(atPath: nspath as String)
			for item in contents {
				if !item.hasSuffix("html") {
					continue
				}
				
				let pagePath = nspath.appendingPathComponent(item)
				
				_pages.append(HelpPage(url:URL(fileURLWithPath: pagePath)))
			}
		}
		catch {
			
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
				_rootItems.append(HelpPage(url:URL(fileURLWithPath: itemPath)))
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
		
		let searchTerm = searchTerm.lowercased()
		var results:[HelpPage] = []
		
		for item in rootItems {
			if let section = item as? HelpSection {
				for page in section.pages {
					if page.title.localizedCaseInsensitiveContains(searchTerm) {
						results.append(page)
					}
					else if page.summary.localizedCaseInsensitiveContains(searchTerm) {
						results.append(page)
					}
					else {
						for tag in page.tags {
							if tag.localizedCaseInsensitiveContains(searchTerm) {
								results.append(page)
								break
							}
						}
					}
					
				}
			}
			else if let page = item as? HelpPage {
				if page.title.localizedCaseInsensitiveContains(searchTerm) {
					results.append(page)
				}
				else if page.summary.localizedCaseInsensitiveContains(searchTerm) {
					results.append(page)
				}
				else {
					for tag in page.tags {
						if tag.localizedCaseInsensitiveContains(searchTerm) {
							results.append(page)
							break
						}
					}
				}
			}
		}
		
		return results
	}
}
