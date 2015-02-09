import Foundation
import UIKit

/**
Responsible for downloading images.

A stock `Failed` image is utilized when a download attempt fails.

@author Julian Builes
*/
class ImageDownloadOperation: ImageOperation {
  
  override func main() {
    
    if self.cancelled {
      return
    }
    
    let imageData = NSData(contentsOfURL: self.photoRecord.url)
    
    if self.cancelled {
      return
    }
    
    if imageData?.length > 0 {
      self.photoRecord.image = UIImage(data: imageData!)
      self.photoRecord.state = .Downloaded
    } else {
      self.photoRecord.state = .Failed
      self.photoRecord.image = UIImage(named: "Failed")
    }
  }
}
