import 'package:flutter/material.dart';
import 'package:untitled5/main.dart';
import '../models/location.dart';
Widget buildTopNavigation(
    BuildContext context,
    TextEditingController destinationController,
    List<Location> searchSuggestions,
    Function(Location) onDestinationSelected,
    Function(String) searchLocations,
    ) {
  return SafeArea(
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MyApp.textLight,
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
                    prefixIcon: Icon(Icons.search, color: MyApp.primry),
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
                  backgroundColor: MyApp.primry,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: MyApp.textLight),
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
              color: MyApp.textLight,
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
  );
}
