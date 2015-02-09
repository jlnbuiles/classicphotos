import UIKit
import CoreImage

let dataSourceURL = NSURL(string: "http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")

class ListViewController: UITableViewController {
  
  var photos = [PhotoRecord]()
  let downloadOperations = PendingOperations(name: "download operations")
  let filterOperations = PendingOperations(name: "filter operations")
  
  // MARK: - view life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.title = "Classic Photos"
    fetchPhotoDetails()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - UITableViewDataSource
  
  override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func tableView(tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
      let cell = tableView.dequeueReusableCellWithIdentifier("CellIdentifier",
        forIndexPath: indexPath) as UITableViewCell
    
      if cell.accessoryView == nil {
        cell.accessoryView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
      }
      
      let indicator = cell.accessoryView as UIActivityIndicatorView
      
      let photoDetails = photos[indexPath.row]
      
      cell.textLabel?.text = photoDetails.name
      cell.imageView?.image = photoDetails.image
      
      switch (photoDetails.state) {
      case .Filtered:
        indicator.stopAnimating()
      case .Failed:
        indicator.stopAnimating()
        cell.textLabel?.text = "Failed to load"
      case .New, .Downloaded:
        indicator.startAnimating()
        
        // only start operations if tv is not scrolling
        if (!tableView.dragging && !tableView.decelerating) {
          startOperationsForPhotoRecord(photoDetails, indexPath: indexPath)
        }
      }
      return cell
  }
  
  // MARK: - UIScrollViewDelegate
  
  override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    suspendAllOperations(true)
  }
  
  override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      loadImagesForOnscreenCells()
    suspendAllOperations(false)
    }
  }
  
  override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    loadImagesForOnscreenCells()
    suspendAllOperations(false)
  }
  
  // MARK: - instance methods
  
  func fetchPhotoDetails() {
    
    let request = NSURLRequest(URL: dataSourceURL!)
    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    
    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
      response, data, error in
      
      if data != nil {
        let datasourceDictionary = NSPropertyListSerialization.propertyListFromData(data,
          mutabilityOption: .Immutable, format: nil, errorDescription: nil) as NSDictionary
        
        for(key : AnyObject,value : AnyObject) in datasourceDictionary {
          let name = key as? String
          let url = NSURL(string: value as? String ?? "")
          
          if name != nil && url != nil {
            let photoRecord = PhotoRecord(name: name!, url: url!)
            self.photos.append(photoRecord)
          }
        }
        
        self.tableView.reloadData()
      }
      
      if error != nil {
        let alert = UIAlertView(title: "Oops!", message: error.localizedDescription,
          delegate: nil, cancelButtonTitle: "OK")
        alert.show()
      }
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
  }
  
  func startOperationsForPhotoRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath) {
    switch (photoDetails.state) {
    case .New:
      startOperationForPhotoRecord(photoDetails, indexPath: indexPath, pendingOperations: downloadOperations)
    case .Downloaded:
      startOperationForPhotoRecord(photoDetails, indexPath: indexPath, pendingOperations: filterOperations)
    default:
      NSLog("do nothing")
    }
  }
  
  func startOperationForPhotoRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath,
    pendingOperations: PendingOperations) {
    
    if let operation = pendingOperations.inProgress[indexPath] {
      return
    }
     
    // only good for 2 types of pending operations. could use factory pattern if more types were introduced
    let operation = pendingOperations === self.downloadOperations ?
      ImageDownloadOperation(photoRecord: photoDetails) : ImageFilterOperation(photoRecord: photoDetails)
    
    operation.completionBlock = {
      if operation.cancelled {
        return
      }
      dispatch_async(dispatch_get_main_queue(), {
        pendingOperations.inProgress.removeValueForKey(indexPath)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      })
    }
    
    pendingOperations.inProgress[indexPath] = operation
    pendingOperations.queue.addOperation(operation)
  }
  
  func suspendAllOperations(suspend: Bool) {
    filterOperations.queue.suspended = suspend
    downloadOperations.queue.suspended = suspend
  }
  
  func loadImagesForOnscreenCells () {

    if let pathsArray = tableView.indexPathsForVisibleRows() {

      let allPendingOperations = NSMutableSet(array: downloadOperations.inProgress.keys.array)
      allPendingOperations.addObjectsFromArray(filterOperations.inProgress.keys.array)
      
      let toBeCancelled = allPendingOperations.mutableCopy() as NSMutableSet
      let visiblePaths = NSSet(array: pathsArray)
      toBeCancelled.minusSet(visiblePaths)
      
      let toBeStarted = visiblePaths.mutableCopy() as NSMutableSet
      toBeStarted.minusSet(allPendingOperations)
      
      for indexPath in toBeCancelled {
        let indexPath = indexPath as NSIndexPath
        if let pendingDownload = downloadOperations.inProgress[indexPath] {
          pendingDownload.cancel()
        }
        downloadOperations.inProgress.removeValueForKey(indexPath)
        if let pendingFiltration = filterOperations.inProgress[indexPath] {
          pendingFiltration.cancel()
        }
        filterOperations.inProgress.removeValueForKey(indexPath)
      }
      
      for indexPath in toBeStarted {
        let indexPath = indexPath as NSIndexPath
        let recordToProcess = self.photos[indexPath.row]
        startOperationsForPhotoRecord(recordToProcess, indexPath: indexPath)
      }
    }
  }
}
