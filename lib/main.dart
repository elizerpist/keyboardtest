import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'performance_diagnostics.dart';

void main() {
  runApp(const KeyboardTestApp());
}

class KeyboardTestApp extends StatelessWidget {
  const KeyboardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'keyboardtest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF147A73)),
        useMaterial3: true,
      ),
      home: const KeyboardTestHome(),
    );
  }
}

class KeyboardInputWarmup {
  KeyboardInputWarmup._();

  static final _client = _KeyboardWarmupTextInputClient();
  static var _scheduled = false;
  static var _ready = false;

  static bool get isReady => _ready;

  static void ensureScheduled() {
    if (_scheduled) return;
    _scheduled = true;
    TextInput.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warm());
  }

  static void _warm() {
    if (_ready) return;
    final connection = TextInput.attach(
      _client,
      const TextInputConfiguration(
        inputType: TextInputType.none,
        inputAction: TextInputAction.none,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
      ),
    );
    connection.setEditingState(TextEditingValue.empty);
    connection.close();
    _ready = true;
  }
}

class _KeyboardWarmupTextInputClient with TextInputClient {
  const _KeyboardWarmupTextInputClient();

  @override
  TextEditingValue? get currentTextEditingValue => TextEditingValue.empty;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {}

  @override
  void performAction(TextInputAction action) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {}
}

class KeyboardTestHome extends StatefulWidget {
  const KeyboardTestHome({super.key});

  @override
  State<KeyboardTestHome> createState() => _KeyboardTestHomeState();
}

class _KeyboardTestHomeState extends State<KeyboardTestHome> {
  var _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    KeyboardInputWarmup.ensureScheduled();
  }

  void _openSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    KeyboardInputWarmup.ensureScheduled();
    DebugBuildStats.reset();
    DebugPerformanceProbe.resetSession();
    DebugConsole.clear();
    DebugPerformanceProbe.ensureStarted();
    DebugConsole.log('sheet open');
    DebugConsole.log('text input prewarm ready=${KeyboardInputWarmup.isReady}');
    setState(() => _sheetOpen = true);
  }

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    DebugConsole.log('sheet close');
    setState(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4F0E8),
      body: Stack(
        children: [
          const _HomeSurface(),
          if (_sheetOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('keyboardtest-backdrop'),
                behavior: HitTestBehavior.opaque,
                onTap: _closeSheet,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),
            const KeyboardMotionLayer(),
          ],
          const DebugFloatingButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('keyboardtest-open-sheet-fab'),
        onPressed: _openSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomeSurface extends StatelessWidget {
  const _HomeSurface();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'keyboardtest',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF243633),
        ),
      ),
    );
  }
}

class KeyboardMotionMetrics {
  const KeyboardMotionMetrics({
    required this.rawInset,
    required this.safeBottom,
    required this.spacing,
    double? visualLift,
    this.source = 'imeDirect',
    this.bridgeMs = 0,
    this.bridgedGap = false,
  }) : _visualLift = visualLift;

  factory KeyboardMotionMetrics.fromContext(BuildContext context) {
    return KeyboardMotionMetrics(
      rawInset: MediaQuery.viewInsetsOf(context).bottom,
      safeBottom: MediaQuery.viewPaddingOf(context).bottom,
      spacing: 12,
    );
  }

  final double rawInset;
  final double safeBottom;
  final double spacing;
  final double? _visualLift;
  final String source;
  final int bridgeMs;
  final bool bridgedGap;

  double get layerPillBottom => safeBottom + spacing;
  double get targetLift => math.max(rawInset - safeBottom, 0);
  double get visualLift => _visualLift ?? targetLift;
  double get keyboardLift => targetLift;
  double get dockBottom => layerPillBottom + visualLift;
  double get sheetTranslation => -visualLift;
  double get lagPx => targetLift - visualLift;

  KeyboardMotionMetrics withVisualLift(
    double lift, {
    required String source,
    required int bridgeMs,
    required bool bridgedGap,
  }) {
    return KeyboardMotionMetrics(
      rawInset: rawInset,
      safeBottom: safeBottom,
      spacing: spacing,
      visualLift: lift,
      source: source,
      bridgeMs: bridgeMs,
      bridgedGap: bridgedGap,
    );
  }

