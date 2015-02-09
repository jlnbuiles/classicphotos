import Foundation
import UIKit

class PendingOperations {

  var queue: NSOperationQueue
  lazy var inProgress = [NSIndexPath:NSOperation]()
  
  init(name: NSString) {
    queue = {
      var queue = NSOperationQueue()
      queue.name = name
      queue.maxConcurrentOperationCount = 1
      return queue
      }()
  }
}
