import 'package:assignmentsubhasish/db/database_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<RegisterUser>(_onRegister);
    on<LoginUser>(_onLogin);
    on<LogoutUser>(_onLogout);
    on<LoadProfile>(_onLoadProfile);
  }
  Future<void> _onRegister(RegisterUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (await _hasInternet()) {
        await apiService.registerUser(event);
        emit(AuthSuccess());
      } else {
        await _storeOfflineUser(event);
        emit(AuthFailure(
          "No internet. or Server offline User data saved locally and will sync later.",
        ));
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.badResponse) {
        emit(AuthFailure("Failed to register: Server is offline."));
      } else {
        await _storeOfflineUser(event);
        emit(AuthFailure(
          "No internet. User data saved locally and will sync later.",
        ));
      }
    }
  }

  Future<void> _storeOfflineUser(RegisterUser event) async {
    await DatabaseHelper.instance.insertUser({
      'name': event.name,
      'email': event.email,
      'password': event.password,
      'phone': event.phone,
      'address': event.address,
      'latlong': event.latlong,
      'confirm_password': event.confirmPassword,
      'image': event.image,
      'synced': 0,
    });
  }

  Future<void> _onLogin(LoginUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (await _hasInternet()) {
        final tokenData =
            await apiService.loginUser(event.email, event.password);
        final accessToken = tokenData['accessToken']; // Extract access token

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', accessToken); // Save access token
        emit(AuthSuccess());
      } else {
        final user = await DatabaseHelper.instance.getUserByEmail(event.email);
        if (user != null && user['password'] == event.password) {
          emit(AuthSuccess());
        } else {
          emit(AuthFailure('Invalid credentials or user not found locally.'));
        }
      }
    } catch (e) {
      emit(AuthFailure("Login failed: $e"));
    }
  }

  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      if (await _hasInternet()) {
        final user = await apiService.fetchProfile(
          await _getToken(),
        );
        emit(ProfileLoaded(user));
      } else {
        final user = await DatabaseHelper.instance.getUserByEmail(event.email);
        if (user != null) {
          emit(ProfileLoaded(user));
        } else {
          emit(AuthFailure("No local data found."));
        }
      }
    } catch (e) {
      //emit(AuthFailure("Failed to load profile: $e"));
      final token = await _getTokens();
      if (token == null) {
        final user = await DatabaseHelper.instance.getUserByEmail(event.email);
        if (user != null) {
          emit(ProfileLoaded(user));
        } else {
          emit(AuthFailure("No local data found."));
        }
        return; // Stop further execution
      }
    }
  }

  Future<void> _onLogout(LogoutUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await apiService.logoutUser();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure("Logout failed: $e"));
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await Dio().get('https://www.google.com');
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token not found. Please log in.");
    return token;
  }

  Future<String?> _getTokens() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Will return null if 'token' doesn't exist
  }
}
