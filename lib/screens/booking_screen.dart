import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  double _calculatePrice(double ratePerHour) {
    int startMinutes = _startTime.hour * 60 + _startTime.minute;
    int endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    // Handle overnight or same-time
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; 
    }
    
    double durationHours = (endMinutes - startMinutes) / 60.0;
    return durationHours * ratePerHour;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final spot = provider.selectedSpot;
    final slot = provider.selectedSlot;

    if (spot == null || slot == null) {
      return const Scaffold(body: Center(child: Text("Missing selection info")));
    }

    final double rate = provider.selectedVehicleType == "Car" 
        ? spot.carPrice 
        : spot.bikePrice;
    
    final double totalPrice = _calculatePrice(rate);

    // Calculate duration string
    int startMinutes = _startTime.hour * 60 + _startTime.minute;
    int endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) endMinutes += 24 * 60;
    int diff = endMinutes - startMinutes;
    String durationStr = "${diff ~/ 60}h ${diff % 60}m";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Booking Confirmation",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow("Parking", spot.name),
                  const SizedBox(height: 15),
                  _summaryRow("Location", spot.location),
                  const SizedBox(height: 15),
                  _summaryRow("Slot ID", "Slot ${slot.name}", isHighlight: true),
                  const Divider(height: 40),
                  
                  _summaryRow("Vehicle", provider.selectedVehicleType),
                  const SizedBox(height: 15),
                  _summaryRow("Date", DateFormat('MMM dd, yyyy').format(DateTime.now())),
                  const Divider(height: 40),

                  const Text(
                    "Set Time",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _timePickerBox("Start", _startTime.format(context), () => _selectTime(context, true)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _timePickerBox("End", _endTime.format(context), () => _selectTime(context, false)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _summaryRow("Duration", durationStr),

                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Price",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "₹${totalPrice.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                onPressed: () {
                  // Prepare date times for today
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
                  var end = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
                  if (end.isBefore(start)) {
                    end = end.add(const Duration(days: 1));
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        amount: totalPrice,
                        startTime: start,
                        endTime: end,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F3D56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  "Proceed to Payment",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF3F3D56) : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _timePickerBox(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.access_time, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
