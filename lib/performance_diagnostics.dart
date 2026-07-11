import 'dart:collection';

abstract interface class DiagnosticSample {
  String format();
}

final class FrameBudget {
  const FrameBudget(this.milliseconds);

  final double milliseconds;

  factory FrameBudget.fromRefreshRate(double refreshRate) {
    final effectiveRefreshRate = refreshRate.isFinite && refreshRate > 0
        ? refreshRate
        : 60.0;
    return FrameBudget(1000 / effectiveRefreshRate);
  }

  factory FrameBudget.fromObservedVsync({
    required double refreshRate,
    required List<double> observedVsyncMs,
  }) {
    final validIntervals =
        observedVsyncMs
            .where((interval) => interval.isFinite && interval > 0)
            .toList(growable: false)
          ..sort();
    if (validIntervals.length < 3) {
      return FrameBudget.fromRefreshRate(refreshRate);
    }

    final middle = validIntervals.length ~/ 2;
    final median = validIntervals.length.isOdd
        ? validIntervals[middle]
        : (validIntervals[middle - 1] + validIntervals[middle]) / 2;
    return FrameBudget(median);
  }
}

final class TextDiagnosticSample implements DiagnosticSample {
  const TextDiagnosticSample(this.text);

  final String text;

  @override
  String format() => text;
}

final class MotionDiagnosticSample implements DiagnosticSample {
  const MotionDiagnosticSample({
    required this.sequence,
    required this.rawInset,
    required this.safeBottom,
    required this.targetLift,
    required this.visualLift,
    required this.lagPx,
    required this.source,
    required this.metricsArrivalUs,
    required this.transformBuildUs,
    required this.postFrameUs,
  });

  final int sequence;
  final double rawInset;
  final double safeBottom;
  final double targetLift;
  final double visualLift;
  final double lagPx;
  final String source;
  final int metricsArrivalUs;
  final int transformBuildUs;
  final int postFrameUs;

  @override
  String format() {
    final metricsToBuildMs =
        (transformBuildUs - metricsArrivalUs) /
        Duration.microsecondsPerMillisecond;
    final metricsToPostFrameMs =
        (postFrameUs - metricsArrivalUs) / Duration.microsecondsPerMillisecond;
    return 'motion seq=$sequence '
        'raw=${rawInset.toStringAsFixed(1)} '
        'safe=${safeBottom.toStringAsFixed(1)} '
        'targetLift=${targetLift.toStringAsFixed(1)} '
        'visualLift=${visualLift.toStringAsFixed(1)} '
        'lagPx=${lagPx.toStringAsFixed(1)} '
        'source=$source '
        'metricsToBuildMs=${metricsToBuildMs.toStringAsFixed(1)} '
        'metricsToPostFrameMs=${metricsToPostFrameMs.toStringAsFixed(1)}';
  }
}

final class FrameDiagnosticSample implements DiagnosticSample {
  const FrameDiagnosticSample({
    required this.buildMs,
    required this.rasterMs,
    required this.totalSpanMs,
    required this.vsyncOverheadMs,
    required this.vsyncDeltaMs,
    required this.refreshRate,
    required this.budgetMs,
    required this.frameNumber,
    required this.latestMotionSequence,
  });

  final double buildMs;
  final double rasterMs;
  final double totalSpanMs;
  final double vsyncOverheadMs;
  final double vsyncDeltaMs;
  final double refreshRate;
  final double budgetMs;
  final int frameNumber;
  final int latestMotionSequence;

  @override
  String format() {
    return 'frame frameNumber=$frameNumber '
        'buildMs=${buildMs.toStringAsFixed(1)} '
        'rasterMs=${rasterMs.toStringAsFixed(1)} '
        'totalSpanMs=${totalSpanMs.toStringAsFixed(1)} '
        'vsyncOverheadMs=${vsyncOverheadMs.toStringAsFixed(1)} '
        'vsyncDeltaMs=${vsyncDeltaMs.toStringAsFixed(1)} '
        'refreshRate=${refreshRate.toStringAsFixed(1)} '
        'budgetMs=${budgetMs.toStringAsFixed(1)} '
        'latestMotionSequence=$latestMotionSequence';
  }
}

final class PerformanceSummary {
  const PerformanceSummary({
    required this.frameCount,
    required this.p95BuildMs,
    required this.p95RasterMs,
    required this.p95TotalSpanMs,
    required this.buildOverBudgetCount,
    required this.rasterOverBudgetCount,
    required this.buildOverTwoBudgetsCount,
    required this.rasterOverTwoBudgetsCount,
  });

