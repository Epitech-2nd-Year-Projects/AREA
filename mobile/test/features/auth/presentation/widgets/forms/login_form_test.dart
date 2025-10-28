import 'package:area/features/auth/presentation/blocs/login/login_cubit.dart';
import 'package:area/features/auth/presentation/blocs/login/login_state.dart';
import 'package:area/features/auth/presentation/widgets/forms/login_form.dart';
import 'package:area/features/auth/presentation/widgets/buttons/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/fakes/fake_auth_repository.dart';

void main() {
  group('LoginForm', () {
    late TestLoginCubit cubit;

    setUp(() {
      cubit = TestLoginCubit();
    });

    tearDown(() async {
      await cubit.close();
    });

    testWidgets('submits trimmed credentials when form valid', (tester) async {
      await pumpLocalizedWidget(
        tester,
        BlocProvider<LoginCubit>.value(
          value: cubit,
          child: const LoginForm(),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(cubit.submittedCredentials, isNotEmpty);
      expect(
        cubit.submittedCredentials.last,
        ('user@example.com', 'password123'),
      );
    });

    testWidgets('shows validation errors when fields empty', (tester) async {
      await pumpLocalizedWidget(
        tester,
        BlocProvider<LoginCubit>.value(
          value: cubit,
          child: const LoginForm(),
        ),
      );

      await tester.tap(find.byType(AuthButton));
      await tester.pump();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(cubit.submittedCredentials, isEmpty);
    });

    testWidgets('shows loading indicator when logging in', (tester) async {
      cubit.setState(LoginLoading());

      await pumpLocalizedWidget(
        tester,
        BlocProvider<LoginCubit>.value(
          value: cubit,
          child: const LoginForm(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class TestLoginCubit extends LoginCubit {
  TestLoginCubit() : super(FakeAuthRepository());

  final List<(String, String)> submittedCredentials = [];

  @override
  Future<void> login(String emailStr, String passwordStr) async {
    submittedCredentials.add((emailStr, passwordStr));
  }

  void setState(LoginState state) => emit(state);
}
