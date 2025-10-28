import 'package:area/features/auth/presentation/blocs/register/register_cubit.dart';
import 'package:area/features/auth/presentation/blocs/register/register_state.dart';
import 'package:area/features/auth/presentation/widgets/forms/register_form.dart';
import 'package:area/features/auth/presentation/widgets/buttons/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/fakes/fake_auth_repository.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  group('RegisterForm', () {
    late TestRegisterCubit cubit;

    setUp(() {
      cubit = TestRegisterCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    testWidgets('submits trimmed credentials when form valid', (tester) async {
      await pumpLocalizedWidget(
        tester,
        BlocProvider<RegisterCubit>.value(
          value: cubit,
          child: const RegisterForm(),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'strongPassword12',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'strongPassword12',
      );

      await tester.tap(find.widgetWithText(AuthButton, 'Create Account'));
      await tester.pumpAndSettle();

      expect(cubit.submissions, isNotEmpty);
      expect(
        cubit.submissions.last,
        ('user@example.com', 'strongPassword12', 'strongPassword12'),
      );
    });

    testWidgets('shows validation errors for invalid email and mismatched passwords', (tester) async {
      await pumpLocalizedWidget(
        tester,
        BlocProvider<RegisterCubit>.value(
          value: cubit,
          child: const RegisterForm(),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'invalid_email',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'short',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'different',
      );

      await tester.tap(find.widgetWithText(AuthButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 12 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(cubit.submissions, isEmpty);
    });

    testWidgets('shows loading indicator while submitting', (tester) async {
      cubit.setState(RegisterLoading());

      await pumpLocalizedWidget(
        tester,
        BlocProvider<RegisterCubit>.value(
          value: cubit,
          child: const RegisterForm(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class TestRegisterCubit extends RegisterCubit {
  TestRegisterCubit() : super(FakeAuthRepository());

  final List<(String, String, String)> submissions = [];

  @override
  Future<void> register(String emailStr, String passwordStr, String confirm) async {
    submissions.add((emailStr, passwordStr, confirm));
  }

  void setState(RegisterState state) => emit(state);
}
