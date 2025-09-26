import 'package:equatable/equatable.dart';

class AboutInfo extends Equatable {
  final String clientHost;
  final int currentTime;
  final List<AboutService> services;

  const AboutInfo({
    required this.clientHost,
    required this.currentTime,
    required this.services,
  });

  @override
  List<Object?> get props => [clientHost, currentTime, services];
}

class AboutService extends Equatable {
  final String name;
  final List<AboutAction> actions;
  final List<AboutReaction> reactions;

  const AboutService({
    required this.name,
    required this.actions,
    required this.reactions,
  });

  @override
  List<Object?> get props => [name, actions, reactions];
}

class AboutAction extends Equatable {
  final String name;
  final String description;

  const AboutAction({
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => [name, description];
}

class AboutReaction extends Equatable {
  final String name;
  final String description;

  const AboutReaction({
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => [name, description];
}