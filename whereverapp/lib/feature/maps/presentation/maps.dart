import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // 1. Import package geolocator
import 'package:latlong2/latlong.dart';
import 'package:whereverapp/auth.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final Supabase supabase = Supabase();
  List<Marker> markers = [];
  Timer? timer;
  LatLng? myPosition;

  // 2. Tambahkan MapController untuk mengontrol peta secara programatik
  final MapController _mapController = MapController();
  // 3. State untuk menyimpan posisi pengguna saat ini
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    // _listenToLocation();
    _getCurrentLocationOnce();
    // Panggil fungsi untuk mendapatkan lokasi saat widget pertama kali dibuat
    _getCurrentLocationAndCenterMap();
    fetchMarkers(); // pertama kali load
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchMarkers());
  }

  @override
  void dispose() {
    timer?.cancel();
    _mapController.dispose(); // Jangan lupa dispose controller
    super.dispose();
  }

  Future<void> _listenToLocation() async {
    // Minta izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // update tiap 10 meter
        ),
      ).listen((Position pos) {
        setState(() {
          myPosition = LatLng(pos.latitude, pos.longitude);
          debugPrint("Posisi baru: $myPosition");
          markers.removeWhere(
            (m) => m.child is Icon && (m.child as Icon).color == Colors.red,
          );
          markers.add(
            Marker(
              point: myPosition!,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          );
        });

        supabase.updatePos(
          "Admin",
          myPosition!.latitude,
          myPosition!.longitude,
        );
      });
    }
  }

  Future<void> _getCurrentLocationOnce() async {
    // 1. Bagian pengecekan izin tetap sama dan penting
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Tampilkan pesan jika layanan lokasi mati
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan lokasi dinonaktifkan. Mohon aktifkan.'),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Tampilkan pesan jika izin ditolak
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Tampilkan pesan jika izin ditolak permanen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen.')),
        );
      }
      return;
    }

    // 2. Mengambil lokasi saat ini HANYA SEKALI
    try {
      // Menggunakan 'await' untuk menunggu hasil satu kali
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Update state setelah mendapatkan posisi
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        supabase.addPos(position.latitude, position.longitude, "Admin");
        debugPrint("Posisi didapat: $_currentPosition");
      });

      // Opsional: Langsung pindahkan kamera peta ke lokasi pengguna
      _mapController.move(_currentPosition!, 15.0);
    } catch (e) {
      debugPrint("Gagal mendapatkan lokasi: $e");
    }
  }

  // 4. Fungsi baru untuk menangani logika lokasi
  Future<void> _getCurrentLocationAndCenterMap() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Layanan lokasi dinonaktifkan. Mohon aktifkan layanan lokasi.',
          ),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin lokasi ditolak secara permanen, kami tidak dapat meminta izin.',
          ),
        ),
      );
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        // Pindahkan peta ke lokasi pengguna
        _mapController.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  Future<void> fetchMarkers() async {
    try {
      final List<dynamic> result = await supabase.getPos();
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        result,
      );

      if (data.isEmpty) return;

      final List<Marker> newMarkers = data.map((item) {
        final lat = (item['lat'] as num).toDouble();
        final lng = (item['lng'] as num).toDouble();

        return Marker(
          point: LatLng(lat, lng),
          width: 80,
          height: 80,
          child: Tooltip(
            // Tambahkan Tooltip untuk menampilkan ID saat ditekan lama
            message: "ID: ${item['id']}",
            child: Text("📍 ${item["name"]}", style: TextStyle(fontSize: 25)),
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          markers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint("Error fetchMarkers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Map with Supabase Markers")),
      body: FlutterMap(
        // 5. Hubungkan MapController ke FlutterMap
        mapController: _mapController,
        options: MapOptions(
          // initialCenter bisa diatur ke lokasi default sebelum lokasi pengguna didapat
          initialCenter: LatLng(-6.200000, 106.816666), // Default ke Jakarta
          initialZoom: 10,
        ),
        children: [
          TileLayer(
            // 1. Ganti URL dengan format yang benar menggunakan {z}/{x}/{y}
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            // 2. Tambahkan subdomains untuk performa yang lebih baik
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.whereverapp',
          ),
          MarkerLayer(
            // 6. Gabungkan markers dari Supabase dengan marker lokasi pengguna
            markers: [
              ...markers, // marker dari Supabase
              if (_currentPosition !=
                  null) // Tampilkan jika lokasi sudah didapat
                Marker(
                  point: _currentPosition!,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
      // 7. Tombol untuk kembali ke lokasi pengguna saat ini
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocationAndCenterMap,
        tooltip: 'Lokasi Saya',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
