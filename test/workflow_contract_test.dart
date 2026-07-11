import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workflow publishes a direct profile APK release asset', () {
    final yaml = File('.github/workflows/android-build.yml').readAsStringSync();
    expectProfileReleaseWorkflowContract(yaml);
  });

  test('contract rejects misnested workflow triggers', () {
    final yaml = File('.github/workflows/android-build.yml').readAsStringSync();
    final malformed = yaml.replaceFirst('  push:\n', '    push:\n');

    expect(
      () => expectProfileReleaseWorkflowContract(malformed),
      throwsA(anything),
    );
  });
}

void expectProfileReleaseWorkflowContract(String yaml) {
  const triggers = '''on:
  push:
    branches:
      - main
      - 'feat/**'
  workflow_dispatch:
''';
  const permissions = '''permissions:
  contents: write
''';
  const copyProfileApk = r'''      - name: Rename APK with commit
        run: |
          mkdir -p artifacts
          cp build/app/outputs/flutter-apk/app-profile.apk \
            artifacts/keyboardtest-${{ steps.vars.outputs.short_sha }}-profile.apk
''';
  const publishRelease = r'''      - name: Publish profile APK release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          tag="keyboardtest-${{ steps.vars.outputs.short_sha }}"
          apk="artifacts/keyboardtest-${{ steps.vars.outputs.short_sha }}-profile.apk"
          if gh release view "$tag" >/dev/null 2>&1; then
            gh release upload "$tag" "$apk" --clobber
          else
            gh release create "$tag" "$apk" --target "$GITHUB_SHA" \
              --title "keyboardtest ${{ steps.vars.outputs.short_sha }} profile" \
              --notes "Profile APK for commit $GITHUB_SHA"
          fi
          url="https://github.com/${GITHUB_REPOSITORY}/releases/download/${tag}/$(basename "$apk")"
          echo "### Direct profile APK" >> "$GITHUB_STEP_SUMMARY"
          echo "[Download $(basename "$apk")]($url)" >> "$GITHUB_STEP_SUMMARY"
''';
  const analyzeStep = '''      - name: Analyze
        run: flutter analyze''';
  const testStep = '''      - name: Test
        run: flutter test''';
  const buildStep = '''      - name: Build profile APK
        run: flutter build apk --profile''';

  expect(yaml, contains(triggers));
  expect(yaml, contains(permissions));
  expect(yaml, contains(copyProfileApk));
  expect(yaml, contains(publishRelease));
  expect(yaml, isNot(contains('actions/upload-artifact')));

  final analyzeIndex = yaml.indexOf(analyzeStep);
  final testIndex = yaml.indexOf(testStep);
  final buildIndex = yaml.indexOf(buildStep);
  final releaseIndex = yaml.indexOf(publishRelease);
  expect(analyzeIndex, greaterThanOrEqualTo(0));
  expect(testIndex, greaterThan(analyzeIndex));
  expect(buildIndex, greaterThan(testIndex));
  expect(releaseIndex, greaterThan(buildIndex));
}
