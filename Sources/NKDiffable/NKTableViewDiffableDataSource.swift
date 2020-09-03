//
//  NKTableViewDiffableDataSource.swift
//  NKDiffable
//
//  Created by Mihai Fratu on 27/02/2020.
//  Copyright © 2020 Mihai Fratu. All rights reserved.
//

import UIKit

open class NKTableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NKDiffableDataSource<SectionIdentifierType, ItemIdentifierType>, UITableViewDataSource where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
     
    public typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType) -> UITableViewCell?
    
    private var _uiDataSource: AnyObject!
    @available(iOS 13, tvOS 13, *)
    private var uiDataSource: UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> {
        set {
            _uiDataSource = newValue
        }
        get {
            return _uiDataSource as! UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
        }
    }
    
    private var tableView: UITableView!
    private var cellProvider: CellProvider!
    
    public init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        super.init()
        if #available(iOS 13, tvOS 13, *) {
            uiDataSource = UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>(tableView: tableView, cellProvider: cellProvider)
            tableView.dataSource = self
        }
        else {
            self.currentSnapshot = NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
            self.tableView = tableView
            self.cellProvider = cellProvider
            self.tableView.dataSource = self
        }
    }
    
    open func apply(_ snapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        if #available(iOS 13, tvOS 13, *) {
            DispatchQueue.global().sync {
                uiDataSource.apply(snapshot.nsSnapshot(), animatingDifferences: animatingDifferences, completion: completion)
            }
        }
        else {
            DispatchQueue.global().sync {
                guard let oldSnapshot = currentSnapshot else { return }
                let differences = snapshot.difference(from: oldSnapshot)
                
                if #available(iOS 11, tvOS 11, *), animatingDifferences {
                    tableView.performBatchUpdates({
                        currentSnapshot = snapshot
                        applyDifferences(differences, for: snapshot, and: oldSnapshot)
                    }) { [weak self] (done) in
                        self?.applyReloads(differences, for: snapshot, and: oldSnapshot)
                        completion?()
                    }
                } else {
                    let areAnimationsEnabled = UIView.areAnimationsEnabled
                    UIView.setAnimationsEnabled(animatingDifferences)
                    tableView.beginUpdates()
                    currentSnapshot = snapshot
                    applyDifferences(differences, for: snapshot, and: oldSnapshot)
                    tableView.endUpdates()
                    DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                        self?.applyReloads(differences, for: snapshot, and: oldSnapshot)
                    }
                    UIView.setAnimationsEnabled(areAnimationsEnabled)
                }
            }
        }
    }
    
    private func applyDifferences(_ differences: [NKDiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType>], for snapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, and oldSnapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) {
        differences.forEach {
            switch $0 {
            // Deletions
            case .sectionDelete(let sectionIdentifier):
                let index = oldSnapshot.indexOfSection(sectionIdentifier)!
                tableView.deleteSections(IndexSet(integer: index), with: defaultRowAnimation)
            case .itemDelete(let sectionIdentifier, let itemIdentifier):
                let sectionIndex = oldSnapshot.indexOfSection(sectionIdentifier)!
                let index = oldSnapshot.indexOfItem(itemIdentifier)!
                tableView.deleteRows(at: [IndexPath(row: index, section: sectionIndex)], with: defaultRowAnimation)
            // Inserts
            case .sectionInsert(let sectionIdentifier):
                let index = snapshot.indexOfSection(sectionIdentifier)!
                tableView.insertSections(IndexSet(integer: index), with: defaultRowAnimation)
            case .itemInsert(let sectionIdentifier, let itemIdentifier):
                let sectionIndex = snapshot.indexOfSection(sectionIdentifier)!
                let index = snapshot.indexOfItem(itemIdentifier)!
                tableView.insertRows(at: [IndexPath(row: index, section: sectionIndex)], with: defaultRowAnimation)
            // Moves
            case .sectionMove(let sectionIdentifier):
                let fromIndex = oldSnapshot.indexOfSection(sectionIdentifier)!
                let toIndex = snapshot.indexOfSection(sectionIdentifier)!
                tableView.moveSection(fromIndex, toSection: toIndex)
            case .itemMove(let fromSectionIdentifier, let toSectionIdentifier, let itemIdentifier):
                let fromSectionIndex = oldSnapshot.indexOfSection(fromSectionIdentifier)!
                let fromIndex = oldSnapshot.indexOfItem(itemIdentifier)!
                let toSectionIndex = snapshot.indexOfSection(toSectionIdentifier)!
                let toIndex = snapshot.indexOfItem(itemIdentifier)!
                tableView.moveRow(at: IndexPath(row: fromIndex, section: fromSectionIndex), to: IndexPath(row: toIndex, section: toSectionIndex))
            default: break
            }
        }
    }
    
    private func applyReloads(_ differences: [NKDiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType>], for snapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, and oldSnapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) {
        differences.forEach {
            switch $0 {
            // Reloads
            case .sectionReload(let sectionIdentifier):
                let index = snapshot.indexOfSection(sectionIdentifier)!
                tableView.reloadSections(IndexSet(integer: index), with: defaultRowAnimation)
            case .itemReload(let itemIdentifier):
                let sectionIdentifier = snapshot.sectionIdentifier(containingItem: itemIdentifier)!
                let sectionIndex = snapshot.indexOfSection(sectionIdentifier)!
                let index = snapshot.indexOfItem(itemIdentifier)!
                tableView.reloadRows(at: [IndexPath(row: index, section: sectionIndex)], with: defaultRowAnimation)
            default: break
            }
        }
    }
    
    open override func snapshot() -> NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        if #available(iOS 13, tvOS 13, *) {
            return NKDiffableDataSourceSnapshot(uiDataSource.snapshot())
        }
        return super.snapshot()
    }
    
    open override func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.itemIdentifier(for: indexPath)
        }
        return super.itemIdentifier(for: indexPath)
    }

    open override func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.indexPath(for: itemIdentifier)
        }
        return super.indexPath(for: itemIdentifier)
    }
    
    private var _defaultRowAnimation: UITableView.RowAnimation = .fade
    open var defaultRowAnimation: UITableView.RowAnimation {
        set {
            if #available(iOS 13, tvOS 13, *) {
                uiDataSource.defaultRowAnimation = newValue
            }
            else {
                _defaultRowAnimation = newValue
            }
        }
        get {
            if #available(iOS 13, tvOS 13, *) {
                return uiDataSource.defaultRowAnimation
            }
            else {
                return _defaultRowAnimation
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.numberOfSections(in: tableView)
        }
        return currentSnapshot.numberOfSections
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, numberOfRowsInSection: section)
        }
        return currentSnapshot.itemIdentifiers(inSection: currentSnapshot.sectionIdentifiers[section]).count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, cellForRowAt: indexPath)
        }
        
        guard let item = itemIdentifier(for: indexPath) else {
            fatalError("Could not find an item identifier for indexPath: \(indexPath)")
        }
        
        guard let cell = cellProvider(tableView, indexPath, item) else {
            fatalError("UITableView dataSource returned a nil cell for row at index path: \(indexPath). Table view: \(tableView)")
        }
        
        return cell
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, titleForHeaderInSection: section)
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, titleForFooterInSection: section)
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, canEditRowAt: indexPath)
        }
        return false
    }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if #available(iOS 13, tvOS 13, *) {
            uiDataSource.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
        }
    }
    
    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, canMoveRowAt: indexPath)
        }
        return true
    }
    
    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if #available(iOS 13, tvOS 13, *) {
            uiDataSource.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        }
    }
    
    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.sectionIndexTitles(for: tableView)
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.tableView(tableView, sectionForSectionIndexTitle: title, at: index)
        }
        return 0
    }
    
    open func description() -> String {
        if #available(iOS 13, tvOS 13, *) {
            return uiDataSource.description()
        }
        return description
    }
    
}
