import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/core/network/api_client.dart';
import 'package:my_first_app/models/auth_token_model.dart';
import 'package:my_first_app/models/user_model.dart';
import 'package:my_first_app/repositories/remote/api_auth_repository.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/services/session_storage_service.dart';

void main() {
  group('1. SessionStorageService Sealed Storage & Device ID', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fincredit_sec_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'Tokens are sealed on disk (no plaintext JWT/refreshToken) and unsealed on reload',
      () async {
        final storage1 = SessionStorageService(customDirectory: tempDir);
        final token = AuthTokenModel(
          accessToken: 'secret_jwt_access_token_xyz',
          refreshToken: 'secret_refresh_token_abc',
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          accessExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          userId: 42,
        );
        const user = UserModel(
          userId: 42,
          fullName: 'Nguyen Van Bao Mat',
          email: 'baomat@fincredit.vn',
          passwordHash: '',
        );

        await storage1.saveSession(
          token: token,
          user: user,
          identifier: 'baomat@fincredit.vn',
        );

        final rawFile = File(
          '${tempDir.path}/auth_session.json',
        ).readAsStringSync();
        expect(rawFile.startsWith('v1:'), isTrue);
        expect(rawFile.contains('secret_jwt_access_token_xyz'), isFalse);
        expect(rawFile.contains('secret_refresh_token_abc'), isFalse);

        // Reload from a fresh instance
        final storage2 = SessionStorageService(customDirectory: tempDir);
        final restored = await storage2.getSavedToken();
        expect(restored, isNotNull);
        expect(restored!.accessToken, 'secret_jwt_access_token_xyz');
        expect(restored.refreshToken, 'secret_refresh_token_abc');
        expect(restored.userId, 42);
        expect((await storage2.getSavedUser())?.email, 'baomat@fincredit.vn');
      },
    );

    test(
      'Expired accessExpiresAt still keeps refreshToken available while session is valid',
      () async {
        final storage = SessionStorageService(customDirectory: tempDir);
        final token = AuthTokenModel(
          accessToken: 'expired_access_jwt',
          refreshToken: 'valid_refresh_token',
          expiresAt: DateTime.now().add(const Duration(days: 10)),
          accessExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
          userId: 1,
        );
        await storage.saveSession(token: token);

        final loaded = storage.getSavedTokenSync();
        expect(loaded, isNotNull);
        expect(loaded!.isAccessTokenExpired, isTrue);
        expect(loaded.isExpired, isFalse);
        expect(loaded.refreshToken, 'valid_refresh_token');
      },
    );

    test('getOrCreateDeviceId generates persistent 36-char UUID-style ID', () {
      final s1 = SessionStorageService(customDirectory: tempDir);
      final id1 = s1.getOrCreateDeviceId();
      final id2 = SessionStorageService(
        customDirectory: tempDir,
      ).getOrCreateDeviceId();
      expect(id1.length, 36);
      expect(id1, id2);
    });
  });

  group(
    '2. ApiAuthRepository Device Header, Expiry & Auto-Refresh on /session',
    () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('fincredit_auth_http_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test(
        'login parses access expires_at, sets rememberMe TTL, sends device UUID, and checkSession auto-refreshes on 401',
        () async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          String? capturedDeviceName;
          String? capturedRefreshHeader;
          int sessionCalls = 0;

          server.listen((req) async {
            final bodyStr = await utf8.decoder.bind(req).join();
            if (req.uri.path == '/api/v1/auth/login') {
              capturedDeviceName = req.headers.value('x-device-name');
              req.response.statusCode = 200;
              req.response.write(
                jsonEncode({
                  'data': {
                    'token': 'expired_access_1',
                    'refreshToken': 'refresh_1',
                    'expires_at': DateTime.now()
                        .subtract(const Duration(minutes: 1))
                        .toIso8601String(),
                    'user': {
                      'user_id': 7,
                      'full_name': 'Tester',
                      'email': 't@fincredit.vn',
                    },
                  },
                }),
              );
            } else if (req.uri.path == '/api/v1/auth/session') {
              sessionCalls++;
              capturedRefreshHeader = req.headers.value('x-refresh-token');
              final auth = req.headers.value('authorization');
              if (auth == 'Bearer expired_access_1') {
                req.response.statusCode = 401;
                req.response.write(jsonEncode({'message': 'Token expired'}));
              } else {
                req.response.statusCode = 200;
                req.response.write(
                  jsonEncode({
                    'data': {
                      'access_token': 'fresh_access_2',
                      'refresh_token': null,
                      'expires_at': DateTime.now()
                          .add(const Duration(minutes: 15))
                          .toIso8601String(),
                      'user_id': 7,
                    },
                  }),
                );
              }
            } else if (req.uri.path == '/api/v1/auth/refresh-token') {
              final parsed = jsonDecode(bodyStr) as Map<String, dynamic>;
              expect(parsed['refreshToken'], 'refresh_1');
              req.response.statusCode = 200;
              req.response.write(
                jsonEncode({
                  'data': {
                    'access_token': 'fresh_access_2',
                    'refresh_token': 'refresh_2',
                    'expires_at': DateTime.now()
                        .add(const Duration(minutes: 15))
                        .toIso8601String(),
                    'user_id': 7,
                  },
                }),
              );
            } else {
              req.response.statusCode = 404;
            }
            await req.response.close();
          });

          final storage = SessionStorageService(customDirectory: tempDir);
          final client = ApiClient(
            baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
          );
          client.onRefreshToken = () async {
            final saved = await storage.getSavedToken();
            if (saved?.refreshToken == null) return false;
            final res = await client.post(
              '/api/auth/refresh-token',
              body: {'refreshToken': saved!.refreshToken},
            );
            final data =
                (res as Map<String, dynamic>)['data'] as Map<String, dynamic>;
            final parsed = AuthTokenModel.fromJson(data);
            final updated = AuthTokenModel(
              accessToken: parsed.accessToken,
              refreshToken: parsed.refreshToken ?? saved.refreshToken,
              expiresAt: saved.expiresAt,
              accessExpiresAt: parsed.expiresAt,
              userId: parsed.userId,
            );
            client.setAuthToken(updated.accessToken);
            await storage.saveSession(token: updated);
            return true;
          };

          final repo = ApiAuthRepository(
            client: client,
            sessionStorage: storage,
          );
          await repo.login(
            identifier: 't@fincredit.vn',
            password: 'Password123!',
          );

          expect(capturedDeviceName, isNotNull);
          expect(capturedDeviceName!, startsWith('Android Device ('));
          expect(
            capturedDeviceName!.length,
            greaterThan('Android Device ('.length + 10),
          );

          final session = await repo.checkSession();
          expect(sessionCalls, 2);
          expect(capturedRefreshHeader, 'refresh_1');
          expect(session, isNotNull);
          expect(session!.accessToken, 'fresh_access_2');
          // Refresh token is preserved even though /session returned refresh_token: null
          expect(session.refreshToken, 'refresh_2');
          expect((await storage.getSavedToken())?.refreshToken, 'refresh_2');
        },
      );

      test(
        'onRefreshToken clears session when refresh-token returns 401',
        () async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          addTearDown(() => server.close(force: true));

          server.listen((req) async {
            req.response.statusCode = 401;
            req.response.write(jsonEncode({'message': 'Refresh revoked'}));
            await req.response.close();
          });

          await resetServiceLocator(dispose: false);
          setupServiceLocator(
            isMock: false,
            apiBaseUrl: 'http://127.0.0.1:${server.port}/api/v1',
          );
          addTearDown(() async {
            await resetServiceLocator(dispose: false);
            setupServiceLocator(isMock: true);
          });

          final client = sl<ApiClient>();
          client.setAuthToken('old_access');
          final storage = sl<SessionStorageService>();
          await storage.saveSession(
            token: AuthTokenModel(
              accessToken: 'old_access',
              refreshToken: 'revoked_refresh',
              expiresAt: DateTime.now().add(const Duration(days: 5)),
              userId: 1,
            ),
            user: const UserModel(
              userId: 1,
              fullName: 'User',
              email: 'u@test.vn',
              passwordHash: '',
            ),
          );
          sl<AuthController>().setCurrentUser(await storage.getSavedUser());

          final ok = await client.onRefreshToken!();
          expect(ok, isFalse);
          expect(client.authToken, isNull);
          expect(await storage.getSavedToken(), isNull);
          expect(sl<AuthController>().currentUser, isNull);
        },
      );
    },
  );

  group('3. Biometric Credentials & Android Keystore MethodChannel', () {
    late Directory tempDir;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = Directory.systemTemp.createTempSync('fincredit_bio_sec_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'saveBiometricCredentials never stores raw Base64 plaintext on disk',
      () async {
        final storage = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: false,
        );
        await storage.saveBiometricCredentials(
          identifier: 'user@fincredit.vn',
          password: 'SuperSecretPassword123!',
        );

        final rawFile = File(
          '${tempDir.path}/biometric_binding.json',
        ).readAsStringSync();
        expect(rawFile.startsWith('v1:'), isTrue);
        expect(rawFile.contains('SuperSecretPassword123!'), isFalse);
        final base64Raw = base64Encode(utf8.encode('SuperSecretPassword123!'));
        expect(rawFile.contains(base64Raw), isFalse);

        final fresh = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: false,
        );
        final creds = await fresh.getBiometricCredentials();
        expect(creds, isNotNull);
        expect(creds!.identifier, 'user@fincredit.vn');
        expect(creds.password, 'SuperSecretPassword123!');
      },
    );

    test(
      'Keystore MethodChannel encrypts auth_session & biometric_binding with ks1: and preload decrypts',
      () async {
        const channel = MethodChannel('fincredit/secure_storage');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              final args = call.arguments as Map;
              if (call.method == 'encrypt') {
                final plain = args['plain'] as String;
                return 'ks1:${base64Encode(utf8.encode(plain))}';
              }
              if (call.method == 'decrypt') {
                final cipher = args['cipher'] as String;
                return utf8.decode(base64Decode(cipher.substring(4)));
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final s1 = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: true,
        );
        await s1.saveSession(
          token: AuthTokenModel(
            accessToken: 'ks_jwt_1',
            refreshToken: 'ks_ref_1',
            expiresAt: DateTime.now().add(const Duration(days: 30)),
            userId: 9,
          ),
          identifier: 'ks@fincredit.vn',
        );
        await s1.saveBiometricCredentials(
          identifier: 'ks@fincredit.vn',
          password: 'KsPassword!99',
        );

        expect(
          File(
            '${tempDir.path}/auth_session.json',
          ).readAsStringSync().startsWith('ks1:'),
          isTrue,
        );
        expect(
          File(
            '${tempDir.path}/biometric_binding.json',
          ).readAsStringSync().startsWith('ks1:'),
          isTrue,
        );

        final s2 = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: true,
        );
        await s2.preload();
        expect(s2.getSavedTokenSync()?.accessToken, 'ks_jwt_1');
        expect(s2.getSavedTokenSync()?.refreshToken, 'ks_ref_1');
        expect(s2.getBiometricCredentialsSync()?.password, 'KsPassword!99');
      },
    );
  });

  group('3. Biometric Credentials & Android Keystore MethodChannel', () {
    late Directory tempDir;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = Directory.systemTemp.createTempSync('fincredit_bio_sec_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'saveBiometricCredentials never stores raw Base64 plaintext on disk',
      () async {
        final storage = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: false,
        );
        await storage.saveBiometricCredentials(
          identifier: 'user@fincredit.vn',
          password: 'SuperSecretPassword123!',
        );

        final rawFile = File(
          '${tempDir.path}/biometric_binding.json',
        ).readAsStringSync();
        expect(rawFile.startsWith('v1:'), isTrue);
        expect(rawFile.contains('SuperSecretPassword123!'), isFalse);
        final base64Raw = base64Encode(utf8.encode('SuperSecretPassword123!'));
        expect(rawFile.contains(base64Raw), isFalse);

        final fresh = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: false,
        );
        final creds = await fresh.getBiometricCredentials();
        expect(creds, isNotNull);
        expect(creds!.identifier, 'user@fincredit.vn');
        expect(creds.password, 'SuperSecretPassword123!');
      },
    );

    test(
      'Keystore MethodChannel encrypts auth_session & biometric_binding with ks1: and preload decrypts',
      () async {
        const channel = MethodChannel('fincredit/secure_storage');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              final args = call.arguments as Map;
              if (call.method == 'encrypt') {
                final plain = args['plain'] as String;
                return 'ks1:${base64Encode(utf8.encode(plain))}';
              }
              if (call.method == 'decrypt') {
                final cipher = args['cipher'] as String;
                return utf8.decode(base64Decode(cipher.substring(4)));
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final s1 = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: true,
        );
        await s1.saveSession(
          token: AuthTokenModel(
            accessToken: 'ks_jwt_1',
            refreshToken: 'ks_ref_1',
            expiresAt: DateTime.now().add(const Duration(days: 30)),
            userId: 9,
          ),
          identifier: 'ks@fincredit.vn',
        );
        await s1.saveBiometricCredentials(
          identifier: 'ks@fincredit.vn',
          password: 'KsPassword!99',
        );

        expect(
          File(
            '${tempDir.path}/auth_session.json',
          ).readAsStringSync().startsWith('ks1:'),
          isTrue,
        );
        expect(
          File(
            '${tempDir.path}/biometric_binding.json',
          ).readAsStringSync().startsWith('ks1:'),
          isTrue,
        );

        final s2 = SessionStorageService(
          customDirectory: tempDir,
          useKeystoreOverride: true,
        );
        await s2.preload();
        expect(s2.getSavedTokenSync()?.accessToken, 'ks_jwt_1');
        expect(s2.getSavedTokenSync()?.refreshToken, 'ks_ref_1');
        expect(s2.getBiometricCredentialsSync()?.password, 'KsPassword!99');
      },
    );
  });
}
