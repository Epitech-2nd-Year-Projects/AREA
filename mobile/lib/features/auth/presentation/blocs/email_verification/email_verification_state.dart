import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class EmailVerificationState extends Equatable {
  const EmailVerificationState();

  @override
  List<Object?> get props => [];
}

class EmailVerificationInitial extends EmailVerificationState {}

class EmailVerificationLoading extends EmailVerificationState {}

class EmailVerificationSuccess extends EmailVerificationState {
  final User user;
  const EmailVerificationSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class EmailVerificationError extends EmailVerificationState {
  final String message;
  const EmailVerificationError(this.message);

  @override
  List<Object?> get props => [message];
}