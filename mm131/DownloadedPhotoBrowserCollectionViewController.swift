//
//  DownloadedPhotoBrowserCollectionViewController.swift
//  1000meitu
//
//  Created by lu on 15/8/27.
//  Copyright (c) 2015年 lu. All rights reserved.
//

import UIKit

class DownloadedPhotoBrowserCollectionViewController: UICollectionViewController {
    var downloadedPhotoURLs: [NSURL]?
    let DownloadedPhotoBrowserCellIdentifier = "DownloadedPhotoBrowserCell"
    
    // MARK: Life-Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.size.width, height: 200.0)
        
        collectionView!.collectionViewLayout = layout
        
        collectionView!.registerClass(DownloadedPhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: DownloadedPhotoBrowserCellIdentifier)
        
        navigationItem.title = "已下载"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
            var error: NSError?
//            println("directory = \(directoryURL)")
            let urls = NSFileManager.defaultManager().contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: nil, options: nil, error: &error)
            
            if error == nil {
                downloadedPhotoURLs = urls as? [NSURL]

//                println("durls = \(downloadedPhotoURLs)")
                collectionView!.reloadData()
            }
        }
    }
    
    // MARK: CollectionView
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return downloadedPhotoURLs?.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(DownloadedPhotoBrowserCellIdentifier, forIndexPath: indexPath) as! DownloadedPhotoBrowserCollectionViewCell
        
        let localFileData = NSFileManager.defaultManager().contentsAtPath(downloadedPhotoURLs![indexPath.row].path!)
        
        let image = UIImage(data: localFileData!, scale: UIScreen.mainScreen().scale)
        
        cell.imageView.image = image
        
        return cell
    }
}

class DownloadedPhotoBrowserCollectionViewCell: UICollectionViewCell {
    let imageView = UIImageView()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        imageView.frame = bounds
        imageView.contentMode = .ScaleAspectFit
    }
}