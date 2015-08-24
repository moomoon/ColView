//
//  CellDataSource.swift
//  CollectionViewTest
//
//  Created by Jia Jing on 8/21/15.
//  Copyright (c) 2015 Jia Jing. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa


private let dummyTemplates: [TemplateItem] = {
    var t: [TemplateItem] = []
    t.append(TemplateItem(title: "买买买"))
    t.append(TemplateItem(title: "每日一look"))
    t.append(TemplateItem(title: "汪汪汪"))
    return t }()


protocol CellDataSource {
    typealias CellType: UICollectionViewCell
    static var identifier: String { get }
    func bind(cell: CellType)
}

class UICollectionViewDataSourceWrapper: NSObject, UICollectionViewDataSource {
    final func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return swift_collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
    
    final func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return swift_collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    final func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        return swift_collectionView(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
    }
    
    final func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return swift_numberOfSectionsInCollectionView(collectionView)
    }
    
    func swift_numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func swift_collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        fatalError("not implemented")
    }
    
    func swift_collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fatalError("not implemented")
    }
    
    func swift_collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        fatalError("not implemented")
    }
}

class SimpleDataSource<T: CellDataSource> : UICollectionViewDataSourceWrapper, DataRefreshable {
    private let isRefreshedProp = MutableProperty(false)
    var isRefreshed: PropertyOf<Bool> { return PropertyOf(isRefreshedProp) }
    let cellData = MutableProperty<[T]>([])
    
    func bindRefreshControl(signal: Signal<(), NoError>) {
        isRefreshedProp <~ signal |> map{ _ in false }
    }
    
    override func swift_collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(T.identifier, forIndexPath: indexPath) as! T.CellType
        let data = cellData.value[indexPath.row]
        data.bind(cell)
        return cell
    }
    
    override func swift_collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellData.value.count
    }
    
    
}


protocol SimpleDataSourceDelegate {
    typealias CellDataType : CellDataSource
    static func loadData() -> [CellDataType]
}

func delegate<T, D: SimpleDataSourceDelegate where D.CellDataType == T>(dataSource: SimpleDataSource<T>, delegateType: D.Type) {
    dataSource.cellData <~ dataSource.isRefreshed.producer |> filter { !$0 } |> map{ _ in delegateType.loadData() }
}


class TemplateSegmentDataSource : NSObject, SegmentDataSource {
    private let isRefreshedProp = MutableProperty(false)
    var isRefreshed: PropertyOf<Bool> { return PropertyOf(isRefreshedProp) }
    private var templates: [TemplateItem] = []
    
    
    func bindRefreshControl(signal: Signal<(), NoError>) {
        signal.observe(next: { [unowned self] in self.doRefresh() })
    }
    private func doRefresh(){
        isRefreshedProp.put(false)
        templates = dummyTemplates
        isRefreshedProp.put(true)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return templates.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("templateCell", forIndexPath: indexPath) as! TemplateCell
        let item = templates[indexPath.row]
        cell.setup(item)
        return cell
    }
    
    
}

struct TemplateItem {
    let title: String
}
