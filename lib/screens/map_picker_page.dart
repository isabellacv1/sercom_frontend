import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? selectedLocation;
  GoogleMapController? mapController;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        selectedLocation = const LatLng(4.7110, -74.0721); // Bogotá por defecto
        loading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        selectedLocation = const LatLng(4.7110, -74.0721);
        loading = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
      loading = false;
    });
  }

  Future<void> _confirmLocation() async {
    if (selectedLocation == null) return;

    String address = '';

    try {
      final placemarks = await placemarkFromCoordinates(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
      }
    } catch (_) {
      address = 'Ubicación seleccionada en el mapa';
    }

    Navigator.pop(context, {
      'address': address,
      'latitude': selectedLocation!.latitude,
      'longitude': selectedLocation!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading || selectedLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation!,
          zoom: 16,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          mapController = controller;
        },
        onTap: (LatLng position) {
          setState(() {
            selectedLocation = position;
          });
        },
        markers: {
          Marker(
            markerId: const MarkerId('selected-location'),
            position: selectedLocation!,
          ),
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _confirmLocation,
          child: const Text('Usar esta ubicación'),
        ),
      ),
    );
  }
}