  String toDebugLine() {
    return 'raw=${rawInset.toStringAsFixed(1)} '
        'safe=${safeBottom.toStringAsFixed(1)} '
        'dock=${dockBottom.toStringAsFixed(1)} '
        'lift=${visualLift.toStringAsFixed(1)} '
        'sheet=${sheetTranslation.toStringAsFixed(1)} '
        'pill=${dockBottom.toStringAsFixed(1)} '
        'targetLift=${targetLift.toStringAsFixed(1)} '
        'visualLift=${visualLift.toStringAsFixed(1)} '
        'lagPx=${lagPx.toStringAsFixed(1)} '
        'source=$source '
        'bridgeMs=$bridgeMs '
        'bridgedGap=$bridgedGap';
  }
}

class _DebugConsoleNotifier extends ValueNotifier<int> {
  _DebugConsoleNotifier(super.value);

  var _listenerCount = 0;

  bool get hasExternalListeners => _listenerCount > 0;

  @override
  void addListener(VoidCallback listener) {
    _listenerCount += 1;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_listenerCount > 0) _listenerCount -= 1;
    super.removeListener(listener);
  }
}

class DebugBuildStats {
  DebugBuildStats._();

  static int motionBuild = 0;
  static int sheetBuild = 0;
  static int pillBuild = 0;

  static void reset() {
    motionBuild = 0;
    sheetBuild = 0;
    pillBuild = 0;
  }

  static String snapshot() {
    return 'builds motion=$motionBuild sheet=$sheetBuild pill=$pillBuild';
  }
}

class DebugPerformanceProbe {
  DebugPerformanceProbe._();

  static const frameLogRateLimit = Duration(milliseconds: 250);
  static var _started = false;
  static var _headerLogged = false;
  static var _frameSeq = 0;
  static int? _lastVsyncStartUs;
  static final List<double> _observedVsyncMs = <double>[];

  static void resetSession() {
    _headerLogged = false;
    _frameSeq = 0;
    _lastVsyncStartUs = null;
    _observedVsyncMs.clear();
  }

  static void ensureStarted() {
    if (!_started) {
      SchedulerBinding.instance.addTimingsCallback(_handleTimings);
      _started = true;
    }
    if (_headerLogged) return;
    _headerLogged = true;
    DebugConsole.log(
      'frameProbe buildMs=0.0 rasterMs=0.0 totalMs=0.0 totalSpanMs=0.0 '
      'vsyncOverheadMs=0.0 vsyncDeltaMs=0.0 refreshRate=0.0 budgetMs=0.0 '
      'over16ms=false over33ms=false '
      'rateLimitMs=${frameLogRateLimit.inMilliseconds} '
      'suppressed=0 worstTotalMs=0.0 source=flutterFrame '
      'debugOpen=false warmupFrame=false',
    );
  }

  static void _handleTimings(List<FrameTiming> timings) {
    if (!DebugConsole.detailedCollectionEnabled) return;
    for (final timing in timings) {
      _frameSeq += 1;
      final buildMs = _ms(timing.buildDuration);
      final rasterMs = _ms(timing.rasterDuration);
      final totalSpanMs = _ms(timing.totalSpan);
      final vsyncOverheadMs = _ms(timing.vsyncOverhead);
      final vsyncStartUs = timing.timestampInMicroseconds(
        FramePhase.vsyncStart,
      );
      final vsyncDeltaMs = _lastVsyncStartUs == null
          ? 0.0
          : (vsyncStartUs - _lastVsyncStartUs!) /
                Duration.microsecondsPerMillisecond;
      _lastVsyncStartUs = vsyncStartUs;
      if (vsyncDeltaMs.isFinite && vsyncDeltaMs > 0) {
        if (_observedVsyncMs.length == 120) _observedVsyncMs.removeAt(0);
        _observedVsyncMs.add(vsyncDeltaMs);
      }
      final refreshRate = WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .display
          .refreshRate;
      final budgetMs = FrameBudget.fromObservedVsync(
        refreshRate: refreshRate,
        observedVsyncMs: _observedVsyncMs,
      ).milliseconds;
      DebugConsole._logFrame(
        FrameDiagnosticSample(
          buildMs: buildMs,
          rasterMs: rasterMs,
          totalSpanMs: totalSpanMs,
          vsyncOverheadMs: vsyncOverheadMs,
          vsyncDeltaMs: vsyncDeltaMs,
          refreshRate: refreshRate,
          budgetMs: budgetMs,
          frameNumber: timing.frameNumber,
          latestMotionSequence: DebugConsole.latestMotionSequence,
        ),
        sequence: _frameSeq,
        warmupFrame: _frameSeq <= 5,
      );
    }
  }

