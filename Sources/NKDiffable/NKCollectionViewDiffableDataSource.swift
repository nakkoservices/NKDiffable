//
//  NKCollectionViewDiffableDataSource.swift
//  NKDiffable
//
//  Created by Mihai Fratu on 02/03/2020.
//  Copyright © 2020 Mihai Fratu. All rights reserved.
//

import UIKit

open class NKCollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NKDiffableDataSource<SectionIdentifierType, ItemIdentifierType>, UICollectionViewDataSource where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {
    
    public typealias CellProvider = (UICollectionView, IndexPath, ItemIdentifierType) -> UICollectionViewCell?
    
    private var _uiDataSource: AnyObject!
    @available(iOS 13, *)
    private var uiDataSource: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> {
        set {
            _uiDataSource = newValue
        }
        get {
            return _uiDataSource as! UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
        }
    }
    
    private var collectionView: UICollectionView!
    private var cellProvider: CellProvider!
    
    public init(collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
        super.init()
        if #available(iOS 13, *) {
            uiDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: cellProvider)
            collectionView.dataSource = self
        }
        else {
            self.currentSnapshot = NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
            self.collectionView = collectionView
            self.cellProvider = cellProvider
            self.collectionView.dataSource = self
        }
    }

    open func apply(_ snapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        if #available(iOS 13, *) {
            uiDataSource.apply(snapshot.nsSnapshot(), animatingDifferences: animatingDifferences, completion: completion)
        }
        else {
            let oldSnapshot = currentSnapshot!
            let differences = snapshot.difference(from: oldSnapshot)
            
            let areAnimationsEnabled = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(animatingDifferences)
            collectionView.performBatchUpdates({
                currentSnapshot = snapshot
                applyDifferences(differences, for: snapshot, and: oldSnapshot)
            }) { (done) in completion?() }
            UIView.setAnimationsEnabled(areAnimationsEnabled)
        }
    }
    
    private func applyDifferences(_ differences: [NKDiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType>], for snapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, and oldSnapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) {
        differences.forEach {
            switch $0 {
            // Deletions
            case .sectionDelete(let sectionIdentifier):
                let index = oldSnapshot.indexOfSection(sectionIdentifier)!
                collectionView.deleteSections(IndexSet(integer: index))
            case .itemDelete(let sectionIdentifier, let itemIdentifier):
                let sectionIndex = oldSnapshot.indexOfSection(sectionIdentifier)!
                let index = oldSnapshot.indexOfItem(itemIdentifier)!
                collectionView.deleteItems(at: [IndexPath(row: index, section: sectionIndex)])
            // Inserts
            case .sectionInsert(let sectionIdentifier):
                let index = snapshot.indexOfSection(sectionIdentifier)!
                collectionView.insertSections(IndexSet(integer: index))
            case .itemInsert(let sectionIdentifier, let itemIdentifier):
                let sectionIndex = snapshot.indexOfSection(sectionIdentifier)!
                let index = snapshot.indexOfItem(itemIdentifier)!
                collectionView.insertItems(at: [IndexPath(row: index, section: sectionIndex)])
            // Moves
            case .sectionMove(let sectionIdentifier):
                let fromIndex = oldSnapshot.indexOfSection(sectionIdentifier)!
                let toIndex = snapshot.indexOfSection(sectionIdentifier)!
                collectionView.moveSection(fromIndex, toSection: toIndex)
            case .itemMove(let fromSectionIdentifier, let toSectionIdentifier, let itemIdentifier):
                let fromSectionIndex = oldSnapshot.indexOfSection(fromSectionIdentifier)!
                let fromIndex = oldSnapshot.indexOfItem(itemIdentifier)!
                let toSectionIndex = snapshot.indexOfSection(toSectionIdentifier)!
                let toIndex = snapshot.indexOfItem(itemIdentifier)!
                collectionView.moveItem(at: IndexPath(row: fromIndex, section: fromSectionIndex), to: IndexPath(row: toIndex, section: toSectionIndex))
            // Reloads
            case .sectionReload(let sectionIdentifier):
                let index = snapshot.indexOfSection(sectionIdentifier)!
                collectionView.reloadSections(IndexSet(integer: index))
            case .itemReload(let itemIdentifier):
                let sectionIdentifier = snapshot.sectionIdentifier(containingItem: itemIdentifier)!
                let sectionIndex = snapshot.indexOfSection(sectionIdentifier)!
                let index = snapshot.indexOfItem(itemIdentifier)!
                collectionView.reloadItems(at: [IndexPath(row: index, section: sectionIndex)])
            }
        }
    }
    
    open override func snapshot() -> NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        if #available(iOS 13, *) {
            return NKDiffableDataSourceSnapshot(uiDataSource.snapshot())
        }
        return super.snapshot()
    }
    
    open override func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        if #available(iOS 13, *) {
            return uiDataSource.itemIdentifier(for: indexPath)
        }
        return super.itemIdentifier(for: indexPath)
    }

    open override func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        if #available(iOS 13, *) {
            return uiDataSource.indexPath(for: itemIdentifier)
        }
        return super.indexPath(for: itemIdentifier)
    }
    
    // MARK: - UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        if #available(iOS 13, *) {
            return uiDataSource.numberOfSections(in: collectionView)
        }
        return currentSnapshot.numberOfSections
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if #available(iOS 13, *) {
            return uiDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        }
        return currentSnapshot.itemIdentifiers(inSection: currentSnapshot.sectionIdentifiers[section]).count
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 13, *) {
            return uiDataSource.collectionView(collectionView, cellForItemAt: indexPath)
        }
        
        guard let item = itemIdentifier(for: indexPath) else {
            fatalError("Could not find an item identifier for indexPath: \(indexPath)")
        }
        
        guard let cell = cellProvider(collectionView, indexPath, item) else {
            fatalError("UICollectionView dataSource returned a nil cell for row at index path: \(indexPath). Collection view: \(collectionView)")
        }
        
        return cell
    }

    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if #available(iOS 13, *) {
            return uiDataSource.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
        return UICollectionReusableView(frame: .zero)
    }

    open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if #available(iOS 13, *) {
            return uiDataSource.collectionView(collectionView, canMoveItemAt: indexPath)
        }
        return false
    }

    open func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if #available(iOS 13, *) {
            uiDataSource.collectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
        }
    }

    open func indexTitles(for collectionView: UICollectionView) -> [String]? {
        if #available(iOS 13, *) {
            return uiDataSource.indexTitles(for: collectionView)
        }
        return nil
    }
    
    open func collectionView(_ collectionView: UICollectionView, indexPathForIndexTitle title: String, at index: Int) -> IndexPath {
        if #available(iOS 13, *) {
            return uiDataSource.collectionView(collectionView, indexPathForIndexTitle: title, at: index)
        }
        return IndexPath(row: 0, section: 0)
    }

    open func description() -> String {
        if #available(iOS 13, *) {
            return uiDataSource.description()
        }
        return description
    }
    
}
