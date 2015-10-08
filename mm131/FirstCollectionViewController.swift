//
//  PhotoBrowserCollectionViewController.swift
//  1000meitu
//
//  Created by lu on 15/8/24.


import Foundation
import UIKit
import Alamofire
import Kanna
import JGProgressHUD

class FisrstCollectionViewCell: UICollectionViewCell {
    // request stored for cancellation and checking the original URLString
    var request: Alamofire.Request?
    
    //image是直接连接到storyboard上的
    var imageView = UIImageView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.frame = bounds
        imageView.contentMode = UIViewContentMode.ScaleAspectFit

    }
}

class FirstCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, TopMenuDelegate{
    
    //top menu，类似网易新闻客户端
    var menuView:ZNTopMenuView!

    /*====================*/
    var photos = NSMutableOrderedSet()
    
    //给cell定义名称，在cell的属性上也要定义为同一个名称
    let CellIdentifier = "Cell"
    var populatingPhotos = false //是否在获取图片
    var currentPage = 1 //当前页数
    var currentType: PageType = .qingchun
    let refreshControl = UIRefreshControl() //下拉刷新
    var isGot = false   //标志是否已经获取到数据
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //让界面显示1秒
        NSThread.sleepForTimeInterval(0.5)
        configureRefresh()

        //初始化滑动栏
        initTop()
        
        //设置视图
        setupView()
        
        //添加所有的按钮
//        addBarItem()
        
        //获取第一页图片
        populatePhotos()
//        self.collectionView?.header.beginRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    
    /*!
    case qingchun = "qingchun" //1
    case xiaohua  = "xiaohua"  //2
    case chemo    = "chemo"    //3
    case qipao    = "qipao"    //4
    case mingxing = "mingxing" //5
    case xinggan  = "xinggan" //6
    */

    //设置下拉和上啦刷新
    func configureRefresh(){
        self.collectionView?.header = MJRefreshNormalHeader(refreshingBlock: { () in
            print("header")
            self.handleRefresh()
            self.collectionView?.header.endRefreshing()
        })
  
        self.collectionView?.footer = MJRefreshAutoFooter(refreshingBlock:
            { () in
            print("footer")
            self.populatePhotos()
            self.collectionView?.footer.endRefreshing()
        })
    }

    //设置顶部滑动栏
    func initTop(){
        let navBarHeight = self.navigationController?.navigationBar.frame.height ?? 0.0
        
        //设置menu的高度和位置，在navigationbar下面
        let menuView = ZNTopMenuView(frame: CGRectMake(0, navBarHeight + 20, kScreenSize.width, MENU_HEIGHT))
        menuView.bgColor = UIColor.grayColor()
        
        menuView.delegate = self
        //设置显示的类别
        menuView.titles = ["清纯美眉", "美女校花","性感车模","旗袍美女","明星写真","性感美女"]
        //关闭scrolltotop，不然点击status bar不会返回第一页
        menuView.setScrollToTop(false)
        self.menuView = menuView
        self.view.addSubview(menuView)
    }
    
