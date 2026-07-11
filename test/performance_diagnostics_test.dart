import 'package:flutter_test/flutter_test.dart';
import 'package:keyboardtest/performance_diagnostics.dart';

void main() {
  group('FrameBudget', () {
    test('follows display refresh and observed vsync', () {
      expect(
        FrameBudget.fromRefreshRate(60).milliseconds,
        closeTo(16.67, 0.01),
      );
      expect(
        FrameBudget.fromRefreshRate(120).milliseconds,
        closeTo(8.33, 0.01),
      );

      final observed = FrameBudget.fromObservedVsync(
        refreshRate: 120,
        observedVsyncMs: const [16.6, 16.7, 16.8],
      );

      expect(observed.milliseconds, closeTo(16.7, 0.1));
    });

    test('uses only valid observations and otherwise falls back safely', () {
      final observed = FrameBudget.fromObservedVsync(
        refreshRate: 120,
        observedVsyncMs: const [double.nan, -1, 8.2, 8.4, 8.6],
      );
      expect(observed.milliseconds, closeTo(8.4, 0.001));

      final insufficient = FrameBudget.fromObservedVsync(
        refreshRate: 120,
        observedVsyncMs: const [8.2, 8.4],
      );
      expect(insufficient.milliseconds, closeTo(1000 / 120, 0.001));
      expect(
        FrameBudget.fromRefreshRate(0).milliseconds,
        closeTo(1000 / 60, 0.001),
      );
      expect(
        FrameBudget.fromRefreshRate(double.infinity).milliseconds,
        closeTo(1000 / 60, 0.001),
      );
    });
  });

  group('DiagnosticRingBuffer', () {
    test('is bounded and formats only on demand', () {
      var formatCalls = 0;
      final buffer = DiagnosticRingBuffer(capacity: 2);
      buffer.add(FakeSample('one', () => formatCalls += 1));
      buffer.add(FakeSample('two', () => formatCalls += 1));
      buffer.add(FakeSample('three', () => formatCalls += 1));

      expect(formatCalls, 0);
      expect(buffer.formattedText, 'two\nthree');
      expect(formatCalls, 2);
    });

    test('formats only the requested tail and can be cleared', () {
      var formatCalls = 0;
      final buffer = DiagnosticRingBuffer(capacity: 3);
      buffer.add(FakeSample('one', () => formatCalls += 1));
      buffer.add(FakeSample('two', () => formatCalls += 1));
      buffer.add(FakeSample('three', () => formatCalls += 1));

      expect(buffer.formattedTail(2), 'two\nthree');
      expect(formatCalls, 2);
      expect(buffer.formattedTail(0), isEmpty);
      expect(formatCalls, 2);

      buffer.clear();
      expect(buffer.formattedText, isEmpty);
      expect(formatCalls, 2);
    });

    test('requires a positive capacity', () {
      expect(() => DiagnosticRingBuffer(capacity: 0), throwsArgumentError);
    });
  });

  group('diagnostic samples', () {
    test('text, motion, and frame samples format their stored values', () {
      expect(const TextDiagnosticSample('plain text').format(), 'plain text');

      const motion = MotionDiagnosticSample(
        sequence: 7,
        rawInset: 240,
        safeBottom: 24,
        targetLift: 216,
        visualLift: 215.5,
        lagPx: 0.5,
        source: 'imeDirect',
        metricsArrivalUs: 1000,
        transformBuildUs: 2500,
        postFrameUs: 5000,
      );
      final motionText = motion.format();
      expect(motionText, contains('seq=7'));
      expect(motionText, contains('raw=240.0'));
      expect(motionText, contains('metricsToBuildMs=1.5'));
      expect(motionText, contains('metricsToPostFrameMs=4.0'));
      expect('metricsToBuildMs='.allMatches(motionText), hasLength(1));

      final frameText = frame(
        buildMs: 3,
        rasterMs: 4,
        totalSpanMs: 12,
        frameNumber: 42,
      ).format();
      expect(frameText, contains('frameNumber=42'));
      expect(frameText, contains('buildMs=3.0'));
      expect(frameText, contains('rasterMs=4.0'));
      expect(frameText, contains('totalSpanMs=12.0'));
      expect(frameText, contains('vsyncOverheadMs=1.5'));
      expect(frameText, contains('vsyncDeltaMs=16.7'));
      expect(frameText, contains('refreshRate=60.0'));
      expect(frameText, contains('budgetMs=16.7'));
      expect(frameText, contains('latestMotionSequence=9'));
      expect('buildMs='.allMatches(frameText), hasLength(1));
    });
  });

  group('PerformanceSummary', () {
    test('classifies build and raster overruns independently', () {
      final summary = PerformanceSummary.fromFrames([
        frame(buildMs: 20, rasterMs: 5, totalSpanMs: 40),
        frame(buildMs: 5, rasterMs: 20, totalSpanMs: 60),
      ]);

      expect(summary.frameCount, 2);
      expect(summary.buildOverBudgetCount, 1);
      expect(summary.rasterOverBudgetCount, 1);
      expect(summary.buildOverTwoBudgetsCount, 0);
      expect(summary.rasterOverTwoBudgetsCount, 0);
      expect(summary.p95BuildMs, closeTo(19.25, 0.001));
      expect(summary.p95RasterMs, closeTo(19.25, 0.001));
      expect(summary.p95TotalSpanMs, closeTo(59, 0.001));
    });

    test('counts frames above two individual budgets', () {
      final summary = PerformanceSummary.fromFrames([
        frame(buildMs: 34, rasterMs: 4, totalSpanMs: 38),
        frame(buildMs: 4, rasterMs: 34, totalSpanMs: 38),
      ]);

      expect(summary.buildOverBudgetCount, 1);
      expect(summary.rasterOverBudgetCount, 1);
      expect(summary.buildOverTwoBudgetsCount, 1);
      expect(summary.rasterOverTwoBudgetsCount, 1);
    });

    test('uses linear interpolation for p95 and handles no frames', () {
      final summary = PerformanceSummary.fromFrames([
        frame(buildMs: 0, rasterMs: 30, totalSpanMs: 10),
        frame(buildMs: 10, rasterMs: 20, totalSpanMs: 20),
        frame(buildMs: 20, rasterMs: 10, totalSpanMs: 30),
      ]);

      expect(summary.p95BuildMs, closeTo(19, 0.001));
      expect(summary.p95RasterMs, closeTo(29, 0.001));
      expect(summary.p95TotalSpanMs, closeTo(29, 0.001));

      final empty = PerformanceSummary.fromFrames(const []);
      expect(empty.frameCount, 0);
      expect(empty.p95BuildMs, 0);
      expect(empty.p95RasterMs, 0);
      expect(empty.p95TotalSpanMs, 0);
    });
  });
}

FrameDiagnosticSample frame({
  required double buildMs,
  required double rasterMs,
  required double totalSpanMs,
  int frameNumber = 1,
}) {
  return FrameDiagnosticSample(
    buildMs: buildMs,
    rasterMs: rasterMs,
    totalSpanMs: totalSpanMs,
    vsyncOverheadMs: 1.5,
    vsyncDeltaMs: 16.7,
    refreshRate: 60,
    budgetMs: 16.67,
    frameNumber: frameNumber,
    latestMotionSequence: 9,
  );
}

final class FakeSample implements DiagnosticSample {
  FakeSample(this.value, this.onFormat);

  final String value;
  final void Function() onFormat;

  @override
  String format() {
    onFormat();
    return value;
  }
}