  static double _ms(Duration duration) {
    return duration.inMicroseconds / Duration.microsecondsPerMillisecond;
  }
}

final class _MotionConsoleSample implements DiagnosticSample {
  const _MotionConsoleSample({
    required this.sample,
    required this.spacing,
    required this.bridgeMs,
    required this.bridgedGap,
    required this.dtMs,
    required this.rawDelta,
    required this.velocity,
    required this.droppedLike,
    required this.idleGap,
    required this.sampleGap,
    required this.activeMotion,
    required this.motionPhase,
    required this.motionBuilds,
    required this.sheetBuilds,
    required this.pillBuilds,
    required this.focus,
  });

  final MotionDiagnosticSample sample;
  final double spacing;
  final int bridgeMs;
  final bool bridgedGap;
  final double dtMs;
  final double rawDelta;
  final double velocity;
  final bool droppedLike;
  final bool idleGap;
  final bool sampleGap;
  final bool activeMotion;
  final String motionPhase;
  final int motionBuilds;
  final int sheetBuilds;
  final int pillBuilds;
  final String focus;

  @override
  String format() {
    final dock = sample.safeBottom + spacing + sample.visualLift;
    return '${sample.format()} '
        'dock=${dock.toStringAsFixed(1)} '
        'lift=${sample.visualLift.toStringAsFixed(1)} '
        'sheet=${(-sample.visualLift).toStringAsFixed(1)} '
        'pill=${dock.toStringAsFixed(1)} '
        'bridgeMs=$bridgeMs bridgedGap=$bridgedGap '
        'dtMs=${dtMs.toStringAsFixed(1)} '
        'rawDelta=${rawDelta.toStringAsFixed(1)} '
        'velocity=${velocity.toStringAsFixed(1)} '
        'droppedLike=$droppedLike idleGap=$idleGap sampleGap=$sampleGap '
        'activeMotion=$activeMotion motionPhase=$motionPhase '
        'builds motion=$motionBuilds sheet=$sheetBuilds pill=$pillBuilds '
        'focus=$focus';
  }
}

final class _FrameConsoleSample implements DiagnosticSample {
  const _FrameConsoleSample({
    required this.sample,
    required this.sequence,
    required this.debugOpen,
    required this.warmupFrame,
  });

  final FrameDiagnosticSample sample;
  final int sequence;
  final bool debugOpen;
  final bool warmupFrame;

  @override
  String format() {
    return '${sample.format()} seq=$sequence '
        'totalMs=${sample.totalSpanMs.toStringAsFixed(1)} '
        'over16ms=${sample.totalSpanMs > 16.7} '
        'over33ms=${sample.totalSpanMs > 33.3} '
        'rateLimitMs=${DebugPerformanceProbe.frameLogRateLimit.inMilliseconds} '
        'suppressed=0 worstTotalMs=${sample.totalSpanMs.toStringAsFixed(1)} '
        'source=flutterFrame debugOpen=$debugOpen warmupFrame=$warmupFrame';
  }
}

class DebugConsole {
  DebugConsole._();

  static const _maxEntries = 500;
  static const _visibleTailLines = 80;
  static final DiagnosticRingBuffer _samples = DiagnosticRingBuffer(
    capacity: _maxEntries,
  );
  static final List<FrameDiagnosticSample> _frames = <FrameDiagnosticSample>[];
  static final _DebugConsoleNotifier _notifier = _DebugConsoleNotifier(0);
  static var _notifyScheduled = false;
  static final Stopwatch _clock = Stopwatch()..start();
  static KeyboardMotionMetrics? _lastMotionMetrics;
  static int? _lastMotionUs;
  static var _motionSeq = 0;
  static var _entryCount = 0;
  static var _detailedCollectionEnabled = true;

  static bool get detailedCollectionEnabled => _detailedCollectionEnabled;
  static int get latestMotionSequence => _motionSeq;

  static void setDetailedCollectionEnabled(bool enabled) {
    if (_detailedCollectionEnabled == enabled) return;
    _detailedCollectionEnabled = enabled;
    _scheduleNotify();
  }

  static void log(String message) {
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${(now.millisecond ~/ 10).toString().padLeft(2, '0')}';
    _add(TextDiagnosticSample('[$stamp] $message'));
  }

