import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var center: CLLocationCoordinate2D
    var region: MKCoordinateRegion
    
    var overlay: WMSTileOverlay

    override func viewDidLoad() {
        super.viewDidLoad()

        self.getCardfromGeoserver()
        
        self.recentreMap()
        mapView.mapType = MKMapType.Hybrid
        mapView.setRegion(region, animated: false)
        self.mapView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        self.center = CLLocationCoordinate2D(latitude: 51.0000000, longitude: 10.0000000)
        self.region = MKCoordinateRegion(center: self.center, span: MKCoordinateSpan(latitudeDelta: 10.01, longitudeDelta: 10.01))
        
        self.overlay = WMSTileOverlay(urlArg: "", useMercatorArg: true)
        
        super.init(coder: aDecoder)
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay:
        MKOverlay) -> MKOverlayRenderer {
            
            if overlay is MKTileOverlay {
                let renderer = MKTileOverlayRenderer(overlay:overlay)
                renderer.alpha = (overlay as! WMSTileOverlay).alpha
                return renderer
            }
            return MKPolylineRenderer()
    }

    // Warnung ueber Geoserver holen
    func getCardfromGeoserver() {
        let url = "https://__GEOSERVER__?LAYERS=__LAYER__&STYLES=&SERVICE=WMS&VERSION=1.3&REQUEST=GetMap&SRS=EPSG:900913&width=256&height=256&format=image/png8&transparent=true"
            
        self.recentreMap()
        self.mapView.removeOverlay(overlay)
        overlay = WMSTileOverlay(urlArg: url, useMercatorArg: true)
        
        overlay.canReplaceMapContent = false
        //Set the overlay transparency
        overlay.alpha = 0.7
        //Add the overlay
        self.mapView.addOverlay(overlay)
    }

    func recentreMap() {
        
        let centre = CLLocationCoordinate2D(latitude: 51.0000000,
            longitude: 10.0000000)
        
        let span = MKCoordinateSpan(latitudeDelta: 10.01,
            longitudeDelta: 10.01)
        
        let region = MKCoordinateRegion(center: centre, span: span)
        self.mapView.setRegion(region, animated: false)
        self.mapView.regionThatFits(region)
    }

}

