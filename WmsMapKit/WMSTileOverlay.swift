import Foundation
import MapKit

extension String {
    
    func stringByAppendingPathComponent(path: String) -> String {
        
        let nsSt = self as NSString
        
        return nsSt.stringByAppendingPathComponent(path)
    }
}

class WMSTileOverlay: MKTileOverlay {
    
    var url: String
    var useMercator: Bool
    var alpha: CGFloat = 1.0
    
    init(urlArg: String, useMercatorArg: Bool) {
        self.url = urlArg
        self.useMercator = useMercatorArg
        super.init(URLTemplate: url)
    }
    
    
    // MapViewUtils
    
    let TILE_SIZE = 256.0
    let MINIMUM_ZOOM = 0
    let MAXIMUM_ZOOM = 25
    let TILE_CACHE = "TILE_CACHE"
    
    func tileZ(zoomScale: MKZoomScale) -> Int {
        let numTilesAt1_0 = MKMapSizeWorld.width / TILE_SIZE
        let zoomLevelAt1_0 = log2(Float(numTilesAt1_0))
        let zoomLevel = max(0, zoomLevelAt1_0 + floor(log2f(Float(zoomScale)) + 0.5))
        return Int(zoomLevel)
    }
    
    func xOfColumn(column: Int, zoom: Int) -> Double {
        let x = Double(column)
        let z = Double(zoom)
        return x / pow(2.0, z) * 360.0 - 180
    }
    
    func yOfRow(row: Int, zoom: Int) -> Double {
        let y = Double(row)
        let z = Double(zoom)
        let n = M_PI - 2.0 * M_PI * y / pow(2.0, z)
        return 180.0 / M_PI * atan(0.5 * (exp(n) - exp(-n)))
    }
    
    func mercatorXofLongitude(lon: Double) -> Double {
        return lon * 20037508.34 / 180
    }
    
    func mercatorYofLatitude(lat: Double) -> Double {
        var y = log(tan((90 + lat) * M_PI / 360)) / (M_PI / 180)
        y = y * 20037508.34 / 180
        return y
    }
    
    func md5Hash(stringData: NSString) -> NSString {
        let str = stringData.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CUnsignedInt(stringData.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        CC_MD5(str, strLen, result)
        
        let hash = NSMutableString()
        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.dealloc(digestLen)
        
        return String(format: hash as String)
    }
    
    func createPathIfNecessary(path: String) -> Bool {
        var succeeded = true
        let fm = NSFileManager.defaultManager()
        if(!fm.fileExistsAtPath(path)) {
            do {
                try fm.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
                succeeded = true
            } catch _ {
                succeeded = false
            }
        }
        return succeeded
    }
    
    func cachePathWithName(name: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let cachesPath: String = paths as String
        let cachePath = name.stringByAppendingPathComponent(cachesPath)
        createPathIfNecessary(cachesPath)
        createPathIfNecessary(cachePath)
        
        return cachePath
    }
    
    
    func getFilePathForURL(url: NSURL, folderName: String) -> String {
        return cachePathWithName(folderName).stringByAppendingPathComponent(md5Hash("\(url)") as String)
    }
    
    func cacheUrlToLocalFolder(url: NSURL, data: NSData, folderName: String) {
        let localFilePath = getFilePathForURL(url, folderName: folderName)
        data.writeToFile(localFilePath, atomically: true)
    }
    
    // MapViewUtils END ************
    
    
    func urlForTilePath(path: MKTileOverlayPath) -> NSURL {
        var left   = xOfColumn(path.x, zoom: path.z) // minX
        var right  = xOfColumn(path.x+1, zoom: path.z) // maxX
        var bottom = yOfRow(path.y+1, zoom: path.z) // minY
        var top    = yOfRow(path.y, zoom: path.z) // maxY
        
        if self.useMercator {
            left   = mercatorXofLongitude(left) // minX
            right  = mercatorXofLongitude(right) // maxX
            bottom = mercatorYofLatitude(bottom) // minY
            top    = mercatorYofLatitude(top) // maxY
        }
        
        let resolvedUrl = "\(self.url)&BBOX=\(left),\(bottom),\(right),\(top)"
        
        return NSURL(string: resolvedUrl)!
    }
    
    override func loadTileAtPath(path: MKTileOverlayPath, result: ((NSData?, NSError?) -> Void)) {
        let url1 = self.urlForTilePath(path)
        let filePath = getFilePathForURL(url1, folderName: TILE_CACHE)
        let file = NSFileManager.defaultManager()
        if file.fileExistsAtPath(filePath) {
            let tileData = try? NSData(contentsOfFile: filePath, options: .DataReadingMappedIfSafe)
            result(tileData, nil)
        }
        else {
            let request = NSMutableURLRequest(URL: url1)
            request.HTTPMethod = "GET"
            
            let session = NSURLSession.sharedSession()
            session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
                
                if error != nil {
                    print("Error downloading tile")
                    result(nil, error)
                }
                else {
                    data!.writeToFile(filePath, atomically: true)
                    result(data, nil)
                }
            }).resume()

        }
    }
    
    
}
