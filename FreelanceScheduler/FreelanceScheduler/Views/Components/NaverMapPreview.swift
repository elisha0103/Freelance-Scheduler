import SwiftUI
import NMapsMap

struct NaverMapPreview: UIViewRepresentable {
    let latitude: Double
    let longitude: Double
    let markerTitle: String

    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView(frame: .zero)
        mapView.showCompass = false
        mapView.showZoomControls = false
        mapView.showScaleBar = false
        mapView.showLocationButton = false
        mapView.mapView.isScrollGestureEnabled = false
        mapView.mapView.isZoomGestureEnabled = false
        mapView.mapView.isRotateGestureEnabled = false
        mapView.mapView.isTiltGestureEnabled = false

        let coord = NMGLatLng(lat: latitude, lng: longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
        mapView.mapView.moveCamera(cameraUpdate)

        let marker = NMFMarker()
        marker.position = coord
        marker.captionText = markerTitle
        marker.mapView = mapView.mapView

        return mapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        let coord = NMGLatLng(lat: latitude, lng: longitude)
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord, zoomTo: 15)
        uiView.mapView.moveCamera(cameraUpdate)
    }
}
