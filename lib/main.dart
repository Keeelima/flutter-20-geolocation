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

  Future<void> adicionarWaypoint() async {
    // Verifica se o GPS já forneceu uma posição válida.
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguardando posição GPS para cadastrar waypoint.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    String nome = '';

    // Abre o formulário e aguarda o nome informado.
    final String? name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo Waypoint'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Entrada principal',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome do waypoint.';
              }
              return null;
            },
            onSaved: (value) => nome = value!.trim(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                Navigator.pop(dialogContext, nome);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // O usuário pode ter cancelado o diálogo.
    if (name == null || !mounted) return;

    // Captura a posição mais recente disponível.
    final double? latitudeWaypoint = latitude;
    final double? longitudeWaypoint = longitude;

    if (latitudeWaypoint == null || longitudeWaypoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posição GPS indisponível.')),
      );
      return;
    }

    final novoWaypoint = Waypoint(
      name: name,
      latitude: latitudeWaypoint,
      longitude: longitudeWaypoint,
    );

    setState(() {
      waypoints.add(novoWaypoint);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Waypoint "$name" cadastrado.')));
  }

  void excluirWaypoint(Waypoint waypoint) {
    setState(() {
      waypoints.remove(waypoint);

      // Se o waypoint excluído estiver em navegação,
      // encerra a navegação automaticamente.
      if (identical(navegandoPara, waypoint)) {
        navegandoPara = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Waypoint "${waypoint.name}" excluído.'),
        duration: const Duration(seconds: 2),
      ),
    );
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
