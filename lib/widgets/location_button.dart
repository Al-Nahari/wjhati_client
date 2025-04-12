import 'package:flutter/material.dart';

Widget buildLocationButton(Function toggleExpanded, bool isExpanded,BuildContext context) {
  return Positioned(
    bottom: 170,
    right: 16,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isExpanded)
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: () {
              Navigator.pushNamed(context, '/TripTracking');
            },
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
        const SizedBox(height: 10),
        if (isExpanded)
          FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              Navigator.pushNamed(context, '/Complaint');
            },
            child: const Icon(Icons.map, color: Colors.white),
          ),
        const SizedBox(height: 10),
        if (isExpanded)
          FloatingActionButton(
            backgroundColor: Colors.orange,
            onPressed: () {
              Navigator.pushNamed(context, '/Wallet');
            },
            child: const Icon(Icons.wallet, color: Colors.white),
          ),
        const SizedBox(height: 10),
        FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () {
            toggleExpanded();
          },
          child: Icon(
            isExpanded ? Icons.close : Icons.add,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
