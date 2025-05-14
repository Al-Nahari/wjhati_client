import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../services/AuthService.dart';
import '../services/ip.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final Color primaryColor = const Color(0xff2d4960);
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final headers = await AuthService.getAuthHeader();
      final userData = await AuthService.getUserData();
      final uri = Uri.parse('${ips.apiUrl}trips/').replace(
        queryParameters: {'user': userData['id'].toString()},
      );

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _trips = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timeout. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTrips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                onPressed: _fetchTrips,
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.travel_explore, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No trips available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchTrips,
              child: Text('Check again',
                  style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTrips,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailsScreen(tripData: trip, primaryColor: primaryColor),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapPreview(trip),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip #${trip['id']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          _getStatusText(trip['status'] ?? ''),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(trip['status'] ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTripInfoRow(
                      Icons.location_on, 'From:', trip['from_location']),
                  _buildTripInfoRow(
                      Icons.location_pin, 'To:', trip['to_location']),
                  _buildTripInfoRow(Icons.access_time, 'Departure:',
                      _formatDate(trip['departure_time'])),
                  _buildTripInfoRow(Icons.attach_money, 'Price:',
                      '${trip['price_per_seat']} SAR'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {},
                      child: const Text('View Details',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPreview(Map<String, dynamic> trip) {
    final startPoint = _parseLocation(trip['from_location']);
    final endPoint = _parseLocation(trip['to_location']);

    return SizedBox(
      height: 150,
      child: FlutterMap(
        options: MapOptions(
          center: startPoint,
          zoom: 10.0,
          interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: startPoint,
                width: 30,
                height: 30,
                builder: (ctx) => Icon(
                  Icons.location_pin,
                  color: primaryColor,
                  size: 30,
                ),
              ),
              Marker(
                point: endPoint,
                width: 30,
                height: 30,
                builder: (ctx) => const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: [startPoint, endPoint],
                color: primaryColor.withOpacity(0.7),
                strokeWidth: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'full':
        return 'Full';
      case 'in_progress':
        return 'In Progress';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'full':
        return Colors.orange;
      case 'in_progress':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  LatLng _parseLocation(String loc) {
    try {
      final coords = loc.split(',');
      return LatLng(
        double.parse(coords[0].trim()),
        double.parse(coords[1].trim()),
      );
    } catch (e) {
      return const LatLng(24.7136, 46.6753); // Default to Riyadh coordinates
    }
  }
}

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final Color primaryColor;

  const TripDetailsScreen({
    super.key,
    required this.tripData,
    required this.primaryColor,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  bool _isMapLoading = true;
  double _mapHeight = 300;
  bool _useOSRM = true; // Flag to switch between simple and OSRM routing

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _parseRouteCoordinates();
  }

  void _parseRouteCoordinates() async {
    try {
      final coords = widget.tripData['route_coordinates']?.toString() ?? '';

      if (coords.isNotEmpty) {
        // Use existing coordinates if available
        final parsed = jsonDecode(coords) as List;
        setState(() {
          _routePoints = parsed.map<LatLng>((point) {
            return LatLng(
              double.parse(point['lat'].toString()),
              double.parse(point['lng'].toString()),
            );
          }).toList();
          _isMapLoading = false;
        });
      } else if (_useOSRM) {
        // Fetch route from OSRM API if no coordinates available
        await _fetchOSRMRoute();
      } else {
        // Fallback to simple straight line
        final start = _parseLocation(widget.tripData['from_location']);
        final end = _parseLocation(widget.tripData['to_location']);
        setState(() {
          _routePoints = [start, end];
          _isMapLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _zoomToFitRoute();
      });
    } catch (e) {
      debugPrint('Error parsing route: $e');
      final start = _parseLocation(widget.tripData['from_location']);
      final end = _parseLocation(widget.tripData['to_location']);
      setState(() {
        _routePoints = [start, end];
        _isMapLoading = false;
      });
    }
  }

  Future<void> _fetchOSRMRoute() async {
    try {
      final start = _parseLocation(widget.tripData['from_location']);
      final end = _parseLocation(widget.tripData['to_location']);

      final uri = Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/'
              '${start.longitude},${start.latitude};'
              '${end.longitude},${end.latitude}?overview=full&geometries=geojson'
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          _routePoints = geometry.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
          _isMapLoading = false;
        });

        _zoomToFitRoute();
      } else {
        throw Exception('OSRM API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching OSRM route: $e');
      final start = _parseLocation(widget.tripData['from_location']);
      final end = _parseLocation(widget.tripData['to_location']);
      setState(() {
        _routePoints = [start, end];
        _isMapLoading = false;
      });
    }
  }

  void _zoomToFitRoute() {
    if (_routePoints.isNotEmpty ) {
      final bounds = LatLngBounds.fromPoints(_routePoints);
      _mapController.fitBounds(
        bounds,
        options: FitBoundsOptions(
          padding: const EdgeInsets.all(100),
          maxZoom: 15,
        ),
      );
    }
  }

  LatLng _parseLocation(String loc) {
    try {
      final coords = loc.split(',');
      return LatLng(
        double.parse(coords[0].trim()),
        double.parse(coords[1].trim()),
      );
    } catch (e) {
      return const LatLng(24.7136, 46.6753); // Default to Riyadh coordinates
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.tripData;
    final startPoint = _parseLocation(trip['from_location']);
    final endPoint = _parseLocation(trip['to_location']);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: _mapHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildMap(startPoint, endPoint),
                  ),
                  pinned: true,
                  backgroundColor: widget.primaryColor,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: () {
                        setState(() {
                          _mapHeight = _mapHeight == 300 ? 500 : 300;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(_useOSRM ? Icons.map : Icons.straight),
                      onPressed: () {
                        setState(() {
                          _useOSRM = !_useOSRM;
                          _isMapLoading = true;
                        });
                        _parseRouteCoordinates();
                      },
                      tooltip: 'Toggle Routing',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildTripDetails(trip),
                ),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng startPoint, LatLng endPoint) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: startPoint,
            zoom: 13.0,
            interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            onMapReady: _zoomToFitRoute,
            onPositionChanged: (MapPosition position, bool hasGesture) {
              // Handle map movement
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            if (!_isMapLoading && _routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: widget.primaryColor.withOpacity(0.7),
                    strokeWidth: 5,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            if (!_isMapLoading)
              MarkerLayer(
                markers: [
                  Marker(
                    point: startPoint,
                    width: 50,
                    height: 50,
                    builder: (ctx) => Icon(
                      Icons.location_pin,
                      color: widget.primaryColor,
                      size: 40,
                    ),
                  ),
                  Marker(
                    point: endPoint,
                    width: 50,
                    height: 50,
                    builder: (ctx) => const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  if (_routePoints.length > 2)
                    ..._routePoints
                        .sublist(1, _routePoints.length - 1)
                        .map((point) => Marker(
                      point: point,
                      width: 30,
                      height: 30,
                      builder: (ctx) => Icon(
                        Icons.location_on,
                        color: widget.primaryColor,
                        size: 30,
                      ),
                    ))
                        .toList(),
                ],
              ),
          ],
        ),
        if (_isMapLoading)
          const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'zoomIn',
                onPressed: () {

                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'zoomOut',
                onPressed: () {

                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails(Map<String, dynamic> trip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailCard('Departure', Icons.location_on, trip['from_location']),
          _buildDetailCard('Destination', Icons.location_pin, trip['to_location']),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildDetailChip(
                  Icons.access_time, 'Departure', _formatDate(trip['departure_time'])),
              _buildDetailChip(
                  Icons.airline_seat_recline_normal, 'Seats', '${trip['available_seats']}'),
              _buildDetailChip(
                  Icons.directions_car, 'Distance', '${trip['distance_km'] ?? 'N/A'} km'),
              _buildDetailChip(Icons.attach_money, 'Price',
                  '${trip['price_per_seat']} SAR per seat'),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusIndicator(trip['status'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: widget.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 18, color: widget.primaryColor),
      label: Text('$label: $value'),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildStatusIndicator(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
          ),
          const SizedBox(width: 12),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'full':
        return Icons.do_not_disturb;
      case 'in_progress':
        return Icons.directions_car;
      case 'completed':
        return Icons.verified;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.message, color: Colors.white),
              label: const Text('Contact Driver',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bookmark, color: Colors.white),
              label: const Text('Book Trip',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'full':
        return 'Full';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'full':
        return Colors.orange;
      case 'in_progress':
        return widget.primaryColor;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}