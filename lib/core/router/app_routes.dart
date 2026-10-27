abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const session = '/session';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const accountDisabled = '/account-disabled';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const addPet = '/pets/new';
  static const history = '/history';
  static const profile = '/profile';

  static String petDetail(String petId) => '/pets/$petId';
  static String editPet(String petId) => '/pets/$petId/edit';
}
