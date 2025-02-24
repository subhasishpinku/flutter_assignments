abstract class AuthEvent {}

class RegisterUser extends AuthEvent {
  final String name, email, password, phone, address, latlong, confirmPassword;
  final String? image;

  RegisterUser({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.latlong,
    required this.confirmPassword,
    this.image,
  });
}

class LoginUser extends AuthEvent {
  final String email, password;
  LoginUser({required this.email, required this.password});
}

class LogoutUser extends AuthEvent {}

class LoadProfile extends AuthEvent {
  final String email;
  LoadProfile(this.email);
}
