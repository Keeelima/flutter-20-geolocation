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
  double latitude = -23.2048746;
  double longitude = -46.1559800;
  double altitude = 760.0;
  double heading = 45.0;

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
              'Heading: ${heading.toStringAsFixed(1)}°',
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
              Text('Latitude: ${latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${longitude.toStringAsFixed(6)}'),
              Text('Altitude: ${altitude.toStringAsFixed(1)} m'),
            ],
          ),
        ),
      ),
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
