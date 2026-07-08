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

/// Parses the `error` field from an Ollama HTTP error body.
String? parseOllamaErrorMessage(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return null;
    }
    final error = decoded['error']?.toString().trim();
    if (error == null || error.isEmpty) {
      return null;
    }
    return error;
  } on FormatException {
    return null;
  }
}

/// User-facing message and optional details for a failed Ollama HTTP call.
({String message, String? details}) explainOllamaHttpError({
  required int statusCode,
  required String body,
  String operation = 'request',
}) {
  final serverError = parseOllamaErrorMessage(body);
  final trimmedBody = body.trim();

  if (serverError != null &&
      serverError.contains('llama-server binary not found')) {
    return (
      message: 'Remote Ollama install is broken (llama-server missing).',
      details:
          'The Windows Ollama server cannot run models because '
          'llama-server.exe is missing. This is a server install issue, '
          'not a VibePaint bug.\n\n'
          'On the Windows machine:\n'
          '1. Quit Ollama from the system tray\n'
          '2. Reinstall from https://ollama.com/download/windows\n'
          '3. Run: ollama pull moondream\n'
          '4. Test: ollama run moondream "hello"\n\n'
          'Server reported:\n$serverError',
    );
  }

  if (serverError != null) {
    return (
      message: serverError,
      details: 'HTTP $statusCode during Ollama $operation.',
    );
  }

  return (
    message: 'Ollama $operation failed (HTTP $statusCode).',
    details: trimmedBody.isEmpty ? null : trimmedBody,
  );
}
