import '../../domain/entities/area_draft.dart';

class AreaRequestModel {
  final String name;
  final String? description;
  final AreaComponentRequestModel action;
  final List<AreaComponentRequestModel> reactions;

  AreaRequestModel({
    required this.name,
    required this.description,
    required this.action,
    required this.reactions,
  });

  factory AreaRequestModel.fromDraft(AreaDraft draft) {
    return AreaRequestModel(
      name: draft.name,
      description: draft.description,
      action: AreaComponentRequestModel.fromDraft(draft.action),
      reactions: draft.reactions
          .map(AreaComponentRequestModel.fromDraft)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'action': action.toJson(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }
}

class AreaComponentRequestModel {
  final String componentId;
  final Map<String, dynamic> params;

  AreaComponentRequestModel({required this.componentId, required this.params});

  factory AreaComponentRequestModel.fromDraft(AreaComponentDraft draft) {
    return AreaComponentRequestModel(
      componentId: draft.componentId,
      params: draft.params,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{'componentId': componentId};

    if (params.isNotEmpty) {
      final cleanedParams = <String, dynamic>{};

      params.forEach((key, value) {
        if (value == null || (value is String && value.isEmpty)) {
          return;
        }

        if (key == 'frequencyValue' && value is String) {
          final parsed = int.tryParse(value);
          cleanedParams[key] = parsed ?? value;
        } else {
          cleanedParams[key] = value;
        }
      });

      payload['params'] = cleanedParams;
    }

    return payload;
  }
}
