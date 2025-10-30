import '../../domain/entities/about_info.dart';

class AboutInfoModel {
  final ClientModel client;
  final ServerModel server;

  AboutInfoModel({required this.client, required this.server});

  factory AboutInfoModel.fromJson(Map<String, dynamic> json) {
    return AboutInfoModel(
      client: ClientModel.fromJson(json['client'] ?? {}),
      server: ServerModel.fromJson(json['server'] ?? {}),
    );
  }

  AboutInfo toEntity() {
    return AboutInfo(
      clientHost: client.host,
      currentTime: server.currentTime,
      services: server.services.map((s) => s.toEntity()).toList(),
    );
  }
}

class ClientModel {
  final String host;

  ClientModel({required this.host});

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(host: json['host'] ?? 'unknown');
  }
}

class ServerModel {
  final int currentTime;
  final List<AboutServiceModel> services;

  ServerModel({required this.currentTime, required this.services});

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      currentTime:
          json['current_time'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      services:
          (json['services'] as List<dynamic>?)
              ?.map(
                (s) => AboutServiceModel.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class AboutServiceModel {
  final String name;
  final List<AboutActionModel> actions;
  final List<AboutReactionModel> reactions;

  AboutServiceModel({
    required this.name,
    required this.actions,
    required this.reactions,
  });

  factory AboutServiceModel.fromJson(Map<String, dynamic> json) {
    return AboutServiceModel(
      name: json['name'] ?? '',
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((a) => AboutActionModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map(
                (r) => AboutReactionModel.fromJson(r as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  AboutService toEntity() {
    return AboutService(
      name: name,
      actions: actions.map((a) => a.toEntity()).toList(),
      reactions: reactions.map((r) => r.toEntity()).toList(),
    );
  }
}

class AboutActionModel {
  final String name;
  final String description;

  AboutActionModel({required this.name, required this.description});

  factory AboutActionModel.fromJson(Map<String, dynamic> json) {
    return AboutActionModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  AboutAction toEntity() {
    return AboutAction(name: name, description: description);
  }
}

class AboutReactionModel {
  final String name;
  final String description;

  AboutReactionModel({required this.name, required this.description});

  factory AboutReactionModel.fromJson(Map<String, dynamic> json) {
    return AboutReactionModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  AboutReaction toEntity() {
    return AboutReaction(name: name, description: description);
  }
}
