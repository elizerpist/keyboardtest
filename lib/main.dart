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
    setState(() => _sheetOpen = true);
  }

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
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
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideUpKeyboardSheet(),
            ),
            const FloatingKeyboardPill(),
          ],
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
  const FloatingKeyboardPill({super.key});

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final bottom = viewInsetsBottom > 0
        ? viewInsetsBottom + 12
        : safeBottom + 12;

    return Positioned(
      left: 20,
      right: 20,
      bottom: bottom,
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
