import 'dart:io';
import 'dart:async';
import 'package:petreminder_user/models/feeding_schedule.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:petreminder_user/core/time/local_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'feeding_reminders_v2';
  static const _channelName = 'Recordatorios de alimentación';
  static const _channelDescription =
      'Avisos antes y durante la hora de alimentación.';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void> _syncQueue = Future.value();
  int _syncGeneration = 0;
  bool _canScheduleExact = false;
  bool _permissionsRequested = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(
      resolveLocalTimezone(
        timezone.identifier,
        fallbackOffset: DateTime.now().timeZoneOffset,
      ),
    );

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> requestPermissions({bool force = false}) async {
    await initialize();
    if (!Platform.isAndroid) {
      return;
    }
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (_permissionsRequested && !force) {
      _canScheduleExact =
          await android?.canScheduleExactNotifications() ?? false;
      return;
    }
    _permissionsRequested = true;
    await android?.requestNotificationsPermission();
    _canScheduleExact = await android?.canScheduleExactNotifications() ?? false;
    if (!_canScheduleExact) {
      await android?.requestExactAlarmsPermission();
      _canScheduleExact =
          await android?.canScheduleExactNotifications() ?? false;
    }
  }

  Future<void> syncAllForUser({
    required FirebaseFirestore firestore,
    required String userId,
  }) {
    final generation = ++_syncGeneration;
    final next = _syncQueue.catchError((_) {}).then((_) async {
      if (generation != _syncGeneration) return;
      await _syncForUser(
        firestore: firestore,
        userId: userId,
        generation: generation,
      );
    });
    _syncQueue = next;
    return next;
  }

  Future<void> _syncForUser({
    required FirebaseFirestore firestore,
    required String userId,
    required int generation,
  }) async {
    // Preparar la lista antes de cancelar avisos: un fallo de red conserva los ya programados.
    final reminders =
        <({String petId, String petName, FeedingSchedule schedule})>[];
    final pets = await firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .get()
        .timeout(const Duration(seconds: 10));
    for (final pet in pets.docs) {
      if (generation != _syncGeneration) return;
      final schedules = await pet.reference
          .collection('feedingSchedules')
          .get()
          .timeout(const Duration(seconds: 10));
      for (final schedule in schedules.docs) {
        reminders.add((
          petId: pet.id,
          petName: pet.data()['name'] as String? ?? 'Mascota',
          schedule: FeedingSchedule.fromDocument(schedule),
        ));
      }
    }
    if (generation != _syncGeneration) return;
    await requestPermissions();
    if (generation != _syncGeneration) return;
    await _notifications.cancelAll();
    for (final reminder in reminders) {
      if (generation != _syncGeneration) return;
      final schedule = reminder.schedule;
      await updateSchedule(
        petId: reminder.petId,
        petName: reminder.petName,
        scheduleId: schedule.id,
        time: schedule.time,
        active: schedule.active,
        weekdays: schedule.weekdays,
      );
    }
  }

  Future<void> updateSchedule({
    required String petId,
    required String petName,
    required String scheduleId,
    required String time,
    required bool active,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    await initialize();
    await cancelSchedule(petId: petId, scheduleId: scheduleId);
    if (!active) {
      return;
    }

    if (!FeedingSchedule.isValidTime(time) ||
        !FeedingSchedule.validWeekdays(weekdays)) {
      return;
    }
    final mode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Una repetición semanal por día evita avisos en días desactivados.
    for (final day in weekdays) {
      final meal = nextOccurrence(time: time, weekday: day);
      var before = meal.subtract(const Duration(minutes: 5));
      if (!before.isAfter(tz.TZDateTime.now(tz.local))) {
        before = before.add(const Duration(days: 7));
      }
      for (final kind in ['before', 'meal']) {
        await _notifications.zonedSchedule(
          id: notificationId(petId, scheduleId, '$kind-$day'),
          title: kind == 'before' ? 'Próxima comida' : 'Hora de alimentar',
          body: kind == 'before'
              ? 'Mascota "$petName" come en 5 minutos.'
              : 'Es hora de alimentar a "$petName".',
          scheduledDate: kind == 'before' ? before : meal,
          notificationDetails: _details,
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '$petId|$scheduleId',
        );
      }
    }
  }

  static tz.TZDateTime nextOccurrence({
    required String time,
    required int weekday,
    tz.TZDateTime? now,
  }) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    final parts = time.split(':');
    var scheduled = tz.TZDateTime(
      current.location,
      current.year,
      current.month,
      current.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final days = (weekday - current.weekday) % 7;
    scheduled = tz.TZDateTime(
      current.location,
      scheduled.year,
      scheduled.month,
      scheduled.day + days,
      scheduled.hour,
      scheduled.minute,
    );
    if (!scheduled.isAfter(current)) {
      scheduled = tz.TZDateTime(
        current.location,
        scheduled.year,
        scheduled.month,
        scheduled.day + 7,
        scheduled.hour,
        scheduled.minute,
      );
    }
    return scheduled;
  }

  Future<void> cancelSchedule({
    required String petId,
    required String scheduleId,
  }) async {
    await initialize();
    await _notifications.cancel(
      id: notificationId(petId, scheduleId, 'before'),
    );
    await _notifications.cancel(id: notificationId(petId, scheduleId, 'meal'));
    for (var day = 1; day <= 7; day++) {
      for (final kind in ['before', 'meal']) {
        await _notifications.cancel(
          id: notificationId(petId, scheduleId, '$kind-$day'),
        );
      }
    }
  }

  Future<void> cancelAll() async {
    _syncGeneration++;
    await _syncQueue.catchError((_) {});
    await initialize();
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    await initialize();
    return _notifications.pendingNotificationRequests();
  }

  static int notificationId(String petId, String scheduleId, String kind) {
    var hash = 0x811c9dc5;
    for (final byte in '$petId:$scheduleId:$kind'.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Future<void> openSettings() async {
    await initialize();
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.openAppNotificationSettings();
  }

  Future<void> sendTest() async {
    await requestPermissions(force: true);
    await _notifications.show(
      id: 42,
      title: 'PetReminder está listo',
      body: 'Esta es una prueba de sonido y notificaciones.',
      notificationDetails: _details,
    );
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
  );
}
