import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'dart:async';
import 'db/database_helper.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  syncOfflineData();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(apiService: ApiService()),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Auth',
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
        theme: ThemeData(primarySwatch: Colors.blue),
      ),
    );
  }
}

void syncOfflineData() {
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (await _hasInternet()) {
      try {
        List<Map<String, dynamic>> unsyncedUsers =
            await DatabaseHelper.instance.getUnsyncedUsers();

        for (var user in unsyncedUsers) {
          try {
            await ApiService().registerUser(RegisterUser(
              name: user['name'],
              email: user['email'],
              password: user['password'],
              phone: user['phone'],
              address: user['address'],
              latlong: user['latlong'],
              confirmPassword: user['confirm_password'],
              image: user['image'],
            ));
            // Mark user as synced.
            await DatabaseHelper.instance.updateUserSynced(user['id']);
          } catch (e) {
            print("Sync failed for user ${user['id']}: $e");
          }
        }
      } catch (e) {
        print("Failed to fetch unsynced users: $e");
      }
    } else {
      print("No internet connection. Sync skipped.");
    }
  });
}

Future<bool> _hasInternet() async {
  try {
    final result = await Dio().get('https://google.com');
    return result.statusCode == 200;
  } catch (_) {
    return false;
  }
}
