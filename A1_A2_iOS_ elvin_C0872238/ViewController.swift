//
//  ViewController.swift
//  Lab Test 1-2
//
//  Created by Elvin Ross Fabella on 2023-01-20.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var showRoute: UIButton!
    
    var locationManager = CLLocationManager()
    var allowedAnnotations = 0
    var distanceLabel: [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initial setup of the map view
        showRoute.isHidden = true
        mapView.showsUserLocation = true
        //mapView.isZoomEnabled = false
        
        //initial setup of Location Manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //defined the gestures to be used
        let uitgr = UITapGestureRecognizer(target: self, action: #selector(addAnnotation))
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(removeAnnotation))
     
        //add the gestures to mapView
        mapView.addGestureRecognizer(uitgr)
        mapView.addGestureRecognizer(uilpgr)
        mapView.delegate = self
    }
    
        //MARK: show updating location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0]
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        displayLocation(latitude: latitude, longitude: longitude)
    }
    func displayLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        
        let latitudeDelta: CLLocationDegrees = 0.25
        let longitudeDelta: CLLocationDegrees = 0.25
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: add one tap Annotation
    @objc func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        
        allowedAnnotations = mapView.annotations.count
        
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                       
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: {(placemarks, error) in
            
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async {
                    if (placemarks?[0]) != nil {
                            if self.allowedAnnotations <= 3 {
                                switch self.allowedAnnotations{
                                case 0:
                                    let title = Annotation(title: "My Location", coordinate: coordinate)
                                    self.mapView.addAnnotation(title)
                                case 1:
                                    let title = Annotation(title: "A", coordinate: coordinate)
                                    self.mapView.addAnnotation(title)
                                case 2:
                                    let title = Annotation(title: "B", coordinate: coordinate)
                                    self.mapView.addAnnotation(title)
                                case 3:
                                    let title = Annotation(title: "C", coordinate: coordinate)
                                    self.mapView.addAnnotation(title)
                                default:
                                    return
                            }
                            if self.allowedAnnotations == 3 {
                                self.addPolyline()
                                self.addPolygon()
                            }
                        }
                    }
                }
            }
        })
      
    }
    
    //MARK: add Long Press to Remove Annotation
    @objc func removeAnnotation(point: UITapGestureRecognizer){
        let touchedPoint: CGPoint = point.location(in: mapView)
        let removeCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
        let removeLocation: CLLocationCoordinate2D = removeCoordinate
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: removeLocation.latitude, longitude: removeLocation.longitude), completionHandler:{ placemark, error in
            if error != nil {
                print(error!)
            }else {
                DispatchQueue.main.async{
                    if let placemark = placemark?[0] {
                        if placemark.locality != nil{
                            for annotation in self.mapView.annotations{
                                if annotation.title == placemark.locality{
                                    self.removeOverlays()
                                    self.mapView.removeAnnotation(annotation)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func removeOverlays() {
        showRoute.isHidden = true
        removeDistanceLabel()
        
        for polygon in mapView.overlays {
            mapView.removeOverlay(polygon)
        }
    }
    private func removeDistanceLabel() {
        for label in distanceLabel {
            label.removeFromSuperview()
        }
        distanceLabel = []
    }
    
    //MARK: Add Polyline to placemark
    func addPolyline() {
        showRoute.isHidden = false
        var annotations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for mapAnnotation in mapView.annotations[1...3] {
            annotations.append(mapAnnotation.coordinate)
        }
        
        let polyline = MKPolyline(coordinates: annotations, count: annotations.count)
        mapView.addOverlay(polyline, level: .aboveRoads)
        displayDistance()
    }
    
    func addPolygon() {
        var annotations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        for location in mapView.annotations{
            if location.title == "My Location" {
                continue
            }
            annotations.append(location.coordinate)
        }
        let polygon = MKPolygon(coordinates: annotations, count: annotations.count)
        mapView.addOverlay(polygon)
    }
    
    private func displayDistance() {
        var nextIndex = 1
        
        for index in 1...3{
            if index == 3 {
                nextIndex = 1
            } else {
                nextIndex = index + 1
            }

            let distance: Double = getDistance(start: mapView.annotations[index].coordinate, nextStop:  mapView.annotations[nextIndex].coordinate)
            
            let pointA: CGPoint = mapView.convert(mapView.annotations[index].coordinate, toPointTo: mapView)
            let pointB: CGPoint = mapView.convert(mapView.annotations[nextIndex].coordinate, toPointTo: mapView)
        
            let displayDistance = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 25))

            displayDistance.text = "\(String.init(format: "%2.f",  round(distance * 0.001))) km"
            displayDistance.textColor = .black
            displayDistance.backgroundColor = .white
            displayDistance.textAlignment = NSTextAlignment.center
            displayDistance.center = CGPoint(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
            distanceLabel.append(displayDistance)
        }
        for label in distanceLabel {
            mapView.addSubview(label)
        }
    }
    func getDistance(start: CLLocationCoordinate2D, nextStop: CLLocationCoordinate2D) -> CLLocationDistance {
        let start = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let nextStop = CLLocation(latitude: nextStop.latitude, longitude: nextStop.longitude)
        
        return start.distance(from: nextStop)
    }
    @IBAction func drawRoute(sender: UIButton) {
        mapView.removeOverlays(mapView.overlays)
        removeDistanceLabel()

        var nextIndex = 1
        for index in 1...3 {
            if index == 3 {
                nextIndex = 1
            } else {
                nextIndex = index + 1
            }
            
            let source = MKPlacemark(coordinate: mapView.annotations[index].coordinate)
            let destination = MKPlacemark(coordinate: mapView.annotations[nextIndex].coordinate)
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: source)
            directionRequest.destination = MKMapItem(placemark: destination)
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            directions.calculate(completionHandler: { (response, error) in
                guard let directionResponse = response else {
                    return
                }
    
                let route = directionResponse.routes[0]
                self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                
                let rect = route.polyline.boundingMapRect
                self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            })
        }
        
    }
    
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .green
            renderer.lineWidth = 5
            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = .red.withAlphaComponent(0.5)
            return renderer
        }
        return MKOverlayRenderer()
    }
    
}
