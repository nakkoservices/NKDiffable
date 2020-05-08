//
//  NKDiffableDataSourceSnapshot.swift
//  NKDiffable
//
//  Created by Mihai Fratu on 27/02/2020.
//  Copyright © 2020 Mihai Fratu. All rights reserved.
//

import UIKit

private struct _NKDiffableDataSourceSnapshotSection<SectionIdentifierType, ItemIdentifierType>: Hashable where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
    
    let identifier: SectionIdentifierType
    var items: NKOrderedSet<ItemIdentifierType> = NKOrderedSet()
    
    init(_ sectionIdentifier: SectionIdentifierType) {
        identifier = sectionIdentifier
    }
    
    mutating func append(_ items: [ItemIdentifierType]) {
        items.forEach { append($0) }
    }
    
    mutating func append(_ item: ItemIdentifierType) {
        items.append(item)
    }
    
    mutating func remove(_ item: ItemIdentifierType) {
        guard let index = items.firstIndex(of: item) else { return }
        items.remove(at: index)
    }
    
    mutating func insert(_ element: ItemIdentifierType, before beforeElement: ItemIdentifierType) {
        items.insert(element, before: beforeElement)
    }
    
    mutating func insert(_ element: ItemIdentifierType, after afterElement: ItemIdentifierType) {
        items.insert(element, after: afterElement)
    }
    
}

