import 'dart:io';

import 'package:assignmentsubhasish/screens/login_screen.dart';
import 'package:assignmentsubhasish/screens/route_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  final String email;

  const ProfileScreen({super.key, required this.email});
  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(LoadProfile(email));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutUser());
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is ProfileLoaded) {
            final user = state.userData;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: user['image'] != null &&
                                    user['image'].isNotEmpty
                                ? (user['image'].startsWith('http')
                                    ? NetworkImage(user['image']) // For URLs
                                    : FileImage(File(user['image']))
                                        as ImageProvider) // For local files
                                : null,
                            backgroundColor: Colors.grey[200],
                            child:
                                user['image'] == null || user['image'].isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Handle avatar editing
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Details
                    _buildProfileDetail(
                        context, "Name", user['name'], Icons.person),
                    _buildProfileDetail(
                        context, "Phone", user['phone'], Icons.phone),
                    _buildProfileDetail(
                        context, "Email", user['email'], Icons.email),
                    _buildProfileDetail(
                        context, "Password", user['password'], Icons.password),
                    _buildProfileDetail(context, "Confirm Password",
                        user['confirm_password'], Icons.password),
                    _buildProfileDetailAddress(context, "Address",
                        user['address'], Icons.location_city, user['latlong']),
                    _buildProfileDetailLocation(
                        context, "Lat/Long", user['latlong'], Icons.map),
                  ],
                ),
              ),
            );
          } else if (state is AuthFailure) {
            return Center(
              child: Text(
                state.error,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            return const Center(
              child: Text("Please try again."),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileDetail(
      BuildContext context, String label, String? value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label),
        subtitle: Text(value ?? "Not available"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }

  Widget _buildProfileDetailAddress(BuildContext context, String label,
      String? value, IconData icon, latLng) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label),
        subtitle: Text(value ?? "Not available"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          RegExp regExp =
              RegExp(r"Lat:\s*(-?\d+\.\d+),\s*Long:\s*(-?\d+\.\d+)");
          Match? match = regExp.firstMatch(latLng!);
          if (match != null) {
            String latitude = match.group(1)!;
            String longitude = match.group(2)!;

            print("Latitude: $latitude");
            print("Longitude: $longitude");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RouteScreen(latitude: latitude, longitude: longitude),
              ),
            );
          } else {
            print("Invalid input format");
          }
        },
      ),
    );
  }

  Widget _buildProfileDetailLocation(
      BuildContext context, String label, String? value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label),
        subtitle: Text(value ?? "Not available"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (value != null) {
            // Regular expression to extract latitude and longitude
            RegExp regExp =
                RegExp(r"Lat:\s*(-?\d+\.\d+),\s*Long:\s*(-?\d+\.\d+)");
            Match? match = regExp.firstMatch(value);
            if (match != null) {
              // Convert matched strings to double
              double latitude = double.parse(match.group(1)!);
              double longitude = double.parse(match.group(2)!);

              print("Latitude: $latitude");
              print("Longitude: $longitude");
              _openMap(latitude, longitude);
            } else {
              print("Invalid input format");
            }
          } else {
            print("Location value is null");
          }
        },
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}
