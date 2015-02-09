import Foundation
import UIKit

/**
The possible states a PhotoRecord could be in.

@author Julian Builes
*/
enum PhotoRecordState {
  case New, Downloaded, Filtered, Failed
}

/**
Represents a photo entry with all its necessary meta-data.

@author Julian Builes
*/
class PhotoRecord {
  let name: String
  let url: NSURL
  var state = PhotoRecordState.New
  var image = UIImage(named: "Placeholder")
  
  init(name: String, url: NSURL) {
    self.name = name
    self.url = url
  }
}