  factory PerformanceSummary.fromFrames(
    Iterable<FrameDiagnosticSample> frames,
  ) {
    final samples = frames.toList(growable: false);
    return PerformanceSummary(
      frameCount: samples.length,
      p95BuildMs: _percentile95(samples.map((frame) => frame.buildMs)),
      p95RasterMs: _percentile95(samples.map((frame) => frame.rasterMs)),
      p95TotalSpanMs: _percentile95(samples.map((frame) => frame.totalSpanMs)),
      buildOverBudgetCount: samples
          .where((frame) => frame.buildMs > frame.budgetMs)
          .length,
      rasterOverBudgetCount: samples
          .where((frame) => frame.rasterMs > frame.budgetMs)
          .length,
      buildOverTwoBudgetsCount: samples
          .where((frame) => frame.buildMs > frame.budgetMs * 2)
          .length,
      rasterOverTwoBudgetsCount: samples
          .where((frame) => frame.rasterMs > frame.budgetMs * 2)
          .length,
    );
  }

  final int frameCount;
  final double p95BuildMs;
  final double p95RasterMs;
  final double p95TotalSpanMs;
  final int buildOverBudgetCount;
  final int rasterOverBudgetCount;
  final int buildOverTwoBudgetsCount;
  final int rasterOverTwoBudgetsCount;

  static double _percentile95(Iterable<double> values) {
    final sorted = values.toList(growable: false)..sort();
    if (sorted.isEmpty) return 0;

    final position = (sorted.length - 1) * 0.95;
    final lowerIndex = position.floor();
    final upperIndex = position.ceil();
    if (lowerIndex == upperIndex) return sorted[lowerIndex];

    final fraction = position - lowerIndex;
    return sorted[lowerIndex] +
        (sorted[upperIndex] - sorted[lowerIndex]) * fraction;
  }
}

final class FrameDiagnosticRingBuffer
    extends IterableBase<FrameDiagnosticSample> {
  FrameDiagnosticRingBuffer({required this.capacity})
    : _frames = _createStorage(capacity);

  final int capacity;
  final List<FrameDiagnosticSample?> _frames;
  var _start = 0;
  var _length = 0;

  static List<FrameDiagnosticSample?> _createStorage(int capacity) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
    return List<FrameDiagnosticSample?>.filled(capacity, null, growable: false);
  }

  void add(FrameDiagnosticSample sample) {
    if (_length < capacity) {
      _frames[(_start + _length) % capacity] = sample;
      _length += 1;
      return;
    }

    _frames[_start] = sample;
    _start = (_start + 1) % capacity;
  }

  void clear() {
    _frames.fillRange(0, capacity, null);
    _start = 0;
    _length = 0;
  }

  @override
  int get length => _length;

  @override
  Iterator<FrameDiagnosticSample> get iterator => _orderedFrames().iterator;

  Iterable<FrameDiagnosticSample> _orderedFrames() sync* {
    for (var offset = 0; offset < _length; offset += 1) {
      yield _frames[(_start + offset) % capacity]!;
    }
  }
}

final class DiagnosticRingBuffer {
  DiagnosticRingBuffer({required this.capacity})
    : _samples = _createStorage(capacity);

  final int capacity;
  final List<DiagnosticSample?> _samples;
  var _start = 0;
  var _length = 0;

  static List<DiagnosticSample?> _createStorage(int capacity) {
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be positive');
    }
    return List<DiagnosticSample?>.filled(capacity, null, growable: false);
  }

  void add(DiagnosticSample sample) {
    if (_length < capacity) {
      _samples[(_start + _length) % capacity] = sample;
      _length += 1;
      return;
    }

    _samples[_start] = sample;
    _start = (_start + 1) % capacity;
  }

  void clear() {
    _samples.fillRange(0, capacity, null);
    _start = 0;
    _length = 0;
  }

  String get formattedText => _formatTail(_length);

  List<String> get formattedEntries => List<String>.unmodifiable(
    Iterable<String>.generate(
      _length,
      (offset) => _samples[(_start + offset) % capacity]!.format(),
    ),
  );

  String formattedTail(int count) {
    if (count <= 0) return '';
    return _formatTail(count.clamp(0, _length));
  }

  String _formatTail(int count) {
    final output = StringBuffer();
    final logicalStart = _length - count;
    for (var offset = 0; offset < count; offset += 1) {
      if (offset > 0) output.write('\n');
      final index = (_start + logicalStart + offset) % capacity;
      output.write(_samples[index]!.format());
    }
    return output.toString();
  }
}
