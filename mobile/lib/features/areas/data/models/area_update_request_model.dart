import 'package:collection/collection.dart';

import '../../domain/entities/area.dart';
import '../../domain/entities/area_draft.dart';

class AreaUpdateRequestModel {
  AreaUpdateRequestModel({
    required this.name,
    required this.includeName,
    required this.description,
    required this.includeDescription,
    required this.action,
    required this.reactions,
  });

  final String? name;
  final bool includeName;
  final String? description;
  final bool includeDescription;
  final AreaUpdateComponentModel? action;
  final List<AreaUpdateComponentModel> reactions;

  bool get isEmpty =>
      !includeName && !includeDescription && action == null && reactions.isEmpty;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};
    if (includeName) {
      payload['name'] = name;
    }
    if (includeDescription) {
      payload['description'] = description;
    }
    if (action != null) {
      payload['action'] = action!.toJson();
    }
    if (reactions.isNotEmpty) {
      payload['reactions'] = reactions.map((reaction) => reaction.toJson()).toList();
    }
    return payload;
  }

  static AreaUpdateRequestModel fromArea(Area initial, AreaDraft draft) {
    final sanitizedName = draft.name.trim();
    if (sanitizedName.isEmpty) {
      throw Exception('Automation name cannot be empty.');
    }
    final includeName = sanitizedName != initial.name.trim();

    final normalizedDraftDescription = _normalizeOptional(draft.description);
    final normalizedInitialDescription = _normalizeOptional(initial.description);
    final includeDescription = normalizedDraftDescription != normalizedInitialDescription;

    final actionBinding = initial.action;
    if (draft.action.componentId != actionBinding.component.id) {
      throw Exception(
        'Changing the action component is not supported. Create a new automation instead.',
      );
    }
    if (actionBinding.configId.isEmpty) {
      throw Exception('The current automation is misconfigured (missing action config).');
    }

    final normalizedDraftActionName = _normalizeOptional(draft.action.name);
    final normalizedInitialActionName = _normalizeOptional(actionBinding.name);

    final sanitizedDraftActionParams = _sanitizeParams(draft.action.params);
    final sanitizedInitialActionParams = _sanitizeParams(actionBinding.params);
    final paramsEquality = const DeepCollectionEquality();
    final actionParamsChanged =
        !paramsEquality.equals(sanitizedInitialActionParams, sanitizedDraftActionParams);
    final actionNameChanged = normalizedDraftActionName != normalizedInitialActionName;

    AreaUpdateComponentModel? actionModel;
    if (actionNameChanged || actionParamsChanged) {
      actionModel = AreaUpdateComponentModel(
        configId: actionBinding.configId,
        includeName: actionNameChanged,
        name: normalizedDraftActionName,
        includeParams: actionParamsChanged,
        params: sanitizedDraftActionParams,
      );
    }

    if (draft.reactions.length != initial.reactions.length) {
      throw Exception(
        'Adding or removing reactions during edit is not supported. '
        'Create a new automation to change the reaction list.',
      );
    }

    final reactionUpdates = <AreaUpdateComponentModel>[];
    for (var i = 0; i < initial.reactions.length; i++) {
      final current = initial.reactions[i];
      final updated = draft.reactions[i];

      if (updated.componentId != current.component.id) {
        throw Exception(
          'Changing reaction components during edit is not supported. '
          'Create a new automation instead.',
        );
      }
      if (current.configId.isEmpty) {
        throw Exception('The current automation is misconfigured (missing reaction config).');
      }

      final normalizedUpdatedName = _normalizeOptional(updated.name);
      final normalizedCurrentName = _normalizeOptional(current.name);
      final nameChanged = normalizedUpdatedName != normalizedCurrentName;

      final sanitizedUpdatedParams = _sanitizeParams(updated.params);
      final sanitizedCurrentParams = _sanitizeParams(current.params);
      final paramsChanged =
          !paramsEquality.equals(sanitizedCurrentParams, sanitizedUpdatedParams);

      if (nameChanged || paramsChanged) {
        reactionUpdates.add(
          AreaUpdateComponentModel(
            configId: current.configId,
            includeName: nameChanged,
            name: normalizedUpdatedName,
            includeParams: paramsChanged,
            params: sanitizedUpdatedParams,
          ),
        );
      }
    }

    return AreaUpdateRequestModel(
      name: sanitizedName,
      includeName: includeName,
      description: normalizedDraftDescription,
      includeDescription: includeDescription,
      action: actionModel,
      reactions: reactionUpdates,
    );
  }
}

class AreaUpdateComponentModel {
  AreaUpdateComponentModel({
    required this.configId,
    required this.includeName,
    required this.name,
    required this.includeParams,
    required this.params,
  });

  final String configId;
  final bool includeName;
  final String? name;
  final bool includeParams;
  final Map<String, dynamic> params;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{'configId': configId};
    if (includeName) {
      payload['name'] = name;
    }
    if (includeParams) {
      payload['params'] = params;
    }
    return payload;
  }
}

String? _normalizeOptional(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _sanitizeParams(Map<String, dynamic> params) {
  final cleaned = <String, dynamic>{};
  params.forEach((key, value) {
    if (value == null) return;
    if (value is String && value.isEmpty) {
      return;
    }

    if (value is String && key == 'frequencyValue') {
      final parsed = int.tryParse(value);
      cleaned[key] = parsed ?? value;
    } else {
      cleaned[key] = value;
    }
  });
  return cleaned;
}
