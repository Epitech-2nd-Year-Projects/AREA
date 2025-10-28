import 'dart:async';
import 'dart:typed_data';

import 'package:area/features/auth/domain/entities/oauth_provider.dart';
import 'package:area/features/auth/presentation/widgets/buttons/oauth_provider_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  group('OAuthProviderButton', () {
    late _MemoryAssetBundle assetBundle;

    setUp(() {
      final data = Uint8List.fromList(_transparentPixel).buffer.asByteData();
      final manifest = <String, List<Map<String, Object?>>>{
        'assets/icons/google.png': [
          {'asset': 'assets/icons/google.png', 'dpr': 1.0},
        ],
        'assets/icons/facebook.png': [
          {'asset': 'assets/icons/facebook.png', 'dpr': 1.0},
        ],
        'assets/icons/apple.png': [
          {'asset': 'assets/icons/apple.png', 'dpr': 1.0},
        ],
        'assets/icons/applel.png': [
          {'asset': 'assets/icons/applel.png', 'dpr': 1.0},
        ],
      };
      final manifestData =
          const StandardMessageCodec().encodeMessage(manifest) ?? ByteData(0);
      assetBundle = _MemoryAssetBundle({
        'assets/icons/google.png': data,
        'assets/icons/facebook.png': data,
        'assets/icons/apple.png': data,
        'assets/icons/applel.png': data,
        'AssetManifest.bin': manifestData,
      });
    });

    testWidgets('renders provider label and triggers tap', (tester) async {
      var tapped = false;

      await pumpLocalizedWidget(
        tester,
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: SizedBox(
            width: 360,
            child: OAuthProviderButton(
              provider: OAuthProvider.google,
              onPressed: () => tapped = true,
            ),
          ),
        ),
        assetBundle: assetBundle,
      );

      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loader when busy', (tester) async {
      await pumpLocalizedWidget(
        tester,
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: SizedBox(
            width: 360,
            child: OAuthProviderButton(
              provider: OAuthProvider.apple,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
        assetBundle: assetBundle,
      );

      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('adapts layout for large text scale', (tester) async {
      await pumpLocalizedWidget(
        tester,
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 600),
            textScaler: TextScaler.linear(1.5),
          ),
          child: SizedBox(
            width: 280,
            child: OAuthProviderButton(
              provider: OAuthProvider.facebook,
              onPressed: () {},
            ),
          ),
        ),
        assetBundle: assetBundle,
      );

      expect(find.text('Continue with Facebook'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, ByteData> assets;

  @override
  Future<ByteData> load(String key) async {
    final data = assets[key];
    if (data != null) return data;
    throw FlutterError('Asset $key not found');
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData) parser,
  ) async {
    final data =
        assets[key] ??
        const StandardMessageCodec().encodeMessage(const <String, Object?>{}) ??
        ByteData(0);
    return parser(data);
  }
}

const List<int> _transparentPixel = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x60,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE5,
  0x27,
  0xD4,
  0xA7,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
