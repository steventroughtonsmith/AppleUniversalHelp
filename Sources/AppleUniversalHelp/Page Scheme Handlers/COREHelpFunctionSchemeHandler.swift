//
//  COREHelpFunctionSchemeHandler.swift
//  
//
//  Created by Steven Troughton-Smith on 03/01/2023.
//

import WebKit

class COREHelpFunctionSchemeHandler: NSObject, WKURLSchemeHandler {
	func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
		
		urlSchemeTask.didFailWithError(COREHelpError.taskFailedSuccessfully)
		NotificationCenter.default.post(name: .toggleTableOfContents, object: nil)
	}
	
	func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
		
	}
}
