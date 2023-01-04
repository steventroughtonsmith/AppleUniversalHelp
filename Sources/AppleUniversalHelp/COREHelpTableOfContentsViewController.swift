//
//  COREHelpTableOfContentsViewController.swift
//  
//
//  Created by Steven Troughton-Smith on 02/01/2023.
//

import UIKit
import AppleUniversalCore

class COREHelpTableOfContentsViewController: UICollectionViewController, UISearchResultsUpdating {
	
	
	private let reuseIdentifier = "Cell"
	
	var filterString = "" {
		didSet {
			refresh()
		}
	}
	
	var typeselectString = ""
	var lastTypeSelectTimestamp = TimeInterval.zero
	var focusedIndexPath:IndexPath? = nil
	var cachedIndexPath = IndexPath(item:0, section:0)
	
	var helpController:COREHelpRootViewController?
	
	// MARK: -
	
	enum Section {
		case main
	}
	
	class TOCItem: Hashable {
		private let identifier = UUID()
		
		var children:[TOCItem] = []
		
		var page:HelpPage? = nil
		var section:HelpSection? = nil
		var parent:TOCItem? = nil
		
		init(page: HelpPage? = nil) {
			self.page = page
		}
		
		init(section: HelpSection? = nil) {
			self.section = section
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(identifier)
		}
		
		public static func == (lhs: TOCItem, rhs: TOCItem) -> Bool {
			return lhs.identifier == rhs.identifier
		}
	}
	
	var dataSource: UICollectionViewDiffableDataSource<Section, TOCItem>! = nil
	
	// MARK: -
	
	var helpBundle:HelpBundle? {
		didSet {
			refresh()
			
		}
	}
	
	// MARK: -
	
	init() {
		
		let listConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
		let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
		
		super.init(collectionViewLayout: layout)
		
		let titleView = UILabel()
		titleView.text = NSLocalizedString("HELP_TOC_TITLE", comment: "")
		titleView.font = UIFont.boldSystemFont(ofSize: UIFloat(22))
		navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
		
		collectionView.focusGroupIdentifier = "HELP_TOC_TITLE"
		if #available(iOS 15.0, *) {
			collectionView.allowsFocus = true
		}
		collectionView.selectionFollowsFocus = true
		
		let searchController = UISearchController()
		searchController.searchResultsUpdater = self
		searchController.searchBar.placeholder = NSLocalizedString("HELP_TOC_SEARCH_PLACEHOLDER", comment:"")
		searchController.obscuresBackgroundDuringPresentation = false
		
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false
		
		configureDataSource()
		
		collectionView.contentInset = UIEdgeInsets(top: UIFloat(13), left: 0, bottom: UIFloat(13), right: 0)
		
		NotificationCenter.default.addObserver(forName: .viewerDestinationChanged, object: nil, queue: nil) { [weak self] note in
			guard let url = note.object as? URL else { return }
			DispatchQueue.main.async {
				self?.findAndSelectItemForDestinationChange(url)
			}
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	
	// MARK: Data Source -
	
	func configureDataSource() {
		
		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TOCItem> { cell, indexPath, item in
			
			var disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .cell)
			
			if item.section != nil {
				var config = UIListContentConfiguration.sidebarCell()
				
				config.text = item.section?.title
				
				
				config.textProperties.adjustsFontSizeToFitWidth = false
				cell.contentConfiguration = config
			}
			else {
				var config = UIListContentConfiguration.sidebarCell()
				
				config.textProperties.adjustsFontSizeToFitWidth = false
				config.text = item.page?.title
				disclosureOptions.isHidden = true
				cell.contentConfiguration = config
			}
			
			cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
			
		}
		
		dataSource = UICollectionViewDiffableDataSource<Section, TOCItem>(collectionView: collectionView) {
			(collectionView: UICollectionView, indexPath: IndexPath, item: TOCItem) -> UICollectionViewCell? in
			
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
		}
		
		collectionView.dataSource = dataSource
		
	}
	
	// MARK: -
	
	func findAndSelectItemForDestinationChange(_ destination:URL?) {
		var shouldExpand = true
		var currentSnapshot = dataSource.snapshot(for: .main)
		
		func _indexPathOfDestination(_ destination:URL?) -> IndexPath {
			let expandedItems = filteredItems.filter {
				return currentSnapshot.isVisible($0)
			}
			
			var i = 0
			for item in expandedItems {
				if item.page?.url == destination {
					shouldExpand = false
					break
				}
				
				i += 1
			}
			
			return IndexPath(item: i, section: 0)
		}
		
		let ip = _indexPathOfDestination(destination)
		
		if shouldExpand == true {
			guard let hiddenItem = filteredItems.filter({ return $0.page?.url == destination }).first else { return }
			
			guard let parent = hiddenItem.parent else { return }
			currentSnapshot.expand([parent])
			dataSource.apply(currentSnapshot, to: .main) { [weak self] in
				let ip = _indexPathOfDestination(destination)
				self?.collectionView.selectItem(at: ip, animated: false, scrollPosition: [])
				
			}
		}
		else {
			collectionView.selectItem(at: ip, animated: false, scrollPosition: [])
		}
		
	}
	