public struct NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
    
    @available(iOS 13, *)
    internal func nsSnapshot() -> NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        snapshot.appendSections(sectionIdentifiers)
        sectionIdentifiers.forEach { (section) in
            snapshot.appendItems(itemIdentifiers(inSection: section), toSection: section)
        }
        snapshot.reloadSections(sectionsToReload)
        snapshot.reloadItems(itemsToReload)
        return snapshot
    }
    
    @available(iOS 13, *)
    init(_ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) {
        self.init()
        appendSections(snapshot.sectionIdentifiers)
        sectionIdentifiers.forEach { (section) in
            appendItems(snapshot.itemIdentifiers(inSection: section), toSection: section)
        }
    }
    
    public init() { }
    
    private var sections: NKOrderedSet<_NKDiffableDataSourceSnapshotSection<SectionIdentifierType, ItemIdentifierType>> = NKOrderedSet()
    
    public var numberOfItems: Int {
        return itemIdentifiers.count
    }

    public var numberOfSections: Int {
        return sectionIdentifiers.count
    }
    
    public var sectionIdentifiers: [SectionIdentifierType] {
        return sections.map { $0.identifier }
    }
    
    public var itemIdentifiers: [ItemIdentifierType] {
        return sections.flatMap { Array($0.items) }
    }
    
    public func numberOfItems(inSection identifier: SectionIdentifierType) -> Int {
        for section in sections {
            if section.identifier == identifier {
                return section.items.count
            }
        }
        return 0
    }
    
    public func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] {
        guard let items = sections.first(where: { $0.identifier == identifier})?.items else {
            return []
        }
        return Array(items)
    }
    
    public func sectionIdentifier(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? {
        for section in sections {
            if section.items.contains(identifier) {
                return section.identifier
            }
        }
        return nil
    }
    
    public func indexOfItem(_ identifier: ItemIdentifierType) -> Int? {
        guard let sectionIdentifier = self.sectionIdentifier(containingItem: identifier) else {
            return nil
        }
        
        for i in 0..<sections.count {
            if sections[i].identifier == sectionIdentifier {
                return sections[i].items.firstIndex(of: identifier)
            }
        }
        return nil
    }
    
    public func indexOfSection(_ identifier: SectionIdentifierType) -> Int? {
        return sectionIdentifiers.firstIndex(of: identifier)
    }
    
    mutating public func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType? = nil) {
        var alreadyPresent = 0
        
        defer {
            if alreadyPresent > 0 {
                NSLog("[NKDiffableDataSource] Warning: %ld inserted identifier(s) already present; existing items will be moved into place for this current insertion. Please note this will impact performance if items are not unique when inserted.", alreadyPresent)
            }
        }
        
        // No section was passed. Just add to the end
        guard let sectionIdentifier = sectionIdentifier else {
            guard sections.count > 0 else {
                fatalError("There are currently no sections in the data source. Please add a section first.")
            }
            
            identifiers.forEach {
                if itemIdentifiers.contains($0) {
                    alreadyPresent += 1
                    deleteItems([$0])
                }
                sections[sections.count - 1].append($0)
            }
            return
        }
        
        guard let index = sections.map({ $0.identifier }).firstIndex(of: sectionIdentifier) else {
            fatalError("Invalid parameter not satisfying: section != NSNotFound")
        }
        
        identifiers.forEach {
            if itemIdentifiers.contains($0) {
                alreadyPresent += 1
                deleteItems([$0])
            }
            sections[index].append($0)
        }
    }

    mutating public func insertItems(_ identifiers: [ItemIdentifierType], beforeItem beforeIdentifier: ItemIdentifierType) {
        guard let sectionIdentifier = self.sectionIdentifier(containingItem: beforeIdentifier) else {
            fatalError("Invalid parameter not satisfying: section != NSNotFound")
        }
        
        var alreadyPresent = 0
        
        defer {
            if alreadyPresent > 0 {
                NSLog("[NKDiffableDataSource] Warning: %ld inserted identifier(s) already present; existing items will be moved into place for this current insertion. Please note this will impact performance if items are not unique when inserted.", alreadyPresent)
            }
        }
        
        let index = sections.map { $0.identifier }.firstIndex(of: sectionIdentifier)!
        identifiers.forEach {
            if itemIdentifiers.contains($0) {
                alreadyPresent += 1
                deleteItems([$0])
            }
            sections[index].insert($0, before: beforeIdentifier)
        }
    }

    mutating public func insertItems(_ identifiers: [ItemIdentifierType], afterItem afterIdentifier: ItemIdentifierType) {
        guard let sectionIdentifier = self.sectionIdentifier(containingItem: afterIdentifier) else {
            fatalError("Invalid parameter not satisfying: section != NSNotFound")
        }
        
        var alreadyPresent = 0
        
        defer {
            if alreadyPresent > 0 {
                NSLog("[NKDiffableDataSource] Warning: %ld inserted identifier(s) already present; existing items will be moved into place for this current insertion. Please note this will impact performance if items are not unique when inserted.", alreadyPresent)
            }
        }
        
        let index = sections.map { $0.identifier }.firstIndex(of: sectionIdentifier)!
        identifiers.reversed().forEach {
            if itemIdentifiers.contains($0) {
                alreadyPresent += 1
                deleteItems([$0])
            }
            sections[index].insert($0, after: afterIdentifier)
        }
    }

    mutating public func deleteItems(_ identifiers: [ItemIdentifierType]) {
        identifiers.forEach {
            guard let sectionIdentifier = sectionIdentifier(containingItem: $0) else {
                return
            }
            sections[sections.map({ $0.identifier }).firstIndex(of: sectionIdentifier)!].remove($0)
        }
    }

    mutating public func deleteAllItems() {
        sections = NKOrderedSet()
    }

    mutating public func moveItem(_ identifier: ItemIdentifierType, beforeItem toIdentifier: ItemIdentifierType) {
        guard let fromSectionIdentifier = sectionIdentifier(containingItem: identifier) else {
            fatalError("Invalid parameter not satisfying: fromIndex != NSNotFound")
        }
        
        guard let toSectionIdentifier = sectionIdentifier(containingItem: toIdentifier) else {
            fatalError("Invalid parameter not satisfying: toIndex != NSNotFound")
        }
        
        let sectionIDs = sections.map { $0.identifier }
        
        let fromSectionIndex = sectionIDs.firstIndex(of: fromSectionIdentifier)!
        let toSectionIndex = sectionIDs.firstIndex(of: toSectionIdentifier)!
        
        sections[fromSectionIndex].remove(identifier)
        sections[toSectionIndex].insert(identifier, before: toIdentifier)
    }

    mutating public func moveItem(_ identifier: ItemIdentifierType, afterItem toIdentifier: ItemIdentifierType) {
        guard let fromSectionIdentifier = sectionIdentifier(containingItem: identifier) else {
            fatalError("Invalid parameter not satisfying: fromIndex != NSNotFound")
        }
        
        guard let toSectionIdentifier = sectionIdentifier(containingItem: toIdentifier) else {
            fatalError("Invalid parameter not satisfying: toIndex != NSNotFound")
        }
        
        let sectionIDs = sections.map { $0.identifier }
        
        let fromSectionIndex = sectionIDs.firstIndex(of: fromSectionIdentifier)!
        let toSectionIndex = sectionIDs.firstIndex(of: toSectionIdentifier)!
        
        sections[fromSectionIndex].remove(identifier)
        sections[toSectionIndex].insert(identifier, after: toIdentifier)
    }
    
    internal var sectionsToReload: [SectionIdentifierType] = []
    internal var itemsToReload: [ItemIdentifierType] = []
    
    mutating public func reloadItems(_ identifiers: [ItemIdentifierType]) {
        identifiers.forEach {
            guard itemIdentifiers.contains($0) else {
                fatalError("Invalid parameter not satisfying: indexPath || ignoreInvalidItems")
            }
            
            guard !itemsToReload.contains($0) else { return }            
            itemsToReload.append($0)
        }
    }

    mutating public func appendSections(_ identifiers: [SectionIdentifierType]) {
        identifiers.forEach {
            guard !sectionIdentifiers.contains($0) else {
                fatalError("Invalid parameter not satisfying: dataSourceSnapshot.numberOfSections == sectionIdentifiers.count")
            }
            sections.append(_NKDiffableDataSourceSnapshotSection($0))
        }
    }

    mutating public func insertSections(_ identifiers: [SectionIdentifierType], beforeSection toIdentifier: SectionIdentifierType) {
        guard let beforeSection = sections.first(where: { $0.identifier == toIdentifier }) else {
            fatalError("Invalid parameter not satisfying: insertIndex != NSNotFound")
        }
        
        identifiers.forEach {
            guard !sectionIdentifiers.contains($0) else {
                fatalError("Invalid parameter not satisfying: dataSourceSnapshot.numberOfSections == sectionIdentifiers.count")
            }
            sections.insert(_NKDiffableDataSourceSnapshotSection($0), before: beforeSection)
        }
    }
    
    mutating public func insertSections(_ identifiers: [SectionIdentifierType], afterSection toIdentifier: SectionIdentifierType) {
        guard let afterSection = sections.first(where: { $0.identifier == toIdentifier }) else {
            fatalError("Invalid parameter not satisfying: insertIndex != NSNotFound")
        }
        
        identifiers.reversed().forEach {
            guard !sectionIdentifiers.contains($0) else {
                fatalError("Invalid parameter not satisfying: dataSourceSnapshot.numberOfSections == sectionIdentifiers.count")
            }
            sections.insert(_NKDiffableDataSourceSnapshotSection($0), after: afterSection)
        }
    }
    
    mutating public func deleteSections(_ identifiers: [SectionIdentifierType]) {
        identifiers.forEach { (identifierToRemove) in
            guard let index = sections.map({ $0.identifier }).firstIndex(of: identifierToRemove) else {
                return
            }
            sections.remove(at: index)
        }
    }

    mutating public func moveSection(_ identifier: SectionIdentifierType, beforeSection toIdentifier: SectionIdentifierType) {
        guard let fromIndex = sections.map({ $0.identifier }).firstIndex(of: identifier) else {
            fatalError("Invalid parameter not satisfying: fromSection != NSNotFound")
        }
        
        guard let toIndex = sections.map({ $0.identifier }).firstIndex(of: toIdentifier) else {
            fatalError("Invalid parameter not satisfying: toSection != NSNotFound")
        }
        
        sections.move(from: fromIndex, to: fromIndex >= toIndex ? toIndex : toIndex - 1)
    }

    mutating public func moveSection(_ identifier: SectionIdentifierType, afterSection toIdentifier: SectionIdentifierType) {
        guard let fromIndex = sections.map({ $0.identifier }).firstIndex(of: identifier) else {
            fatalError("Invalid parameter not satisfying: fromSection != NSNotFound")
        }
        
        guard let toIndex = sections.map({ $0.identifier }).firstIndex(of: toIdentifier) else {
            fatalError("Invalid parameter not satisfying: toSection != NSNotFound")
        }
        
        sections.move(from: fromIndex, to: fromIndex <= toIndex ? toIndex : toIndex + 1)
    }
    
    mutating public func reloadSections(_ identifiers: [SectionIdentifierType]) {
        identifiers.forEach {
            guard sectionIdentifiers.contains($0) else {
                fatalError("Invalid parameter not satisfying: indexPath || ignoreInvalidItems")
            }
            
            guard !sectionsToReload.contains($0) else { return }
            sectionsToReload.append($0)
        }
    }
    
}

