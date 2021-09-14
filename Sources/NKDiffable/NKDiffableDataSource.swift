//
//  NKDiffableDataSource.swift
//  NKDiffable
//
//  Created by Mihai Fratu on 05/03/2020.
//

import Foundation

@MainActor
open class NKDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NSObject where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    
    internal var currentSnapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>!
    
    open func snapshot() -> NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
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