	// MARK: -
	
	func actuateItem(at indexPath:IndexPath) {
		
		var currentSnapshot = dataSource.snapshot(for: .main)
		
		let expandedItems = filteredItems.filter {
			return currentSnapshot.isExpanded($0)
		}
		
		guard indexPath.item < expandedItems.count else { return }
		
		let item = expandedItems[indexPath.item]
		
		if item.section != nil {
			
			if currentSnapshot.isExpanded(item) {
				currentSnapshot.collapse([item])
			}
			else {
				currentSnapshot.expand([item])
			}
			dataSource.apply(currentSnapshot, to: .main)
		}
		else {
			helpController?.navigate(to: item.page)
		}
		
		cachedIndexPath = indexPath
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		actuateItem(at: indexPath)
	}
	
	// MARK: -
	
	override func didMove(toParent parent: UIViewController?) {
		super.didMove(toParent: parent)
		
		let indexPath = IndexPath(item: 0, section: 0)
		collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
		actuateItem(at: indexPath)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		collectionView.selectItem(at: cachedIndexPath, animated: false, scrollPosition: [])
	}
	
	// MARK: -
	
	var items:[TOCItem] = [] {
		didSet {
		}
	}
	
	var filteredItems:[TOCItem] {
		get {
			if filterString.isEmpty {
				return items
			}
			else {
				return items.filter { item in
					
					let title = ""
					
					return title.contains(filterString)
				}
			}
		}
	}
	
	
	func refresh() {
		guard let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<Section, TOCItem> else { return }
		guard let helpBundle = helpBundle else { return }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<TOCItem>()
		for rootItem in helpBundle.rootItems {
			
			if type(of: rootItem) == HelpSection.self {
				let section = rootItem as! HelpSection
				
				let sectionItem = TOCItem(section: section)
				snapshot.append([sectionItem])
				items.append(sectionItem)
				
				var pageItems:[TOCItem] = []
				for page in section.pages {
					let pageItem = TOCItem(page:page)
					pageItem.parent = sectionItem
					pageItems.append(pageItem)
					items.append(pageItem)
				}
				
				snapshot.append(pageItems, to:sectionItem)
				snapshot.expand(pageItems)
			}
			else if type(of: rootItem) == HelpPage.self {
				let page = rootItem as! HelpPage
				
				let item = TOCItem(page:page)
				
				snapshot.append([item])
				items.append(item)
				snapshot.expand([item])
			}
		}
		
		dataSource.apply(snapshot, to: .main, animatingDifferences: false)
	}
	
	// MARK: - Keyboard
	
	override var keyCommands: [UIKeyCommand]? {
		get {
			var mine = [
				UIKeyCommand(action: #selector(playFocusedItem(_:)), input: "\r"),
				UIKeyCommand(input:UIKeyCommand.inputUpArrow, modifierFlags:[.alternate], action: #selector(focusTopmostItem(_:))),
				UIKeyCommand(input:UIKeyCommand.inputDownArrow, modifierFlags:[.alternate], action: #selector(focusBottommostItem(_:)))
			]
			
			if let original = super.keyCommands {
				mine.append(contentsOf:original)
			}
			
			return mine
		}
	}
	
	@objc func typeSelect(_ sender:UIKeyCommand) {
		
	}
	
	@objc func focusTopmostItem(_ sender:Any?) {
		
		if let focusedIndexPath = focusedIndexPath {
			collectionView.deselectItem(at: focusedIndexPath, animated: true)
		}
		
		let newFocusedIP = IndexPath(item: 0, section: 0)
		collectionView.selectItem(at: newFocusedIP, animated: false, scrollPosition: [.top])
		
		focusedIndexPath = newFocusedIP
		collectionView.setNeedsFocusUpdate()
	}
	
	@objc func focusBottommostItem(_ sender:Any?) {
		
		if let focusedIndexPath = focusedIndexPath {
			collectionView.deselectItem(at: focusedIndexPath, animated: true)
		}
		
		let newFocusedIP = IndexPath(item: items.count-1, section: 0)
		collectionView.selectItem(at: newFocusedIP, animated: false, scrollPosition: [.bottom])
		
		focusedIndexPath = newFocusedIP
		collectionView.setNeedsFocusUpdate()
	}
	
	@objc func playFocusedItem(_ sender:Any?) {
		guard let focusedIndexPath = focusedIndexPath else { return }
		
		collectionView(collectionView, didSelectItemAt: focusedIndexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		
		if let ip = context.nextFocusedIndexPath {
			focusedIndexPath = ip
		}
	}
	
	override func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
		return focusedIndexPath
	}
	
	override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	// MARK: -
	
	@objc(updateSearchResultsForSearchController:) func updateSearchResults(for searchController: UISearchController) {
		filterString = searchController.searchBar.text ?? ""
	}
	
	// MARK: -
	
	override var isModalInPresentation: Bool {
		get {
			return navigationItem.searchController?.isActive ?? false
		}
		set {
			
		}
	}
}
