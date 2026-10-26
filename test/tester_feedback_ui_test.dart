import 'dart:io';
import 'dart:ui' as ui;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petreminder_user/app.dart';
import 'package:petreminder_user/core/theme/app_theme.dart';
import 'package:petreminder_user/core/widgets/app_background.dart';
import 'package:petreminder_user/features/history/presentation/history_screen.dart';
import 'package:petreminder_user/features/pets/presentation/pet_care_screen.dart';
import 'package:petreminder_user/features/pets/presentation/schedule_editor.dart';
import 'package:petreminder_user/models/care_plan.dart';
import 'package:petreminder_user/models/feeding_record.dart';
import 'package:petreminder_user/models/pet.dart';
import 'package:petreminder_user/providers/auth_providers.dart';
import 'package:petreminder_user/providers/care_space_providers.dart';
import 'package:petreminder_user/providers/feeding_history_providers.dart';
import 'package:petreminder_user/providers/firebase_providers.dart';
import 'package:petreminder_user/providers/pet_care_providers.dart';

final _previewKey = GlobalKey();
const _previews = bool.fromEnvironment('UPDATE_PREVIEWS');

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, widget) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: RepaintBoundary(
      key: _previewKey,
      child: AppBackground(child: widget!),
    ),
  ),
  home: child,
);

Future<void> _capture(WidgetTester tester, String name) async {
  if (!_previews) return;
  await tester.runAsync(() async {
    final boundary =
        _previewKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/previews/beta2');
    await folder.create(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!_previews) return;
    final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/dev/flutter';
    final font = File(
      '$root/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    if (await font.exists()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await loader.load();
    }
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (await icons.exists()) {
      final loader = FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(await icons.readAsBytes())));
      await loader.load();
    }
  });
  testWidgets('login centra el título y permite desplazarse con texto grande', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const RepaintBoundary(
          key: ValueKey('login-preview'),
          child: PetReminderApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('Bienvenido'));
    expect(title.textAlign, TextAlign.center);
    expect(
      (tester.getCenter(find.text('Bienvenido')).dx - 195).abs(),
      lessThan(2),
    );
    expect(tester.takeException(), isNull);
    if (_previews) {
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/backgrounds/paws_hearts.png'),
          tester.element(find.text('Bienvenido')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('login-preview')),
        );
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/previews/beta2').create(recursive: true);
        await File(
          'build/previews/beta2/login.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: const PetReminderApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Regístrate'));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'historial vacío centra el mensaje incluso en pantallas estrechas',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedingHistoryProvider.overrideWith((ref) => const AsyncData([])),
            ensureTodayForAllPetsProvider.overrideWith((ref) async {}),
          ],
          child: _app(const HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.text('Todavía no hay alimentaciones programadas.'),
            )
            .textAlign,
        TextAlign.center,
      );
      await _capture(tester, 'history-empty');
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedingHistoryProvider.overrideWith((ref) => const AsyncData([])),
            ensureTodayForAllPetsProvider.overrideWith((ref) async {}),
          ],
          child: _app(const HistoryScreen(), scale: 1.8),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('editor de horario exige un día y conserva nombre y frecuencia', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDialog<ScheduleDraft>(
                  context: context,
                  builder: (_) => const ScheduleEditor(),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    for (final day in ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']) {
      await tester.ensureVisible(find.widgetWithText(FilterChip, day));
      await tester.tap(find.widgetWithText(FilterChip, day));
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Lun'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
          .onPressed,
      isNotNull,
    );
    await _capture(tester, 'schedule-editor');
  });
  testWidgets(
    'historial filtra realizadas y pendientes sin perder comidas manuales',
    (tester) async {
      final records = [
        for (var n = 0; n < 2; n++)
          FeedingRecord(
            id: '$n',
            userId: 'u',
            petId: 'p',
            petName: 'Max',
            scheduleId: 's$n',
            scheduledTime: '08:00',
            dateKey: '2026-10-26',
            status: n == 0 ? FeedingStatus.fed : FeedingStatus.pending,
            fedAt: n == 0 ? DateTime(2026, 10, 26, 8) : null,
            createdAt: DateTime(2026),
            manual: n == 0,
            grams: n == 0 ? 50 : 0,
          ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedingHistoryProvider.overrideWith((ref) => AsyncData(records)),
            ensureTodayForAllPetsProvider.overrideWith((ref) async {}),
          ],
          child: _app(const HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Realizadas'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Max · Manual'), findsOneWidget);
      expect(find.text('1 registros'), findsOneWidget);
      await tester.tap(find.text('Pendientes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Max · Manual'), findsNothing);
      expect(find.text('Max'), findsOneWidget);
    },
  );
  testWidgets(
    'alimento muestra avance real y permite guardar un registro manual',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      await db.doc('users/u/pets/p').set({'name': 'Max'});
      const plan = CarePlan(
        dailyGrams: 150,
        weightKg: 5,
        mealsPerDay: 3,
        food: 'Alimento de Max',
      );
      final pet = Pet(
        id: 'p',
        name: 'Max',
        species: 'Perro',
        breed: '',
        age: 2,
        description: '',
        photoUrl: null,
        createdAt: DateTime(2026),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firestoreProvider.overrideWithValue(db),
            careOwnerIdProvider.overrideWithValue('u'),
            carePlanProvider('p').overrideWith((ref) => Stream.value(plan)),
            medicalRecordsProvider('p').overrideWith((ref) => Stream.value([])),
            feedingHistoryProvider.overrideWith((ref) => const AsyncData([])),
          ],
          child: _app(PetCareScreen(pet: pet)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('150 g al día / 3 comidas = 50 g por comida'),
        findsOneWidget,
      );
      await _capture(tester, 'nutrition');
      await tester.tap(find.text('Registrar comida manual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar comida'));
      await tester.pumpAndSettle();
      final records = await db.collection('users/u/feedingHistory').get();
      expect(records.docs.single.data()['grams'], 50);
      expect(records.docs.single.data()['manual'], isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
