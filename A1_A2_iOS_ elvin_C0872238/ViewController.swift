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
    var cities:[Annotation] = [Annotation]()
    
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
        uitgr.numberOfTapsRequired = 1

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
    
    @objc func addAnnotation(sender: UITapGestureRecognizer) {
        
        let touchpoint = sender.location(in: mapView)
        let coordinate = mapView.convert(touchpoint, toCoordinateFrom: mapView)
        var cityMarker: String = ""
        allowedAnnotations = cities.count
        
        if allowedAnnotations > 1 {
            showRoute.isHidden = false
        }
        switch self.allowedAnnotations{
        case 0:
            cityMarker = "A"
        case 1:
            cityMarker = "B"
        case 2:
            cityMarker = "C"
        default:
            cityMarker = "A"

        }
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: {(placemarks, error) in
            
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async {
                    if let placeMark = placemarks?[0] {
                        
                        if placeMark.locality != nil {
                            let place = Annotation(title: cityMarker, subtitle: "", coordinate: coordinate)
                            
                            // Add up to 3 Annotations on the map
                            if self.allowedAnnotations <= 2 {
                                self.cities.append(place)
                                self.mapView.addAnnotation(place)
                            }
                            else {
                                self.removeOverlays()
                                self.mapView.removeAnnotations(self.mapView.annotations )
                                self.cities = []
                                self.distanceLabel = []
                                self.cities.append(place)
                                self.mapView.addAnnotation(place)
                            }

                            if self.allowedAnnotations == 2 {
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
    
    func addPolyline() {
        let coordinates = cities.map {$0.coordinate}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline, level: .aboveRoads)
        
        showDistanceBetweenTwoPoint()
    }
    
    func addPolygon() {
        let coordinates = cities.map {$0.coordinate}
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polygon)
    }
    private func showDistanceBetweenTwoPoint() {
        var nextIndex = 0
        
        for index in 0...2{
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }

            let distance: Double = getDistance(from: cities[index].coordinate, to:  cities[nextIndex].coordinate)
            
            let pointA: CGPoint = mapView.convert(cities[index].coordinate, toPointTo: mapView)
            let pointB: CGPoint = mapView.convert(cities[nextIndex].coordinate, toPointTo: mapView)
        
            let labelDistance = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 18))

            labelDistance.textAlignment = NSTextAlignment.center
            labelDistance.text = "\(String.init(format: "%2.f",  round(distance * 0.001)))km"
            labelDistance.textColor = .black
            labelDistance.font = UIFont(name: "Thonburi-Bold", size: 10.0)
            labelDistance.center = CGPoint(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
            
            distanceLabel.append(labelDistance)
        }
        for label in distanceLabel {
            mapView.addSubview(label)
        }
    }
    
    func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        return from.distance(from: to)
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

        var nextIndex = 0
        for index in 0...2 {
            if index == 2 {
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
