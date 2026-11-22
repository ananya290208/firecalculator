import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fire_calculator/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Local Authentication Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state: not registered and not logged in', () async {
      final auth = AuthService();
      await auth.init();

      expect(auth.isRegistered, false);
      expect(auth.isLoggedIn, false);
      expect(auth.userName, '');
      expect(auth.userEmail, '');
    });

    test('Registration saves credentials locally and logs in', () async {
      final auth = AuthService();
      await auth.init();

      final err = await auth.register(
        name: 'Amit Patel',
        email: 'amit@example.com',
        password: 'password123',
      );

      expect(err, isNull);
      expect(auth.isRegistered, true);
      expect(auth.isLoggedIn, true);
      expect(auth.userName, 'Amit Patel');
      expect(auth.userEmail, 'amit@example.com');
    });

    test('Login fails with invalid password, succeeds with correct password', () async {
      final auth = AuthService();
      await auth.init();

      await auth.register(
        name: 'Priya Sharma',
        email: 'priya@example.com',
        password: 'secretPassword',
      );

      await auth.logout();
      expect(auth.isLoggedIn, false);

      // Wrong password
      final wrongErr = await auth.login(
        email: 'priya@example.com',
        password: 'wrongPassword',
      );
      expect(wrongErr, contains('Incorrect password'));
      expect(auth.isLoggedIn, false);

      // Correct password
      final successErr = await auth.login(
        email: 'priya@example.com',
        password: 'secretPassword',
      );
      expect(successErr, isNull);
      expect(auth.isLoggedIn, true);
    });

    test('Login is remembered on subsequent access (app relaunch)', () async {
      // 1. First session: user registers and logs in with rememberMe: true (default)
      final session1 = AuthService();
      await session1.init();
      await session1.register(
        name: 'Rohan Mehra',
        email: 'rohan@example.com',
        password: 'mypassword',
        rememberMe: true,
      );
      expect(session1.isLoggedIn, true);

      // 2. Second session: simulate reopening the app (new AuthService instance)
      final session2 = AuthService();
      await session2.init();
      expect(session2.isRegistered, true);
      expect(session2.isLoggedIn, true);
      expect(session2.userName, 'Rohan Mehra');
      expect(session2.userEmail, 'rohan@example.com');

      // 3. User logs out
      await session2.logout();
      expect(session2.isLoggedIn, false);

      // 4. Third session: reopening app after explicit logout requires login
      final session3 = AuthService();
      await session3.init();
      expect(session3.isRegistered, true);
      expect(session3.isLoggedIn, false);
      expect(session3.userEmail, 'rohan@example.com'); // email prefilled for quick login

      // 5. Re-login with rememberMe: true
      final loginErr = await session3.login(
        email: 'rohan@example.com',
        password: 'mypassword',
        rememberMe: true,
      );
      expect(loginErr, isNull);
      expect(session3.isLoggedIn, true);

      // 6. Fourth session: reopening app after login stays logged in
      final session4 = AuthService();
      await session4.init();
      expect(session4.isLoggedIn, true);
    });

    test('Web credentials constants match required user id and password', () {
      expect(AuthService.webAuthorizedEmail, 'sachin.virmalwar@gmail.com');
      expect(AuthService.webAuthorizedPassword, 'Incredible@08');
      expect(AuthService.webAuthorizedName, 'Sachin Virmalwar');
    });
  });
}
