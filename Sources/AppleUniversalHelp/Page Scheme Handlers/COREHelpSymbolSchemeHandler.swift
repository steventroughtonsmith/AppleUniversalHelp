//
//  COREHelpSymbolSchemeHandler.swift
//  
//
//  Created by Steven Troughton-Smith on 03/01/2023.
//

import WebKit
import AppleUniversalCore

class COREHelpSymbolSchemeHandler: NSObject, WKURLSchemeHandler {
	func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
		
		if let symbolName = urlSchemeTask.request.url?.host {
			
			let symbol = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(pointSize: UIFloat(32)))?.withTintColor(.systemBlue, renderingMode: .alwaysTemplate)
			
			guard let data = symbol?.pngData() else { return }
			urlSchemeTask.didReceive(URLResponse(url: urlSchemeTask.request.url!, mimeType: "image/png", expectedContentLength: data.count, textEncodingName: nil))
			
			urlSchemeTask.didReceive(data)
			urlSchemeTask.didFinish()
		}
	}
	
	func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
		
	}
}
