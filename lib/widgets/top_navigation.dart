import 'package:flutter/material.dart';
import '../models/location.dart';

Widget buildTopNavigation(
    BuildContext context,
    TextEditingController destinationController,
    List<Location> searchSuggestions,
    Function(Location) onDestinationSelected,
    Function(String) searchLocations,
    ) {
  return Positioned(
    top: 40,
    left: 16,
    right: 16,
    child: SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      hintText: 'إلى أين؟',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.black87),
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) {
                      searchLocations(value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Builder(
                builder: (context) {
                  return CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black87),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          if (searchSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchSuggestions.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(searchSuggestions[index].name),
                  onTap: () => onDestinationSelected(searchSuggestions[index]),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
