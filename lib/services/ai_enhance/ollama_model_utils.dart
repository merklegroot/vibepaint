import 'dart:convert';

/// Parses installed model names from an Ollama `GET /api/tags` response.
List<String> parseOllamaModelNames(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return const [];
    }

    final models = decoded['models'];
    if (models == null) {
      return const [];
    }
    if (models is! List) {
      return const [];
    }

    final names = <String>{};
    for (final entry in models) {
      final name = _entryModelName(entry);
      if (name != null) {
        names.add(name);
      }
    }
    return names.toList();
  } on FormatException {
    return const [];
  }
}

/// Parses model ids from an OpenAI-compatible `GET /v1/models` response.
List<String> parseOpenAiModelNames(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return const [];
    }

    final data = decoded['data'];
    if (data == null) {
      return const [];
    }
    if (data is! List) {
      return const [];
    }

    final names = <String>{};
    for (final entry in data) {
      if (entry is Map) {
        final id = entry['id']?.toString().trim();
        if (id != null && id.isNotEmpty) {
          names.add(id);
        }
      } else if (entry is String && entry.trim().isNotEmpty) {
        names.add(entry.trim());
      }
    }
    return names.toList();
  } on FormatException {
    return const [];
  }
}

String? _entryModelName(Object? entry) {
  if (entry is String) {
    final trimmed = entry.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (entry is! Map) {
    return null;
  }

  for (final key in const ['name', 'model', 'remote_model']) {
    final value = entry[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

/// Candidate model ids to probe with `POST /api/show`.
List<String> ollamaModelProbeCandidates(String model) {
  final trimmed = model.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  final candidates = <String>{trimmed};
  if (!trimmed.contains(':')) {
    candidates.add('$trimmed:latest');
  }
  return candidates.toList();
}

/// Base model id without an optional `:tag` suffix.
String ollamaModelBaseName(String name) {
  final trimmed = name.trim().toLowerCase();
  final colon = trimmed.indexOf(':');
  if (colon < 0) {
    return trimmed;
  }
  return trimmed.substring(0, colon);
}

/// Whether [available] satisfies a request for [target] (tag optional).
bool ollamaModelNamesMatch(String available, String target) {
  return ollamaModelBaseName(available) == ollamaModelBaseName(target);
}

/// Whether any installed [available] model satisfies [target].
bool ollamaHasModel(Iterable<String> available, String target) {
  return available.any((name) => ollamaModelNamesMatch(name, target));
}