internal extension NKDiffableDataSourceSnapshot {
    
    func difference(from oldSnapshot: NKDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) -> [NKDiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType>] {
        var differences: [NKDiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType>] = []
        switch (numberOfSections, oldSnapshot.numberOfSections) {
        case (0, 0):
            return []
        case (0, _):
            for i in 0..<oldSnapshot.numberOfSections {
                let section = oldSnapshot.sectionIdentifiers[i]
                for j in 0..<oldSnapshot.numberOfItems(inSection: section) {
                    let item = oldSnapshot.itemIdentifiers(inSection: section)[j]
                    differences.append(.itemDelete(section, item))
                }
                differences.append(.sectionDelete(section))
            }
        case (_, 0):
            for i in 0..<numberOfSections {
                let section = sectionIdentifiers[i]
                differences.append(.sectionInsert(section))
                for j in 0..<numberOfItems(inSection: section) {
                    let item = itemIdentifiers(inSection: section)[j]
                    differences.append(.itemInsert(section, item))
                }
            }
        case (_, _):
            var deletedSections: [Int] = []
            var insertedSections: [Int] = []
            
            let sectionDiff = oldSnapshot.sectionIdentifiers.nkDifference(from: sectionIdentifiers)
            
            for section in sectionDiff.removed {
                deletedSections.append(oldSnapshot.indexOfSection(section)!)
                differences.append(.sectionDelete(section))
            }
            
            for section in sectionDiff.inserted {
                insertedSections.append(indexOfSection(section)!)
                differences.append(.sectionInsert(section))
            }
            
            for section in sectionDiff.common {
                if let newIndex = indexOfSection(section.0), let oldIndex = oldSnapshot.indexOfSection(section.0), newIndex != oldIndex {
                    let diff = insertedSections.filter { $0 < newIndex }.count - deletedSections.filter { $0 < oldIndex }.count
                    if newIndex - oldIndex != diff {
                        differences.append(.sectionMove(section.0))
                    }
                }
                
                var deletedItems: [Int] = []
                var insertedItems: [Int] = []
                
                let itemDiff = oldSnapshot.itemIdentifiers(inSection: section.0).nkDifference(from: itemIdentifiers(inSection: section.0))
                
                for item in itemDiff.removed {
                    deletedItems.append(oldSnapshot.indexOfItem(item)!)
                    if !itemIdentifiers.contains(item) {
                        differences.append(.itemDelete(section.0, item))
                    }
                    else {
                        differences.append(.itemMove(section.0, sectionIdentifier(containingItem: item)!, item))
                    }
                }
                
                for item in itemDiff.inserted {
                    insertedItems.append(indexOfItem(item)!)
                    if oldSnapshot.sectionIdentifier(containingItem: item) == nil {
                        differences.append(.itemInsert(section.0, item))
                    }
                }
                
                for item in itemDiff.common {
                    if let newIndex = indexOfItem(item.0), let oldIndex = oldSnapshot.indexOfItem(item.0), newIndex != oldIndex {
                        let diff = insertedItems.filter { $0 < newIndex }.count - deletedItems.filter { $0 < oldIndex }.count
                        if newIndex - oldIndex != diff {
                            differences.append(.itemMove(section.0, section.0, item.0))
                        }
                    }
                }
            }
        }
        
        sectionsToReload.forEach { (section) in
            if oldSnapshot.sectionIdentifiers.contains(section) {
                differences.append(.sectionReload(section))
            }
        }
        
        itemsToReload.forEach { (item) in
            if oldSnapshot.itemIdentifiers.contains(item) {
                differences.append(.itemReload(item))
            }
        }
        
        return differences
    }
    
}

