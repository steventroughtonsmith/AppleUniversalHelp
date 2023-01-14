//
//  COREHelpResourceSchemeHandler.swift
//  
//
//  Created by Steven Troughton-Smith on 03/01/2023.
//

import WebKit

class COREHelpResourceSchemeHandler: NSObject, WKURLSchemeHandler {
	var baseURL:URL? = nil
	
	func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
		
		if urlSchemeTask.request.url?.host == "appicon" {
			let iconName = Bundle.main.infoDictionary?["CFBundleIconFile"] as? String
			
			let icon = UIImage(named: iconName ?? "")
			guard let data = icon?.pngData() else { return }
			urlSchemeTask.didReceive(URLResponse(url: urlSchemeTask.request.url!, mimeType: "image/png", expectedContentLength: data.count, textEncodingName: nil))
			
			urlSchemeTask.didReceive(data)
			urlSchemeTask.didFinish()
		}
		else if urlSchemeTask.request.url?.scheme == "helpbundle" {
			if let nsPath = urlSchemeTask.request.url?.absoluteString as? NSString {
			
				if let url = baseURL?.appendingPathComponent(nsPath.replacingOccurrences(of: "helpbundle://", with: "")) {
					
					do {
						let data = try Data(contentsOf: url)
						urlSchemeTask.didReceive(URLResponse(url: url, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil))
						urlSchemeTask.didReceive(data)
						urlSchemeTask.didFinish()
					}
					catch {
						
					}
				}
			}
		}
		else {
			let url = Bundle.main.url(forResource: "styles", withExtension: "css")!
			do {
				let data = try Data(contentsOf: url)
				urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: nil))
				urlSchemeTask.didReceive(data)
				urlSchemeTask.didFinish()
			}
			catch {
				
			}
		}
	}
	
	func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
		
	}
}
