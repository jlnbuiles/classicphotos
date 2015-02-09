import Foundation
import UIKit

/**
A base image operation. To be sublassed.

@author Julian Builes
*/
class ImageOperation: NSOperation {
  
  let photoRecord: PhotoRecord
  
  init(photoRecord: PhotoRecord) {
    self.photoRecord = photoRecord
  }
}