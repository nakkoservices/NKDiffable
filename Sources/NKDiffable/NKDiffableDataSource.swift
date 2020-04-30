//
//  NKDiffableDataSource.swift
//  NKDiffable
//
//  Created by Mihai Fratu on 05/03/2020.
//

import Foundation

open class NKDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NSObject where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    
    final private(set) lazy var lock: NSObject = {
        return NSObject()
    }()
    
    internal var currentSnapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>!
    
    open func snapshot() -> NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        var newSnapshot = NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        newSnapshot = currentSnapshot
        newSnapshot.sectionsToReload = []
        newSnapshot.itemsToReload = []
        return newSnapshot
    }
    
    open func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        return currentSnapshot.itemIdentifiers(inSection: currentSnapshot.sectionIdentifiers[indexPath.section])[indexPath.row]
    }

    open func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        guard let sectionIdentifier = currentSnapshot.sectionIdentifier(containingItem: itemIdentifier) else {
            return nil
        }
        guard let row = currentSnapshot.indexOfItem(itemIdentifier), let section = currentSnapshot.indexOfSection(sectionIdentifier) else {
            return nil
        }
        return IndexPath(row: row, section: section)
    }
    
}