internal enum NKDiffableDataSourceSnapshotDifference<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {
    
    case sectionDelete(SectionIdentifierType)
    case sectionInsert(SectionIdentifierType)
    case sectionMove(SectionIdentifierType)
    case sectionReload(SectionIdentifierType)
    
    case itemDelete(SectionIdentifierType, ItemIdentifierType)
    case itemInsert(SectionIdentifierType, ItemIdentifierType)
    case itemMove(SectionIdentifierType, SectionIdentifierType, ItemIdentifierType)
    case itemReload(ItemIdentifierType)
    
}

private extension Array where Iterator.Element: Hashable {

    init(_ orderedSet: NKOrderedSet<Iterator.Element>) {
        self = orderedSet.map { $0 }
    }
    
}

public struct NKArrayDifference<T> where T: Hashable {
    let common: [(T, T)]
    let removed: [T]
    let inserted: [T]
    init(common: [(T, T)] = [], removed: [T] = [], inserted: [T] = []) {
        self.common = common
        self.removed = removed
        self.inserted = inserted
    }
}

public extension Array where Iterator.Element: Hashable {
    
    func nkDifference(from other: [Iterator.Element]) -> NKArrayDifference<Iterator.Element> {
        let combinations = compactMap { firstElement in (firstElement, other.first { secondElement in firstElement == secondElement }) }
        let (common, removed): ([(Iterator.Element, Iterator.Element)], [Iterator.Element]) = combinations.reduce(into: ([], [])) { (result, combination) in
            if combination.1 != nil { result.0.append((combination.0, combination.1!)) }
            else { result.1.append(combination.0) }
        }
        let inserted = other.filter { secondElement in !common.contains { $0.0 == secondElement } }
        return NKArrayDifference(common: common, removed: removed, inserted: inserted)
    }
    
    func nkDifferenceOld(from other: [Iterator.Element]) -> NKArrayDifference<Iterator.Element> {
        let combinations = compactMap { firstElement in (firstElement, other.first { secondElement in firstElement == secondElement }) }
        let common = combinations.filter { $0.1 != nil }.compactMap { ($0.0, $0.1!) }
        let removed = combinations.filter { $0.1 == nil }.compactMap { ($0.0) }
        let inserted = other.filter { secondElement in !common.contains { $0.0 == secondElement } }
        return NKArrayDifference(common: common, removed: removed, inserted: inserted)
    }
    
    
}