  static void _add(DiagnosticSample sample) {
    _samples.add(sample);
    _entryCount = math.min(_entryCount + 1, _maxEntries);
    _scheduleNotify();
  }

  static void logMotion(KeyboardMotionMetrics metrics) {
    if (!_detailedCollectionEnabled) return;
    if (_sameMotion(metrics, _lastMotionMetrics)) return;
    final nowUs = _clock.elapsedMicroseconds;
    final dtMs = _lastMotionUs == null
        ? 0.0
        : (nowUs - _lastMotionUs!) / Duration.microsecondsPerMillisecond;
    final rawDelta = _lastMotionMetrics == null
        ? 0.0
        : metrics.rawInset - _lastMotionMetrics!.rawInset;
    final velocity = dtMs <= 0 ? 0.0 : rawDelta / (dtMs / 1000);
    final activeMotion = rawDelta.abs() > 0.1 || metrics.lagPx.abs() > 0.1;
    final idleGap = dtMs > 200;
    final sampleGap = activeMotion && !idleGap && dtMs > 24;
    final droppedLike = sampleGap;
    final motionPhase = _motionPhase(rawDelta, metrics);
    _motionSeq += 1;
    _lastMotionMetrics = metrics;
    _lastMotionUs = nowUs;
    final sample = MotionDiagnosticSample(
      sequence: _motionSeq,
      rawInset: metrics.rawInset,
      safeBottom: metrics.safeBottom,
      targetLift: metrics.targetLift,
      visualLift: metrics.visualLift,
      lagPx: metrics.lagPx,
      source: metrics.source,
      metricsArrivalUs: nowUs,
      transformBuildUs: nowUs,
      postFrameUs: nowUs,
    );
    _add(
      _MotionConsoleSample(
        sample: sample,
        spacing: metrics.spacing,
        bridgeMs: metrics.bridgeMs,
        bridgedGap: metrics.bridgedGap,
        dtMs: dtMs,
        rawDelta: rawDelta,
        velocity: velocity,
        droppedLike: droppedLike,
        idleGap: idleGap,
        sampleGap: sampleGap,
        activeMotion: activeMotion,
        motionPhase: motionPhase,
        motionBuilds: DebugBuildStats.motionBuild,
        sheetBuilds: DebugBuildStats.sheetBuild,
        pillBuilds: DebugBuildStats.pillBuild,
        focus: _primaryFocusLabel(),
      ),
    );
  }

  static void _logFrame(
    FrameDiagnosticSample sample, {
    required int sequence,
    required bool warmupFrame,
  }) {
    if (!_detailedCollectionEnabled) return;
    if (_frames.length == _maxEntries) _frames.removeAt(0);
    _frames.add(sample);
    _add(
      _FrameConsoleSample(
        sample: sample,
        sequence: sequence,
        debugOpen: hasExternalListeners,
        warmupFrame: warmupFrame,
      ),
    );
  }

  static void clear() {
    _lastMotionMetrics = null;
    _lastMotionUs = null;
    _motionSeq = 0;
    _entryCount = 0;
    _samples.clear();
    _frames.clear();
    _clock
      ..reset()
      ..start();
    _scheduleNotify();
  }

  static List<String> get entries {
    final text = _samples.formattedText;
    if (text.isEmpty) return const <String>[];
    return List<String>.unmodifiable(text.split('\n'));
  }

  static int get entryCount => _entryCount;

  static String get allText {
    final text = _samples.formattedText;
    if (text.isEmpty) return '';
    final summary = PerformanceSummary.fromFrames(_frames);
    return '$text\n\nPerformanceSummary '
        'frameCount=${summary.frameCount} '
        'p95BuildMs=${summary.p95BuildMs.toStringAsFixed(1)} '
        'p95RasterMs=${summary.p95RasterMs.toStringAsFixed(1)} '
        'p95TotalSpanMs=${summary.p95TotalSpanMs.toStringAsFixed(1)} '
        'buildOverBudgetCount=${summary.buildOverBudgetCount} '
        'rasterOverBudgetCount=${summary.rasterOverBudgetCount} '
        'buildOverTwoBudgetsCount=${summary.buildOverTwoBudgetsCount} '
        'rasterOverTwoBudgetsCount=${summary.rasterOverTwoBudgetsCount}';
  }