    //MARK: - TopMenuDelegate 代理方法，点击触发
    func topMenuDidChangedToIndex(index:Int){
        self.navigationItem.title = self.menuView.titles[index] as String

        currentType = PhotoUtil.selectTypeByNumber(index)
        //切换类别时要置位isLast

        photos.removeAllObjects()
        //清除所有图片，设置为第一页，刷新数据
        self.currentPage = 1
        
        self.collectionView?.reloadData()
        
        populatePhotos()//开始获取图片url，由于不是自己搭建的服务器，所以只能抓取HTML进行解析
    }
    
    
    func setupView() {
        //设置标题
        self.navigationItem.title = self.menuView.titles[0] as String
        
        self.collectionView?.scrollsToTop = true
        
        //设置flowlayout
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.size.width/3, height: (view.bounds.size.width/3)/120.0*160.0)
        layout.headerReferenceSize = CGSize(width: self.view.frame.width, height: 25)
        collectionView!.collectionViewLayout = layout
        self.collectionView!.registerClass(FisrstCollectionViewCell.self, forCellWithReuseIdentifier: CellIdentifier)
    }
    
    override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return true
    }
    
    //添加navigationitem
    func addBarItem(){
        let item = UIBarButtonItem(image: UIImage(named: "Del"), style: UIBarButtonItemStyle.Plain, target: self, action: "setting:")
        item.tintColor = UIColor.whiteColor()

        self.navigationItem.rightBarButtonItem = item
    }
    
    @IBAction func setting(sender: AnyObject){
        let alert = UIAlertController(title: "提示", message: "确认要清除图片缓存么?", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: clearCache)
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //清除缓存
    func clearCache(alert: UIAlertAction!){
        
        print("clear")
        let size = SDImageCache.sharedImageCache().getSize() / 1000 //KB
        var string: String
        if size/1000 >= 1{
            string = "清除缓存 \(size/1000)M"
        }else{
            string = "清除缓存 \(size)K"
        }
        let hud = JGProgressHUD(style: JGProgressHUDStyle.Light)
        hud.textLabel.text = string
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.showInView(self.view, animated: true)
        SDImageCache.sharedImageCache().clearDisk()
        hud.dismissAfterDelay(1.0, animated: true)
    }
    
    //下拉刷新回调函数
    func handleRefresh() {
        photos.removeAllObjects()
//        清除所有图片，设置为第一页，刷新数据
        self.currentPage = 1
        self.collectionView?.reloadData()
        
        populatePhotos()//开始获取图片
    }
    
    //检查forum url，必须符合某种规则，http://www.mm131.com/qingchun/
    func checkForumUrl(forumUrl: String?)->Bool{
        if forumUrl == nil{
            return false
        }
        
        if  !forumUrl!.componentsSeparatedByString(Router.PhotoPage(currentType, currentPage).pageSource).isEmpty{
            let array = forumUrl!.componentsSeparatedByString(Router.PhotoPage(currentType, currentPage).pageSource)
            if array.count > 1 && !array[1].isEmpty{
                return true
            }
        }
        
        return false
    }
    
    //检查image url，必须符合某种规则，img1.mm131.com/pic
    func checkImageUrl(imageUrl: String?)->Bool{
        if imageUrl == nil{
            return false
        }

        if !imageUrl!.componentsSeparatedByString(PhotoUtil.imageSource).isEmpty{
            let array = imageUrl!.componentsSeparatedByString(PhotoUtil.imageSource)
            if array.count > 1 && !array[1].isEmpty{
                return true
            }
        }

        return false
    }
    
    //获取信息
    func populatePhotos(){
        if populatingPhotos{//正在获取，则返回
            print("return back")
            return
        }
        
        //标记正在获取，其他线程获取则返回
        populatingPhotos = true
        let pageUrl = Router.PhotoPage(currentType, currentPage).URLRequest
        Alamofire.request(.GET, pageUrl).validate().responseString{
            (request, response, result) in

            //
            let isSuccess = result.isSuccess
            let html = result.value
            let hud = JGProgressHUD(style: JGProgressHUDStyle.Light)
            if isSuccess == true{
                //设置等待菊花
                
                hud.textLabel.text = "加载中"
                hud.showInView(self.view, animated: true)
                hud.dismissAfterDelay(1.0, animated: true)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    //用photos保存临时数据
                    var photos = [PhotoInfo]()
                    //用kanna解析html数据
                    if let doc = Kanna.HTML(html: html!, encoding: NSUTF8StringEncoding){
                        CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingASCII)
                        let lastItem = self.photos.count
                        //解析imageurl
                        for node in doc.css("img"){
                            if self.checkImageUrl(node["src"]){
                                var temp = PhotoInfo()
                                temp.imageUrl = node["src"]!
                                photos.append(temp)
                                self.isGot = true
                            }
                        }
                
                        //解析forumurl
                        var index = 0
                        for node in doc.css("a"){
                            if index >= photos.count{
                                break
                            }
                            if self.checkForumUrl(node["href"]){
                                photos[index++].forumUrl = node["href"]!
                            }
                        }
                
                        //怕没有获取到数据，做了个保护
                        if self.isGot{
                            self.photos.addObjectsFromArray(photos)
                        }
                
                        //只刷新增加的数据，不能用reloadData，会造成闪屏
                        let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                        }
                        if self.isGot{
                            self.currentPage++
                            self.isGot = false
                        }
                    }
                }
            }else{
                let hud = JGProgressHUD(style: JGProgressHUDStyle.Light)
                hud.textLabel.text = "网络有问题，请检查网络"
                hud.indicatorView = JGProgressHUDErrorIndicatorView()
                hud.showInView(self.view, animated: true)
                hud.dismissAfterDelay(1.0, animated: true)
            }

            //清除HUD
            hud.dismiss()
            self.populatingPhotos = false
        }
    }
    
    //点击显示大图
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("BrowserPhoto", sender: (self.photos.objectAtIndex(indexPath.item) as! PhotoInfo))
    }
    
    //给browser页面设置数据
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "BrowserPhoto"{
            let temp = segue.destinationViewController as! PhotoBrowserCollectionViewController
            temp.photoInfo = sender as! PhotoInfo
            temp.currentType = self.currentType
        }
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.collectionView?.footer.hidden = self.photos.count == 0
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! FisrstCollectionViewCell
        
        let imageURL = NSURL(string: (photos.objectAtIndex(indexPath.row) as! PhotoInfo).imageUrl)
        //复用时先置为nil，使其不显示原有图片
        cell.imageView.image = nil

        //用sdwebimage更加的方便，集成了cache，弃用原来的。。
        cell.imageView.sd_setImageWithURL(imageURL)
        
        return cell
    }
}