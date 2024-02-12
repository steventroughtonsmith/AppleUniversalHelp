//
//  COREHelpSearchViewController.swift
//
//
//  Created by Steven Troughton-Smith on 05/01/2023.
//

import UIKit
import AppleUniversalCore

class COREHelpSearchViewController: UICollectionViewController {
	
	private let reuseIdentifier = "Cell"
	
	var searchString = "" {
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
	
	class SearchResultItem: Hashable {
		private let identifier = UUID()
		
		var page:HelpPage? = nil
		
		init(page: HelpPage? = nil) {
			self.page = page
		}
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(identifier)
		}
		
		public static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
			return lhs.identifier == rhs.identifier
		}
	}
	
	var dataSource: UICollectionViewDiffableDataSource<Section, SearchResultItem>! = nil
	
	// MARK: -
	
	var helpBundle:HelpBundle? {
		didSet {
			refresh()
			
		}
	}
	
	// MARK: -
	
	init() {
		
		var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
		listConfiguration.headerMode = .none
		
		let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
		
		super.init(collectionViewLayout: layout)
		
		title = NSLocalizedString("SEARCH_RESULTS", comment: "")
		
		if #available(iOS 15.0, *) {
			collectionView.allowsFocus = true
		}
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss(_:)))
		
		configureDataSource()
		
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Data Source
	
	func configureDataSource() {
		
		let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SearchResultItem> { cell, indexPath, item in
			
			let padding = UIFloat(13)
			var disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .cell)
			
			
			var config = UIListContentConfiguration.subtitleCell()
			
			config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: padding, leading: 0, bottom: padding, trailing: 0)
			
			config.text = item.page?.title
			config.textProperties.font = UIFont.boldSystemFont(ofSize: UIFloat(18))
			config.secondaryText = item.page?.summary
			config.secondaryTextProperties.font = UIFont.systemFont(ofSize: UIFloat(16))
			config.textToSecondaryTextVerticalPadding = UIFloat(8)
			
			
			disclosureOptions.isHidden = true
			cell.contentConfiguration = config
			
			var bgConfig = UIBackgroundConfiguration.listPlainCell()
			cell.backgroundConfiguration = bgConfig
			
			cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
			
		}
		
		dataSource = UICollectionViewDiffableDataSource<Section, SearchResultItem>(collectionView: collectionView) {
			(collectionView: UICollectionView, indexPath: IndexPath, item: SearchResultItem) -> UICollectionViewCell? in
			
			return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
		}
		
		collectionView.dataSource = dataSource
		
	}
	
	// MARK: -
	
	func actuateItem(at indexPath:IndexPath) {
		
		guard indexPath.item < items.count else { return }
		
		let item = items[indexPath.item]
		
		helpController?.navigate(to: item.page)
		
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
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		collectionView.selectItem(at: cachedIndexPath, animated: false, scrollPosition: [])
	}
	
	// MARK: -
	
	var items:[SearchResultItem] = [] {
		didSet {
		}
	}
	
	func refresh() {
		guard let dataSource = collectionView.dataSource as? UICollectionViewDiffableDataSource<Section, SearchResultItem> else { return }
		guard let helpBundle = helpBundle else { return }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<SearchResultItem>()
		
		items = []
		for page in helpBundle.pagesMatchingSearchTerm(searchString) {
			
			let item = SearchResultItem(page: page)
			
			items.append(item)
			snapshot.append([item])
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
	
	@objc func dismiss(_ sender: Any?) {
		presentingViewController?.dismiss(animated: true)
	}
	
#if os(visionOS)
	override var preferredContainerBackgroundStyle: UIContainerBackgroundStyle {
		return .glass
	}
#endif
}
