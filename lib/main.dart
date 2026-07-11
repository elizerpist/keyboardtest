import 'dart:math' as math;

import 'package:flutter/material.dart';

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

class KeyboardTestHome extends StatefulWidget {
  const KeyboardTestHome({super.key});

  @override
  State<KeyboardTestHome> createState() => _KeyboardTestHomeState();
}

class _KeyboardTestHomeState extends State<KeyboardTestHome> {
  var _sheetOpen = false;

  void _openSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    MotionDebugLog.clear();
    MotionDebugLog.log('sheet open');
    setState(() => _sheetOpen = true);
  }

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    MotionDebugLog.log('sheet close');
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
          const KeyboardMotionDebugPanel(),
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
  });

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

  double get dockBottom => math.max(rawInset, safeBottom) + spacing;
  double get keyboardLift => math.max(rawInset - safeBottom, 0);
  double get sheetTranslation => -keyboardLift;

  String toDebugLine() {
    return 'raw=${rawInset.toStringAsFixed(1)} '
        'safe=${safeBottom.toStringAsFixed(1)} '
        'dock=${dockBottom.toStringAsFixed(1)} '
        'lift=${keyboardLift.toStringAsFixed(1)} '
        'sheet=${sheetTranslation.toStringAsFixed(1)} '
        'pill=${dockBottom.toStringAsFixed(1)}';
  }
}

class MotionDebugLog {
  MotionDebugLog._();

  static const _maxEntries = 8;
  static final ValueNotifier<List<String>> entries =
      ValueNotifier<List<String>>(<String>[]);
  static String? _lastMotionLine;

  static void log(String message) {
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${(now.millisecond ~/ 10).toString().padLeft(2, '0')}';
    final next = <String>[...entries.value, '[$stamp] $message'];
    if (next.length > _maxEntries) {
      entries.value = next.sublist(next.length - _maxEntries);
    } else {
      entries.value = next;
    }
  }

  static void logMotion(KeyboardMotionMetrics metrics) {
    final line = metrics.toDebugLine();
    if (_lastMotionLine == line) return;
    _lastMotionLine = line;
    log(line);
  }

  static void clear() {
    _lastMotionLine = null;
    entries.value = <String>[];
  }
}

class KeyboardMotionLayer extends StatelessWidget {
  const KeyboardMotionLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = KeyboardMotionMetrics.fromContext(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MotionDebugLog.logMotion(metrics);
    });
    return Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideUpKeyboardSheet(),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: metrics.dockBottom - 8,
          child: const _SheetBackplate(),
        ),
        FloatingKeyboardPill(metrics: metrics),
      ],
    );
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
    final height = math.min(MediaQuery.sizeOf(context).height * 0.46, 390.0);
    return SlideTransition(
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
    );
  }
}

class _SheetBackplate extends StatelessWidget {
  const _SheetBackplate();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('keyboardtest-sheet-backplate'),
      height: 86,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4F1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFB7DCD5)),
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
    return Positioned(
      left: 20,
      right: 20,
      bottom: metrics.dockBottom,
      child: const _TextPill(),
    );
  }
}

class _TextPill extends StatelessWidget {
  const _TextPill();

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
          textInputAction: TextInputAction.done,
          onTap: () => MotionDebugLog.log('pill focus request'),
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

class KeyboardMotionDebugPanel extends StatelessWidget {
  const KeyboardMotionDebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = KeyboardMotionMetrics.fromContext(context);
    return Positioned(
      key: const ValueKey('keyboardtest-debug-panel-position'),
      left: 12,
      right: 12,
      top: MediaQuery.viewPaddingOf(context).top + 12,
      child: ValueListenableBuilder<List<String>>(
        valueListenable: MotionDebugLog.entries,
        builder: (context, entries, _) {
          final visibleEntries = entries.isEmpty
              ? const <String>['[--:--:--.--] debug ready']
              : entries;
          final debugLines = <String>[
            '[live] ${metrics.toDebugLine()}',
            ...visibleEntries,
          ];
          return DecoratedBox(
            key: const ValueKey('keyboardtest-debug-panel'),
            decoration: BoxDecoration(
              color: const Color(0xE51E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF06B6D4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Text(
                debugLines.join('\n'),
                maxLines: 9,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: Color(0xFFE0F2FE),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
