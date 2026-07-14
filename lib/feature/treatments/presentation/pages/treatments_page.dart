import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Softbee/feature/beehive/presentation/providers/beehive_providers.dart';
import 'package:Softbee/feature/beehive/domain/entities/beehive.dart';
import 'package:Softbee/feature/treatments/presentation/widgets/hive_treatments_management_dialog.dart';

class TreatmentsPage extends ConsumerStatefulWidget {
  final String apiaryId;

  const TreatmentsPage({super.key, required this.apiaryId});

  @override
  ConsumerState<TreatmentsPage> createState() => _TreatmentsPageState();
}

class _TreatmentsPageState extends ConsumerState<TreatmentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(beehiveControllerProvider.notifier)
          .fetchBeehivesByApiary(widget.apiaryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final beehiveState = ref.watch(beehiveControllerProvider);
    final hivesRequiringTreatment = beehiveState.beehives
        .where((hive) => hive.treatments == true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tratamientos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: beehiveState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : hivesRequiringTreatment.isEmpty
              ? _buildEmptyState()
              : _buildHivesList(hivesRequiringTreatment),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 100,
              color: Colors.amber.shade100,
            ),
            const SizedBox(height: 20),
            Text(
              'No hay colmenas con tratamiento',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Solo se muestran aquí las colmenas que tienen activada la opción de tratamientos en su configuración.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHivesList(List<Beehive> hives) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hives.length,
      itemBuilder: (context, index) {
        final hive = hives[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: Icon(Icons.hive_rounded, color: Colors.amber.shade800),
            ),
            title: Text(
              'Colmena #${hive.beehiveNumber}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Salud: ${hive.healthStatus ?? 'N/A'}',
                  style: GoogleFonts.poppins(),
                ),
                Text(
                  'Actividad: ${hive.activityLevel ?? 'N/A'}',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => HiveTreatmentsManagementDialog(
                    hiveId: hive.id,
                    hiveNumber: hive.beehiveNumber ?? 0,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Gestionar'),
            ),
          ),
        );
      },
    );
  }
}
