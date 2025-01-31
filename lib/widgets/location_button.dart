import 'package:flutter/material.dart';

Widget buildLocationButton(Function toggleExpanded, bool isExpanded) {
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
              print("الزر الأول");
            },
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
        const SizedBox(height: 10),
        if (isExpanded)
          FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              print("الزر الثاني");
            },
            child: const Icon(Icons.map, color: Colors.white),
          ),
        const SizedBox(height: 10),
        if (isExpanded)
          FloatingActionButton(
            backgroundColor: Colors.orange,
            onPressed: () {
              print("الزر الثالث");
            },
            child: const Icon(Icons.settings, color: Colors.white),
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
