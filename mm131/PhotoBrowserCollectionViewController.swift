//
//  PhotoBrowserCollectionViewController.swift
//  1000meitu
//
//  Created by lu on 15/8/24.


import Foundation
import UIKit
import Alamofire
import Kanna
import Photos
import JGProgressHUD
//import WebImage

class CustomPhotoAlbum {
    
    static let albumName = "xxxx"
    static let sharedInstance = CustomPhotoAlbum()
    
    var assetCollection: PHAssetCollection!
    
    init() {
        
        func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", CustomPhotoAlbum.albumName)
            let collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
            
            if let firstObject: AnyObject = collection.firstObject {
                return collection.firstObject as! PHAssetCollection
            }
            
            return nil
        }
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(CustomPhotoAlbum.albumName)
            }) { success, _ in
                if success {
                    self.assetCollection = fetchAssetCollectionForAlbum()
                }
        }
    }
    
    func saveImage(image: UIImage) {
        
        if assetCollection == nil {
            return   // If there was an error upstream, skip the save.
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
            let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection)
//            albumChangeRequest!.addAssets([assetPlaceholder])
//            albumChangeRequest?.addAssets(self)
            }, completionHandler: nil)
    }
    
    
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
    // request stored for cancellation and checking the original URLString
    var request: Alamofire.Request?
    
    //image是直接连接到storyboard上的
    var imageView :UIImageView = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.frame = bounds
        imageView.contentMode = .ScaleAspectFit
    }
}


class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate{
    
    var photos = NSMutableOrderedSet()
    
    //给cell定义名称，在cell的属性上也要定义为同一个名称
    let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    var populatingPhotos = false //是否在获取图片
    var currentPage = 1 //当前页数
    var currentType: PageType = .qingchun //默认的type为qingchun
    var forumId: Int = 0 //forum id
    var currentImage = UIImage() //保存当前的图片，方便保存到相册中
    var photoInfo: PhotoInfo = PhotoInfo() //保存图片信息
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
        setupView()
        populatePhotos()

    }
    
    //获取到这个forum的id，比如http://www.mm131.com/xiaohua/2001.html的forumid为2001
    func initData(){
        forumId = getForumId()
    }
    
    func setupView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        collectionView!.pagingEnabled = true
        collectionView!.directionalLockEnabled = true
        collectionView!.collectionViewLayout = layout
        self.collectionView!.registerClass(PhotoBrowserCollectionViewCell.self, forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        //添加下载baritem
        addButtomBar()
        
        //注册点击事件，隐藏/出现navigationbar和toolbar
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.collectionView!.addGestureRecognizer(tapRecognizer)
        //为了消除载入时候竖直方向上的位移
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    func handleTap(recognizer: UITapGestureRecognizer!) {
        let state = self.navigationController?.navigationBarHidden
        self.navigationController?.setNavigationBarHidden(!state!, animated: true)
        self.navigationController?.setToolbarHidden(!state!, animated: true)
    }
    
    func addButtomBar() {
        var items = [UIBarButtonItem]()
        
        //填充空白
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        items.append(flexibleSpace)
        //只有这样图片才不会显示为纯蓝色
        var image = UIImage(named: "Download")
        image = image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        let downloadItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: "saveToCustomAlbum")
        downloadItem.tintColor = UIColor.whiteColor()
        items.append(downloadItem)
        items.append(flexibleSpace)

        self.setToolbarItems(items, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    //设置HUD
    func loadTextHUD(text: String, time: Float){
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Text
        loadingNotification.minShowTime = time
        loadingNotification.labelText = text
    }
    
    //
    func saveToCustomAlbum(){

        saveToAlbum()
//        loadTextHUD("保存成功", time: 0.3)
//        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    
    //保存图片到相册
    func saveToAlbum(){
        UIImageWriteToSavedPhotosAlbum(self.currentImage, nil, "image:didFinishSavingWithError:contextInfo", nil)
        let hud = JGProgressHUD(style: JGProgressHUDStyle.Light)
        hud.textLabel.text = "保存成功"
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.showInView(self.view, animated: true)
        hud.dismissAfterDelay(1.0, animated: true)
//        loadTextHUD("保存成功", time: 1)
//        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    func image(image: UIImage, didFinishSavingWithError error: NSError, contextInfo:UnsafePointer<Void>)       {
        print("in")
    }
//    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
//        print("in")
//        if error != nil {
//            print("保存失败")
//            return
//        }
//        print("保存成功")
//    }

    //获取forumid
    func getForumId()->Int{
        if !photoInfo.forumUrl.componentsSeparatedByString(Router.PhotoPage(currentType, 0).pageSource).isEmpty{
            let array = photoInfo.forumUrl.componentsSeparatedByString(Router.PhotoPage(currentType, 0).pageSource)
            let temp = array[1].componentsSeparatedByString(".html")
            return Int(temp[0])!
        }
        
        return 0 //invalid
    }
    
    //滑动页面出发的操作，collectionview实现UIScrollViewDelegate
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        //当页面向右滑动时获取下一张图片
        if scrollView.contentSize.width - scrollView.contentOffset.x < view.frame.width * 0.95{
            populatePhotos()
        }
    }
    
    //组装页面的url
    func getPageUrl()->String{
        var url = Router.PhotoPage(currentType, currentPage).pageSource + "\(forumId)"
        if currentPage > 1{
            url += "_" + "\(currentPage)" + ".html"
        }else{
            url += ".html"
        }
        
        return url
    }
    
    //对获取到的图片进行筛选
    func checkImageUrl(imageUrl: String?)->Bool{
        if imageUrl == nil{
            return false
        }
        
        if !imageUrl!.componentsSeparatedByString("\(forumId)").isEmpty{
            let array = imageUrl!.componentsSeparatedByString("\(forumId)")
            if array.count > 1{
                return true
            }
        }
        
        return false
    }
    
    //获取图片
    func populatePhotos(){
        if populatingPhotos{//正在获取，则返回
            print("return back")
            return
        }
        
        populatingPhotos = true

        let pageUrl = getPageUrl()
        Alamofire.request(.GET, pageUrl).validate().responseString{
            (request, response, result) in
            let isSuccess = result.isSuccess
            let html = result.value
            if isSuccess == true{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    if let doc = Kanna.HTML(html: html!, encoding: NSUTF8StringEncoding){
                        CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingASCII)
                        let lastItem = self.photos.count
                        for node in doc.css("img"){
                            if self.checkImageUrl(node["src"]){
                                self.photos.addObject(node["src"]!)
                                break
                            }
                        }
                
                        let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                        }
                        self.currentPage++
                    }
                }
            }

            self.populatingPhotos = false
        }
    }
    
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    //左右间距
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(0)
    }
    
    //上下间距
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(0)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
        
        let imageURL = NSURL(string: photos.objectAtIndex(indexPath.row) as! String)
        
        //复用时先置为nil，使其不显示原有图片
        cell.imageView.image = nil
        //
        cell.request?.cancel()
        let HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
        HUD.textLabel.text = "加载中"
        HUD.showInView(self.view, animated: true)
        cell.imageView.sd_setImageWithURL(imageURL, completed: { (image, error, cacheType, url) -> Void in
            self.currentImage = image
            if indexPath.row + 2 >= self.currentPage{
                self.populatePhotos()
            }
            HUD.dismiss()
        })
        
        return cell
    }
}