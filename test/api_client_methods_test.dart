import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/network/api_client.dart';

void main() {
  group('ApiClient Real HttpServer Methods', () {
    test(
      'ApiClient executes put, patch, delete, getBytes, uploadBinary and handles 4xx',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));

        server.listen((req) async {
          if (req.uri.path.endsWith('/bytes')) {
            req.response.statusCode = 200;
            req.response.add([10, 20, 30]);
          } else if (req.uri.path.endsWith('/upload')) {
            req.response.statusCode = 200;
          } else if (req.uri.path.endsWith('/err400')) {
            req.response.statusCode = 400;
            req.response.write(jsonEncode({'message': 'Bad Request'}));
          } else {
            req.response.statusCode = 200;
            req.response.write(jsonEncode({'method': req.method, 'ok': true}));
          }
          await req.response.close();
        });

        final client = ApiClient(
          baseUrl: 'http://127.0.0.1:${server.port}/api/v1',
        );
        client.setAuthToken('tok_123');

        expect((await client.put('/items/1', body: {'a': 1}))['method'], 'PUT');
        expect(
          (await client.patch('/items/1', body: {'b': 2}))['method'],
          'PATCH',
        );
        expect((await client.delete('/items/1'))['method'], 'DELETE');
        expect(await client.getBytes('/bytes'), [10, 20, 30]);
        expect(
          await client.uploadBinary(
            Uri.parse('http://127.0.0.1:${server.port}/upload'),
            [1, 2, 3],
            extraHeaders: {'x-test': '1'},
          ),
          isTrue,
        );
        await expectLater(client.get('/err400'), throwsA(isA<ApiException>()));
      },
    );
  });
}
