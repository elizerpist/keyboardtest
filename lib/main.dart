import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    DebugConsole.clear();
    DebugConsole.log('sheet open');
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

  double get layerPillBottom => safeBottom + spacing;
  double get keyboardLift => math.max(rawInset - safeBottom, 0);
  double get dockBottom => layerPillBottom + keyboardLift;
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

class DebugConsole {
  DebugConsole._();

  static const _maxEntries = 500;
  static final List<String> _entries = <String>[];
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static String? _lastMotionLine;

  static void log(String message) {
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${(now.millisecond ~/ 10).toString().padLeft(2, '0')}';
    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add('[$stamp] $message');
    notifier.value += 1;
  }

  static void logMotion(KeyboardMotionMetrics metrics) {
    final line = metrics.toDebugLine();
    if (_lastMotionLine == line) return;
    _lastMotionLine = line;
    log(line);
  }

  static void clear() {
    _lastMotionLine = null;
    _entries.clear();
    notifier.value += 1;
  }

  static List<String> get entries => List.unmodifiable(_entries);
  static String get allText => _entries.join('\n');
}

class KeyboardMotionLayer extends StatelessWidget {
  const KeyboardMotionLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = KeyboardMotionMetrics.fromContext(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugConsole.logMotion(metrics);
    });
    return Positioned.fill(
      child: Transform.translate(
        key: const ValueKey('keyboardtest-keyboard-motion-transform'),
        offset: Offset(0, metrics.sheetTranslation),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideUpKeyboardSheet(),
            ),
            FloatingKeyboardPill(metrics: metrics),
          ],
        ),
      ),
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
      bottom: metrics.layerPillBottom,
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
          onTap: () => DebugConsole.log('pill focus request'),
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
  final TextEditingController _controller = TextEditingController();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller.text = DebugConsole.allText;
    DebugConsole.notifier.addListener(_refresh);
  }

  @override
  void dispose() {
    DebugConsole.notifier.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final text = DebugConsole.allText;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _copied = false);
  }

  Future<void> _copyAll() async {
    if (_controller.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final count = DebugConsole.entries.length;
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
                  : TextField(
                      key: const ValueKey('debug-console-text'),
                      controller: _controller,
                      readOnly: true,
                      maxLines: null,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.45,
                        color: Color(0xFFCDD6F4),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