  static String get visibleTailText =>
      _samples.formattedTail(_visibleTailLines);

  static ValueNotifier<int> get notifier => _notifier;
  static bool get hasExternalListeners => _notifier.hasExternalListeners;

  static void _scheduleNotify() {
    if (!_notifier.hasExternalListeners) return;
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      scheduleMicrotask(_flushNotify);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushNotify());
  }

  static void _flushNotify() {
    _notifyScheduled = false;
    _notifier.value += 1;
  }

  static String _primaryFocusLabel() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return 'none';
    return primaryFocus.debugLabel ??
        primaryFocus.context?.widget.runtimeType.toString() ??
        'unknown';
  }

  static String _motionPhase(double rawDelta, KeyboardMotionMetrics metrics) {
    if (rawDelta > 0.1) return 'opening';
    if (rawDelta < -0.1) return 'closing';
    if (metrics.targetLift <= 0.1 && metrics.visualLift <= 0.1) {
      return 'settled';
    }
    if (metrics.lagPx.abs() > 0.1) return 'catchup';
    return 'settled';
  }

  static bool _sameMotion(
    KeyboardMotionMetrics current,
    KeyboardMotionMetrics? previous,
  ) {
    return previous != null &&
        current.rawInset == previous.rawInset &&
        current.safeBottom == previous.safeBottom &&
        current.spacing == previous.spacing &&
        current.visualLift == previous.visualLift &&
        current.source == previous.source &&
        current.bridgeMs == previous.bridgeMs &&
        current.bridgedGap == previous.bridgedGap;
  }
}

class KeyboardMotionLayer extends StatefulWidget {
  const KeyboardMotionLayer({super.key});

  @override
  State<KeyboardMotionLayer> createState() => _KeyboardMotionLayerState();
}

class _KeyboardMotionLayerState extends State<KeyboardMotionLayer> {
  DateTime? _lastTargetAt;
  double? _lastTargetLift;
  var _activeBridgeMs = 0;
  var _activeBridgedGap = false;

  @override
  Widget build(BuildContext context) {
    DebugBuildStats.motionBuild += 1;
    final targetMetrics = KeyboardMotionMetrics.fromContext(context);
    final targetLift = targetMetrics.targetLift;
    _recordTargetSample(targetLift);
    final visualMetrics = targetMetrics.withVisualLift(
      targetLift,
      source: _motionSource(),
      bridgeMs: _activeBridgeMs,
      bridgedGap: _activeBridgedGap,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugConsole.logMotion(visualMetrics);
    });
    return Positioned.fill(
      child: Transform.translate(
        key: const ValueKey('keyboardtest-keyboard-motion-transform'),
        offset: Offset(0, visualMetrics.sheetTranslation),
        child: RepaintBoundary(
          key: const ValueKey('keyboardtest-motion-repaint-boundary'),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideUpKeyboardSheet(),
              ),
              FloatingKeyboardPill(metrics: targetMetrics),
            ],
          ),
        ),
      ),
    );
  }

  String _motionSource() {
    if (_activeBridgedGap) return 'imeDirectGap';
    return 'imeDirect';
  }

  void _recordTargetSample(double targetLift) {
    final now = DateTime.now();
    final previousTarget = _lastTargetLift;
    final targetChanged =
        previousTarget == null || (targetLift - previousTarget).abs() > 0.1;
    if (!targetChanged) {
      _activeBridgeMs = 0;
      _activeBridgedGap = false;
      return;
    }

    final elapsedMs = _lastTargetAt == null
        ? 0.0
        : now.difference(_lastTargetAt!).inMicroseconds /
              Duration.microsecondsPerMillisecond;
    final activeSampleGap =
        previousTarget != null && elapsedMs > 24 && elapsedMs <= 64;

    _activeBridgeMs = 0;
    _activeBridgedGap = activeSampleGap;
    _lastTargetAt = now;
    _lastTargetLift = targetLift;
  }
}

class SlideUpKeyboardSheet extends StatefulWidget {
  const SlideUpKeyboardSheet({super.key});

  @override
  State<SlideUpKeyboardSheet> createState() => _SlideUpKeyboardSheetState();
}

