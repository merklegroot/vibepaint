import 'package:flutter_test/flutter_test.dart';
import 'package:vibepaint/services/ai_enhance/ollama_model_utils.dart';

void main() {
  group('parseOllamaModelNames', () {
    test('reads name field', () {
      const body = '''
{
  "models": [
    {
      "name": "x/flux2-klein:latest",
      "model": "x/flux2-klein:latest"
    }
  ]
}
''';

      expect(parseOllamaModelNames(body), ['x/flux2-klein:latest']);
    });

    test('falls back to model field when name is missing', () {
      const body = '''
{
  "models": [
    {
      "model": "x/flux2-klein:latest",
      "size": 5700000000
    }
  ]
}
''';

      expect(parseOllamaModelNames(body), ['x/flux2-klein:latest']);
    });

    test('reads remote_model field', () {
      const body = '''
{
  "models": [
    {
      "remote_model": "x/flux2-klein:latest",
      "remote_host": "https://ollama.com"
    }
  ]
}
''';

      expect(parseOllamaModelNames(body), ['x/flux2-klein:latest']);
    });

    test('handles models null', () {
      expect(parseOllamaModelNames('{"models": null}'), isEmpty);
    });
  });

  group('parseOpenAiModelNames', () {
    test('reads model ids', () {
      const body = '''
{
  "object": "list",
  "data": [
    {"id": "x/flux2-klein:latest"}
  ]
}
''';

      expect(parseOpenAiModelNames(body), ['x/flux2-klein:latest']);
    });

    test('handles null data', () {
      expect(parseOpenAiModelNames('{"object":"list","data":null}'), isEmpty);
    });
  });

  group('ollamaModelProbeCandidates', () {
    test('adds latest tag for untagged model', () {
      expect(
        ollamaModelProbeCandidates('x/flux2-klein'),
        ['x/flux2-klein', 'x/flux2-klein:latest'],
      );
    });
  });

  group('ollamaModelNamesMatch', () {
    test('matches tagged and untagged names', () {
      expect(
        ollamaModelNamesMatch('x/flux2-klein:latest', 'x/flux2-klein'),
        isTrue,
      );
      expect(
        ollamaModelNamesMatch('x/flux2-klein', 'x/flux2-klein:latest'),
        isTrue,
      );
    });

    test('treats variant tags as the same base model', () {
      expect(
        ollamaModelNamesMatch('x/flux2-klein:4b', 'x/flux2-klein:9b'),
        isTrue,
      );
    });
  });

  test('ollamaHasModel finds moondream in tag list', () {
    expect(
      ollamaHasModel(
        const ['llama3.2:latest', 'moondream:latest'],
        'moondream',
      ),
      isTrue,
    );
  });

  group('explainOllamaHttpError', () {
    test('explains missing llama-server on Windows', () {
      const body = r'''
{"error":"error starting llama-server: llama-server binary not found (checked: C:\\Users\\doug\\AppData\\Local\\Programs\\Ollama\\lib\\ollama\\llama-server.exe)"}
''';

      final explained = explainOllamaHttpError(
        statusCode: 500,
        body: body,
        operation: 'generate',
      );

      expect(
        explained.message,
        contains('llama-server missing'),
      );
      expect(explained.details, contains('Windows'));
      expect(explained.details, contains('ollama.com/download/windows'));
    });

    test('uses server error field as message', () {
      const body = '{"error":"model not found"}';

      final explained = explainOllamaHttpError(
        statusCode: 404,
        body: body,
      );

      expect(explained.message, 'model not found');
    });
  });
}
