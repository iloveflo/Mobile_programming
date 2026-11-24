import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/config/app_env.dart';
import 'package:my_first_app/core/network/api_client.dart';

void main() {
  group('AppEnv & ApiClient Failover (Coolify -> Render)', () {
    test('healthUriFor chuẩn hóa đúng đường dẫn /health ở origin gốc', () {
      expect(
        AppEnv.healthUriFor(
          'https://fincredit.binha10k56.id.vn/api/v1',
        ).toString(),
        'https://fincredit.binha10k56.id.vn/health',
      );
      expect(
        AppEnv.healthUriFor(
          'https://fincredit-api-gjiz.onrender.com/api/v1/',
        ).toString(),
        'https://fincredit-api-gjiz.onrender.com/health',
      );
    });

    test(
      'ensureHealthyEndpoint chuyển ngay sang Render khi Coolify /health lỗi',
      () async {
        final client = ApiClient(
          baseUrl: 'https://primary.test/api/v1',
          fallbackBaseUrl: 'https://fallback.test/api/v1',
          healthChecker: (uri, _) async {
            return uri.host == 'fallback.test';
          },
        );

        await client.ensureHealthyEndpoint();
        expect(client.baseUrl, 'https://fallback.test/api/v1');
      },
    );

    test('Instant 1-tap failover khi /auth/login gặp 503 ở primary', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      bool hitFallback = false;
      server.listen((req) async {
        if (req.uri.path == '/primary/api/v1/auth/login') {
          req.response.statusCode = 503;
          req.response.write(jsonEncode({'message': 'Service Unavailable'}));
        } else if (req.uri.path == '/fallback/api/v1/auth/login') {
          hitFallback = true;
          req.response.statusCode = 200;
          req.response.write(jsonEncode({'token': 'ok_from_render'}));
        } else {
          req.response.statusCode = 404;
        }
        await req.response.close();
      });

      final client = ApiClient(
        baseUrl: 'http://127.0.0.1:${server.port}/primary/api/v1',
        fallbackBaseUrl: 'http://127.0.0.1:${server.port}/fallback/api/v1',
        healthChecker: (uri, _) async => true,
      );

      final res = await client.post(
        '/api/auth/login',
        body: {'identifier': 'a@b.com', 'password': '123'},
      );

      expect(hitFallback, isTrue);
      expect(res['token'], 'ok_from_render');
      expect(client.baseUrl, 'http://127.0.0.1:${server.port}/fallback/api/v1');
    });

    test(
      'Circuit breaker đếm đủ 3 lỗi liên tiếp + Render OK mới gọi onServerFailover',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));

        int mode = 503;
        server.listen((req) async {
          req.response.statusCode = mode;
          req.response.write(jsonEncode({'ok': mode == 200}));
          await req.response.close();
        });

        int failoverCalls = 0;
        final client = ApiClient(
          baseUrl: 'http://127.0.0.1:${server.port}/primary/api/v1',
          fallbackBaseUrl: 'http://127.0.0.1:${server.port}/fallback/api/v1',
          serverFailureThreshold: 3,
          healthChecker: (uri, _) async => true,
        );
        client.onServerFailover = () async {
          failoverCalls++;
        };

        // 2 lỗi đầu chưa kích hoạt failover
        await expectLater(
          client.get('/api/loans'),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          client.get('/api/loans'),
          throwsA(isA<ApiException>()),
        );
        expect(client.consecutiveServerFailures, 2);
        expect(failoverCalls, 0);

        // Nếu có 1 request thành công thì reset bộ đếm về 0
        mode = 200;
        await client.get('/api/loans');
        expect(client.consecutiveServerFailures, 0);

        // Lỗi HTTP 500 không tính là sập server
        mode = 500;
        await expectLater(
          client.get('/api/loans'),
          throwsA(isA<ApiException>()),
        );
        expect(client.consecutiveServerFailures, 0);

        // 3 lỗi 503 liên tiếp -> kích hoạt onServerFailover đúng 1 lần và chuyển sang fallback
        mode = 503;
        await expectLater(
          client.get('/api/loans'),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          client.get('/api/loans'),
          throwsA(isA<ApiException>()),
        );
        await expectLater(
          client.get('/api/loans'),
          throwsA(isA<ApiException>()),
        );

        expect(failoverCalls, 1);
        expect(
          client.baseUrl,
          'http://127.0.0.1:${server.port}/fallback/api/v1',
        );
      },
    );

    test(
      'Không failover nếu Render /health cũng chết (mất mạng phía user)',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));

        server.listen((req) async {
          req.response.statusCode = 503;
          await req.response.close();
        });

        int failoverCalls = 0;
        final client = ApiClient(
          baseUrl: 'http://127.0.0.1:${server.port}/primary/api/v1',
          fallbackBaseUrl: 'http://127.0.0.1:${server.port}/fallback/api/v1',
          serverFailureThreshold: 3,
          healthChecker: (uri, _) async => false,
        );
        client.onServerFailover = () async {
          failoverCalls++;
        };

        for (int i = 0; i < 3; i++) {
          await expectLater(
            client.get('/api/loans'),
            throwsA(isA<ApiException>()),
          );
        }

        expect(failoverCalls, 0);
        expect(
          client.baseUrl,
          'http://127.0.0.1:${server.port}/primary/api/v1',
        );
      },
    );

    test(
      'Khôi phục từ Render về lại Coolify khi ensureHealthyEndpoint thấy Coolify sống lại',
      () async {
        bool primaryAlive = false;
        final client = ApiClient(
          baseUrl: 'https://primary.test/api/v1',
          fallbackBaseUrl: 'https://fallback.test/api/v1',
          healthChecker: (uri, _) async {
            if (uri.host == 'primary.test') return primaryAlive;
            return uri.host == 'fallback.test';
          },
        );

        // Ban đầu primary chết -> chuyển sang fallback
        await client.ensureHealthyEndpoint();
        expect(client.baseUrl, 'https://fallback.test/api/v1');

        // Sau đó primary sống lại -> gọi ensureHealthyEndpoint (như khi mở lại Login/Splash) -> quay về primary
        primaryAlive = true;
        await client.ensureHealthyEndpoint();
        expect(client.baseUrl, 'https://primary.test/api/v1');
      },
    );

    test(
      'Failover 2 chiều: đang ở Render mà Render sập khi Coolify đã sống -> tự quay về Coolify',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));

        bool primaryAlive = false;
        bool fallbackAlive = true;
        server.listen((req) async {
          if (req.uri.path.startsWith('/primary')) {
            req.response.statusCode = primaryAlive ? 200 : 503;
            req.response.write(jsonEncode({'server': 'primary'}));
          } else {
            req.response.statusCode = fallbackAlive ? 200 : 503;
            req.response.write(jsonEncode({'server': 'fallback'}));
          }
          await req.response.close();
        });

        final client = ApiClient(
          baseUrl: 'http://127.0.0.1:${server.port}/primary/api/v1',
          fallbackBaseUrl: 'http://127.0.0.1:${server.port}/fallback/api/v1',
          healthChecker: (uri, _) async {
            if (uri.path.startsWith('/primary')) return primaryAlive;
            return fallbackAlive;
          },
        );

        // 1. Khởi động lúc primary chết -> dùng fallback
        await client.ensureHealthyEndpoint();
        expect(
          client.baseUrl,
          'http://127.0.0.1:${server.port}/fallback/api/v1',
        );

        // 2. Primary sống lại, fallback sập đúng lúc user bấm login -> tự quay về primary ngay
        primaryAlive = true;
        fallbackAlive = false;
        final res = await client.post(
          '/api/auth/login',
          body: {'identifier': 'a@b.com', 'password': '123'},
        );
        expect(res['server'], 'primary');
        expect(
          client.baseUrl,
          'http://127.0.0.1:${server.port}/primary/api/v1',
        );
      },
    );
  });
}
