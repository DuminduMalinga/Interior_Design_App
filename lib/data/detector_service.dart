import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'layout_service.dart';

/// Where the wall detector (`Interior-Design-Web/backend/wall_detector`) runs.
/// Override with `--dart-define=DETECTOR_URL=...`, or point
/// `--dart-define=LAYOUT_SERVICE_BASE=https://my-host` at the Caddy deployment
/// (the detector is served under `/detector`). The default addresses a local
/// `uvicorn main:app --port 8000` from the Android emulator.
class DetectorEnv {
  const DetectorEnv._();

  static const String _url = String.fromEnvironment('DETECTOR_URL');
  static const String _base = String.fromEnvironment('LAYOUT_SERVICE_BASE');

  static String get url {
    final value = _url.isNotEmpty
        ? _url
        : _base.isNotEmpty
        ? '$_base/detector'
        : 'http://10.0.2.2:8000';
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

/// Sends a floor-plan image to the wall detector as the signed-in user and
/// returns its detection document (the `DetectionJSON` the web app stores).
class DetectorService {
  DetectorService({http.Client? client}) : _client = client ?? http.Client();

  static final DetectorService instance = DetectorService();

  final http.Client _client;

  Future<Map<String, dynamic>> detect({
    required Uint8List bytes,
    required String fileName,
    String? floorPlanId,
  }) async {
    final baseUrl = DetectorEnv.url;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw const LayoutServiceException(
        'Your session expired. Please sign in again.',
      );
    }

    final uri = Uri.parse('$baseUrl/detect').replace(
      queryParameters: {
        'ocr': 'true',
        // the annotated picture is large and the app never shows it
        'annotate': 'false',
        'floor_plan_id': ?floorPlanId,
      },
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(minutes: 3)),
      );
    } on TimeoutException {
      throw const LayoutServiceException(
        'The wall detector took too long to answer.',
      );
    } catch (_) {
      throw LayoutServiceException(
        'Could not reach the wall detector at $baseUrl. Is it running?',
      );
    }

    Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (response.statusCode != 200) {
      final detail = body is Map ? body['detail'] : null;
      throw LayoutServiceException(
        'Wall detection failed: '
        '${detail ?? '${response.statusCode} ${response.reasonPhrase}'}',
      );
    }
    if (body is! Map) {
      throw const LayoutServiceException(
        'The wall detector sent an unreadable answer.',
      );
    }
    final detection = Map<String, dynamic>.from(body);
    // never stored, like the web app
    detection.remove('annotatedImage');
    return detection;
  }
}
