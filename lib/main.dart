import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_device_compass/flutter_device_compass.dart';

import 'package:flutter/material.dart';
import 'package:kgps_locator_kevinlima/models/waypoint.dart';
import 'package:kgps_locator_kevinlima/widgets/compass.dart';

void main() {
  runApp(const KGPSLocatorApp());
}

class KGPSLocatorApp extends StatelessWidget {
  const KGPSLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KGPS-Locator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // Dados fictícios para a Gaveta 2.
  double? latitude;
  double? longitude;
  double? altitude;
  double heading = 0.0;

  String gpsStatus = 'Aguardando GPS...';
  String compassStatus = 'Aguardando bússola...';

  StreamSubscription<Position>? gpsSubscription;
  StreamSubscription<CompassEvent>? compassSubscription;

  Waypoint? navegandoPara;

  final List<Waypoint> waypoints = [
    const Waypoint(name: 'WP001', latitude: -23.164281, longitude: -45.896756),
    const Waypoint(name: 'WP002', latitude: -23.189425, longitude: -46.026272),
    const Waypoint(name: 'WP003', latitude: -23.811881, longitude: -45.396372),
  ];

  void navegarPara(Waypoint waypoint) {
    debugPrint('Você acionou o Navegar para ${waypoint.name}');
    setState(() {
      navegandoPara = waypoint;
    });
  }

  void pararNavegacao() {
    if (navegandoPara != null) {
      debugPrint('Você parou o Navegar para ${navegandoPara!.name}');
    } else {
      debugPrint('Você tentou parar a navegação sem destino ativo');
    }

    setState(() {
      navegandoPara = null;
    });
  }

  void adicionarWaypoint() {
    debugPrint('Você clicou no botão Add Waypoint');
  }

  void excluirWaypoint(Waypoint waypoint) {
    debugPrint('Você acionou o excluir Waypoint ${waypoint.name}');
  }

  void iniciarGPS() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          gpsStatus = 'Ative a localização do dispositivo.';
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
          gpsStatus = 'Permissão de localização não concedida.';
        });
        return;
      }

      gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 1,
            ),
          ).listen(
            (Position position) {
              if (!mounted) return;
              setState(() {
                latitude = position.latitude;
                longitude = position.longitude;
                altitude = position.altitude;
                gpsStatus = 'GPS ativo';
              });
            },
            onError: (Object error) {
              if (!mounted) return;
              setState(() {
                gpsStatus = 'Erro ao obter localização.';
              });
              debugPrint('Erro GPS: $error');
            },
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        gpsStatus = 'Falha ao iniciar GPS.';
      });
      debugPrint('Falha GPS: $e');
    }
  }

  void iniciarBussola() {
    compassSubscription = FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (!mounted) return;
        if (event.heading == null) {
          setState(() {
            compassStatus = 'Sensor de bússola indisponível.';
          });
          return;
        }

        setState(() {
          heading = event.heading!;
          compassStatus = 'Bússola ativa';
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          compassStatus = 'Erro no sensor de bússola.';
        });
        debugPrint('Erro bússola: $error');
      },
    );

    if (compassSubscription == null) {
      setState(() {
        compassStatus = 'Sensor de bússola indisponível.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    iniciarGPS();
    iniciarBussola();
  }

  @override
  void dispose() {
    gpsSubscription?.cancel();
    compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KGPS-Locator')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Compass(heading: heading),
            const SizedBox(height: 8),
            Text(
              'Heading: ${heading ?? 0.0}°',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationInfo(),
            const SizedBox(height: 12),
            if (navegandoPara != null) _buildNavigationInfo(),
            const SizedBox(height: 8),
            Expanded(child: _buildWaypointList()),
          ],
        ),
      ),
      floatingActionButton: navegandoPara == null
          ? FloatingActionButton.extended(
              onPressed: pararNavegacao,
              icon: const Icon(Icons.stop),
              label: const Text('STOP'),
            )
          : null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: adicionarWaypoint,
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Add Waypoint'),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _infoRow(
                'Latitude',
                latitude != null ? latitude!.toStringAsFixed(6) : '--',
              ),
              _infoRow(
                'Longitude',
                longitude != null ? longitude!.toStringAsFixed(6) : '--',
              ),
              _infoRow(
                'Altitude',
                altitude != null ? '${altitude!.toStringAsFixed(1)} m' : '--',
              ),
              const SizedBox(height: 8),
              Text(gpsStatus, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(compassStatus, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }

  Widget _buildNavigationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text(
                'NAVEGANDO PARA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(navegandoPara!.name, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              const Text('Azimute: --°'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaypointList() {
    return ListView.builder(
      itemCount: waypoints.length,
      itemBuilder: (context, index) {
        final waypoint = waypoints[index];

        return Dismissible(
          key: ValueKey(waypoint.name),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, size: 30),
          ),
          onDismissed: (_) {
            excluirWaypoint(waypoint);
          },
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(waypoint.name),
            subtitle: Text(
              '${waypoint.latitude.toStringAsFixed(6)}, ${waypoint.longitude.toStringAsFixed(6)}',
            ),
            onLongPress: () {
              navegarPara(waypoint);
            },
          ),
        );
      },
    );
  }
}
