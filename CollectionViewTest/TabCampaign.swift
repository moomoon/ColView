//
//  TabCampaign.swift
//  kaipai2
//
//  Created by Jia Jing on 8/19/15.
//  Copyright (c) 2015 Yang Yi. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa



private let dummyCampaigns: [CampaignItem] = {
    var c: [CampaignItem] = []
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/lx7XpwX9hXX5uW3P3stjjjldWYqbDvJBUwWuFvSP.jpg", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/2969025c7468f410.jpg", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/dc5d4e24d515a5be.jpg", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/5bd5f5dbfe950e01.jpg", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/Bt3CrGIggKSAh98d0mXbNpdsslyXbJisiFB2Pai1.jpg", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/FomFowgPznrq5CCgjDIMT0J8OPv23z7gCBvXuSR8.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/Df3l1pf8uDiN1cwF8UQ0T1rskUS13GAmJ4HAqTvS.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/AseftWmprTrJVFrTe5kDdCVwXthwiDp7noloj6sJ.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/zLGrG6V2vyhAiNzy1v920vILvJybI4cwAXc4TdVe.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/Df3l1pf8uDiN1cwF8UQ0T1rskUS13GAmJ4HAqTvS.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/AseftWmprTrJVFrTe5kDdCVwXthwiDp7noloj6sJ.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/zLGrG6V2vyhAiNzy1v920vILvJybI4cwAXc4TdVe.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/Df3l1pf8uDiN1cwF8UQ0T1rskUS13GAmJ4HAqTvS.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/AseftWmprTrJVFrTe5kDdCVwXthwiDp7noloj6sJ.png", longDescription: "longDescription"))
    c.append(CampaignItem(title: "ccc", bgURL:"http://ac-ynhgmmfe.clouddn.com/zLGrG6V2vyhAiNzy1v920vILvJybI4cwAXc4TdVe.png", longDescription: "longDescription"))

    return c
}()


class TabCampaignController : UIViewController {
    
    let dataSource = CampaignDataSource()
    @IBOutlet weak var cvTemplate: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = cvTemplate.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5)
//        layout.itemSize = CGSizeZero
        layout.estimatedItemSize = CGSizeMake(150, 80)
        dataSource.segments = [CampaignSegmentDataSource(), TemplateSegmentDataSource()]
        dataSource.isRefreshed.producer |> filter { $0 } |> start(next: {[unowned self] _ in self.cvTemplate.reloadData()})
        cvTemplate.dataSource = dataSource
        sendNext(dataSource.refreshControlPipe.1, ())
        
    }
    
}

protocol DataRefreshable {
    var isRefreshed: PropertyOf<Bool> { get }
    func bindRefreshControl(signal: Signal<(), NoError>)// -> Disposable?
}

typealias SegmentDataSource = protocol<UICollectionViewDataSource, DataRefreshable>

class CampaignSegmentDataSource : NSObject, SegmentDataSource {
    private let isRefreshedProp = MutableProperty(false)
    var isRefreshed: PropertyOf<Bool> { return PropertyOf(isRefreshedProp) }
    private var campaigns: [CampaignItem] = []
    
    func bindRefreshControl(signal: Signal<(), NoError>)// -> Disposable?
    {
        //return
    signal.observe(next: { [unowned self] in self.doRefresh() })
    }
    
    private func doRefresh(){
        isRefreshedProp.put(false)
        campaigns = dummyCampaigns
        isRefreshedProp.put(true)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return campaigns.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("campaignCell", forIndexPath: indexPath) as! CampaignCell
        cell.bindParent(collectionView)
        let item = campaigns[indexPath.row]
        cell.setup(item)
        return cell
    }
}

struct CampaignItem {
    let title: String
    let bgURL: String
    let longDescription: String
}

class CampaignCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private var parentBounds: () -> CGSize = { CGSizeZero }
    private var sectionInsec: () -> UIEdgeInsets = { UIEdgeInsetsZero }
    private var inited = false
    
    func bindParent(parent: UICollectionView){
        let layout = parent.collectionViewLayout as! UICollectionViewFlowLayout
        parentBounds = { [unowned parent] in parent.bounds.size }
        sectionInsec = { [unowned layout] in layout.sectionInset }
        inited = true
    }
    
    
    func setup(item: CampaignItem){
        label.text = item.title
        imageView.setImageWithUrl(NSURL(string: item.bgURL)!, placeHolderImage: nil)
    }
    
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes! {
        let insect = sectionInsec()
        let parentWidth = parentBounds().width
        layoutAttributes.size.width = parentWidth - insect.left - insect.right
        layoutAttributes.frame.origin.x = 0
        return layoutAttributes
    }
}



class TemplateCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    

    
    func setup(item: TemplateItem){
        label.text = item.title
    }
    
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes! {
        return layoutAttributes
    }
    
}

class CampaignDataSource : NSObject, SegmentDataSource {
    private let isRefreshedProp = MutableProperty(false)
    var isRefreshed: PropertyOf<Bool> { return PropertyOf(isRefreshedProp) }
    private let refreshControlPipe = Signal<(), NoError>.pipe()
    var segments: [SegmentDataSource] = [] { didSet { self.setupRefreshControl() } }
    
    private func setupRefreshControl(){
        if segments.count == 0 { return }
        isRefreshedProp <~ segments.reduceIfAny({ $0.isRefreshed.producer }){ merged, next in
            merged |> mergeWith(next.isRefreshed.producer |> combineLatestWith, &)}!
        for seg in segments {
            seg.bindRefreshControl(refreshControlPipe.0)
        }
    }
    
    
    func bindRefreshControl(signal: Signal<(), NoError>) {
        signal.observe(refreshControlPipe.1)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return segments[section].collectionView(collectionView, numberOfItemsInSection: 0)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return segments.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return segments[indexPath.section].collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
}

