//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Boutheina Bouchahda on 4/22/18.
//  Copyright © 2018 Boutheina Bouchahda. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    // MARK: - Properties
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
    }
    
    // MARK: - Actions
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Did fail with error: \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("Did update locations: \(newLocation)")
        
        // 1
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        // 2
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        // 3
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
            // 5
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                print("*** We're done!")
                stopLocationManager()
                configureGetButton()
            }
            
            // 6
            if !performingReverseGeocoding {
                print("*** going to geocode")
                performingReverseGeocoding = true
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: {(placemarks, error) in
                    print("*** found placemarks: \(String(describing: placemarks)), error: \(String(describing: error))")
                })
            }
        }
        
        location = newLocation
        updateLabels()
        lastLocationError = nil
    }
    
    // MARK: - Methods
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func updateLabels() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
           
            let statusMessage: String
            if let error = lastLocationError as NSError? {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    /**
     Starts the location manager
     */
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    /**
     Updates the button for getting the location to indicate whether the location search is done or not
     **/
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: UIControl.State.normal)
        } else {
            getButton.setTitle("Get My Location", for: UIControl.State.normal)
        }
    }

}

