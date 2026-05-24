import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/planner_event.dart';

const _calendarScope = 'https://www.googleapis.com/auth/calendar';
const _calendarBase = 'https://www.googleapis.com/calendar/v3';
// Resolved at compile time via --dart-define=GOOGLE_OAUTH_CLIENT_ID=...
const _kGoogleClientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._();

  // Lazily created — avoids loading the GIS JS library until Calendar is
  // actually used, and skips it entirely when no client ID is configured.
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _gs {
    _googleSignIn ??= GoogleSignIn(
      clientId: _kGoogleClientId.isEmpty ? null : _kGoogleClientId,
      scopes: [_calendarScope],
    );
    return _googleSignIn!;
  }

  bool get isConfigured => _kGoogleClientId.isNotEmpty;
  bool get isConnected => _googleSignIn?.currentUser != null;

  Future<bool> connect() async {
    if (!isConfigured) return false;
    try {
      final account = await _gs.signIn();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> tryRestoreConnection() async {
    if (!isConfigured) return false;
    try {
      final account = await _gs.signInSilently();
      return account != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _googleSignIn?.signOut();
  }

  Future<Map<String, String>?> _authHeaders() async {
    if (!isConfigured) return null;
    GoogleSignInAccount? account = _gs.currentUser;
    account ??= await _gs.signInSilently();
    return account?.authHeaders;
  }

  Future<List<PlannerEvent>> fetchEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    final headers = await _authHeaders();
    if (headers == null) return [];

    final uri = Uri.parse('$_calendarBase/calendars/primary/events').replace(
      queryParameters: {
        'timeMin': timeMin.toUtc().toIso8601String(),
        'timeMax': timeMax.toUtc().toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '250',
      },
    );

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List?) ?? [];

    return items
        .map((item) => _googleEventToPlanner(item as Map<String, dynamic>))
        .whereType<PlannerEvent>()
        .toList();
  }

  Future<String?> createEvent(PlannerEvent event) async {
    final headers = await _authHeaders();
    if (headers == null) return null;

    final body = _plannerEventToGoogleBody(event);
    final uri = Uri.parse('$_calendarBase/calendars/primary/events');

    final response = await http.post(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id'] as String?;
  }

  Future<bool> updateEvent(PlannerEvent event) async {
    if (event.googleEventId == null) return false;
    final headers = await _authHeaders();
    if (headers == null) return false;

    final body = _plannerEventToGoogleBody(event);
    final uri = Uri.parse(
        '$_calendarBase/calendars/primary/events/${event.googleEventId}');

    final response = await http.put(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteEvent(String googleEventId) async {
    final headers = await _authHeaders();
    if (headers == null) return false;

    final uri = Uri.parse(
        '$_calendarBase/calendars/primary/events/$googleEventId');
    final response = await http.delete(uri, headers: headers);
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // --- Conversion helpers ---

  PlannerEvent? _googleEventToPlanner(Map<String, dynamic> item) {
    try {
      final startMap = item['start'] as Map<String, dynamic>?;
      final endMap = item['end'] as Map<String, dynamic>?;
      if (startMap == null) return null;

      final isAllDay = startMap.containsKey('date');
      final startStr = isAllDay
          ? '${startMap['date']}T00:00:00'
          : startMap['dateTime'] as String;
      final endStr = endMap == null
          ? null
          : isAllDay
              ? '${endMap['date']}T00:00:00'
              : endMap['dateTime'] as String?;

      return PlannerEvent(
        id: 'gcal-${item['id']}',
        googleEventId: item['id'] as String?,
        title: item['summary'] as String? ?? '(No title)',
        description: item['description'] as String? ?? '',
        location: item['location'] as String? ?? '',
        startDateTime: startStr,
        endDateTime: endStr,
        isAllDay: isAllDay,
        color: 'blue',
        isSynced: true,
        createdAt: item['created'] as String? ?? DateTime.now().toIso8601String(),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _plannerEventToGoogleBody(PlannerEvent event) {
    final Map<String, dynamic> startObj;
    final Map<String, dynamic> endObj;

    if (event.isAllDay) {
      final dateStr = event.startDateStr;
      final endDateStr = event.endDateTime?.split('T')[0] ?? dateStr;
      startObj = {'date': dateStr};
      endObj = {'date': endDateStr};
    } else {
      startObj = {'dateTime': event.startDateTime};
      endObj = {'dateTime': event.endDateTime ?? event.startDateTime};
    }

    return {
      'summary': event.title,
      if (event.description.isNotEmpty) 'description': event.description,
      if (event.location.isNotEmpty) 'location': event.location,
      'start': startObj,
      'end': endObj,
    };
  }
}
