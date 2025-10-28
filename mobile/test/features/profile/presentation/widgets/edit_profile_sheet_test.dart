import 'dart:async';

import 'package:area/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:area/features/profile/presentation/cubits/profile_state.dart';
import 'package:area/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:area/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';

class _MockProfileCubit extends Mock implements ProfileCubit {}

void main() {
  final binding =
      TestWidgetsFlutterBinding.ensureInitialized()
          as TestWidgetsFlutterBinding;

  setUpAll(() {
    registerFallbackValue(const ProfileInitial());
  });

  setUp(() {
    binding.window.physicalSizeTestValue = const Size(1200, 2000);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  _MockProfileCubit buildCubit(ProfileLoaded state) {
    final cubit = _MockProfileCubit();
    when(() => cubit.state).thenReturn(state);
    when(
      () => cubit.stream,
    ).thenAnswer((_) => const Stream<ProfileState>.empty());
    return cubit;
  }

  testWidgets('submits updated profile and closes sheet on success', (
    tester,
  ) async {
    final state = buildProfileLoadedState(
      displayName: 'Alex',
      email: 'alex@example.com',
    );
    final cubit = buildCubit(state);
    when(
      () => cubit.updateProfile(
        newName: any(named: 'newName'),
        newEmail: any(named: 'newEmail'),
      ),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ProfileCubit>.value(
            value: cubit,
            child: EditProfileSheet(state: state),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'Alex Doe');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'alex.doe@example.com',
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    verify(
      () => cubit.updateProfile(
        newName: 'Alex Doe',
        newEmail: 'alex.doe@example.com',
      ),
    ).called(1);

    await tester.pumpAndSettle();

    expect(find.byType(EditProfileSheet), findsNothing);
  });

  testWidgets('shows feedback when saving fails', (tester) async {
    final state = buildProfileLoadedState(
      displayName: 'Taylor',
      email: 'taylor@example.com',
    );
    final cubit = buildCubit(state);
    when(
      () => cubit.updateProfile(
        newName: any(named: 'newName'),
        newEmail: any(named: 'newEmail'),
      ),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ProfileCubit>.value(
            value: cubit,
            child: EditProfileSheet(state: state),
          ),
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump();

    verify(
      () => cubit.updateProfile(
        newName: 'Taylor',
        newEmail: 'taylor@example.com',
      ),
    ).called(1);

    await tester.pumpAndSettle();

    expect(find.text('Failed to update profile'), findsOneWidget);
    final Finder buttonFinder = find.byWidgetPredicate(
      (widget) => widget is FilledButton,
    );
    expect(buttonFinder, findsOneWidget);

    final FilledButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);
  });
}
