import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/parking_service.dart';
import '../../models/parking_spot.dart';

class ManageParkingScreen extends StatelessWidget {
  const ManageParkingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Parking Spots"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: provider.parkingSpots.length,
        itemBuilder: (context, index) {
          final spot = provider.parkingSpots[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.local_parking, color: Colors.blue),
              title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("\${spot.location}\n₹\${spot.carPrice.toInt()}/hr (Car) | ₹\${spot.bikePrice.toInt()}/hr (Bike)"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _showEditDialog(context, spot),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, spot),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, ParkingSpot spot) {
    final nameController = TextEditingController(text: spot.name);
    final locController = TextEditingController(text: spot.location);
    final carPriceController = TextEditingController(text: spot.carPrice.toString());
    final bikePriceController = TextEditingController(text: spot.bikePrice.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Parking Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: locController, decoration: const InputDecoration(labelText: "Location")),
              TextField(controller: carPriceController, decoration: const InputDecoration(labelText: "Car Price (₹/hr)"), keyboardType: TextInputType.number),
              TextField(controller: bikePriceController, decoration: const InputDecoration(labelText: "Bike Price (₹/hr)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ParkingService().updateParkingDetails(
                parkingId: spot.id,
                name: nameController.text,
                carPrice: double.parse(carPriceController.text),
                bikePrice: double.parse(bikePriceController.text),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spot updated successfully")));
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ParkingSpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Spot?"),
        content: Text("Are you sure you want to remove \${spot.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ParkingService().deleteParking(spot.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spot deleted")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