class _SlideUpKeyboardSheetState extends State<SlideUpKeyboardSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    _offset = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DebugBuildStats.sheetBuild += 1;
    final height = math.min(MediaQuery.sizeOf(context).height * 0.46, 390.0);
    return RepaintBoundary(
      key: const ValueKey('keyboardtest-sheet-repaint-boundary'),
      child: SlideTransition(
        position: _offset,
        child: Container(
          key: const ValueKey('keyboardtest-slide-sheet'),
          height: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: const Column(
            children: [
              SizedBox(height: 14),
              _SheetHandle(),
              SizedBox(height: 28),
              Icon(
                Icons.keyboard_alt_outlined,
                size: 42,
                color: Color(0xFF147A73),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFD5DAD8),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}

class FloatingKeyboardPill extends StatelessWidget {
  const FloatingKeyboardPill({super.key, required this.metrics});

  final KeyboardMotionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    DebugBuildStats.pillBuild += 1;
    return Positioned(
      left: 20,
      right: 20,
      bottom: metrics.layerPillBottom,
      child: const RepaintBoundary(
        key: ValueKey('keyboardtest-pill-repaint-boundary'),
        child: _TextPill(),
      ),
    );
  }
}

class _TextPill extends StatefulWidget {
  const _TextPill();

  @override
  State<_TextPill> createState() => _TextPillState();
}

class _TextPillState extends State<_TextPill> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'keyboardtest-pill-field');
    _focusNode.addListener(_logFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_logFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _logFocus() {
    DebugConsole.log(
      'focus active=${_focusNode.hasFocus} primary=${_focusNode.debugLabel}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('keyboardtest-floating-pill'),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 56,
        child: TextField(
          key: const ValueKey('keyboardtest-pill-field'),
          focusNode: _focusNode,
          textInputAction: TextInputAction.done,
          onTap: () => DebugConsole.log(
            'pill focus request primary=${_focusNode.debugLabel}',
          ),
          cursorColor: const Color(0xFF147A73),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            hintText: 'Text pill',
          ),
        ),
      ),
    );
  }
}

class DebugFloatingButton extends StatelessWidget {
  const DebugFloatingButton({super.key, this.bottomOffset});

  final double? bottomOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('debug-floating-button-position'),
      left: 16,
      bottom: bottomOffset ?? MediaQuery.viewPaddingOf(context).bottom + 24,
      child: Material(
        color: const Color(0xFF1E293B),
        shape: const CircleBorder(),
        elevation: 8,
        child: IconButton(
          key: const ValueKey('debug-floating-button'),
          tooltip: 'Debug log',
          icon: const Icon(Icons.terminal, size: 18, color: Color(0xFF06B6D4)),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const DebugConsoleDialog(),
          ),
        ),
      ),
    );
  }
}

class DebugConsoleDialog extends StatefulWidget {
  const DebugConsoleDialog({super.key});

  @override
  State<DebugConsoleDialog> createState() => _DebugConsoleDialogState();
}

class _DebugConsoleDialogState extends State<DebugConsoleDialog> {
  var _visibleText = DebugConsole.visibleTailText;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    DebugConsole.notifier.addListener(_refresh);
  }

  @override
  void dispose() {
    DebugConsole.notifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _visibleText = DebugConsole.visibleTailText;
      _copied = false;
    });
  }

  Future<void> _copyAll() async {
    final text = DebugConsole.allText;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final count = DebugConsole.entryCount;
    return Dialog(
      key: const ValueKey('debug-console-dialog'),
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.terminal,
                    size: 16,
                    color: Color(0xFF06B6D4),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Debug Console',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFCDD6F4),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($count)',
                          style: const TextStyle(
                            color: Color(0xFF6C7086),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('debug-detailed-collection-switch'),
                    value: DebugConsole.detailedCollectionEnabled,
                    onChanged: DebugConsole.setDetailedCollectionEnabled,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  IconButton(
                    key: const ValueKey('debug-console-copy'),
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: count == 0 ? null : _copyAll,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_outlined,
                      size: 16,
                    ),
                    color: _copied
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF89B4FA),
                  ),
                  IconButton(
                    key: const ValueKey('debug-console-clear'),
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: count == 0 ? null : DebugConsole.clear,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: const Color(0xFFEF4444),
                  ),
                  IconButton(
                    key: const ValueKey('debug-console-close'),
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 16),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF313244)),
            Flexible(
              child: count == 0
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Még nincs log.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _visibleText,
                        key: const ValueKey('debug-console-text'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          height: 1.45,
                          color: Color(0xFFCDD6F4),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
