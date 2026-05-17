import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../app/theme.dart';

enum OrbState { idle, listening, speaking, thinking }

class TalkieOrb extends StatefulWidget {
  final OrbState state;
  final Color? color;
  final VoidCallback? onTap;
  final double size;

  const TalkieOrb({
    super.key,
    required this.state,
    this.color,
    this.onTap,
    this.size = 140,
  });

  @override
  State<TalkieOrb> createState() => _TalkieOrbState();
}

class _TalkieOrbState extends State<TalkieOrb> with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _pulseController,
          _rotationController,
        ]),
        builder: (context, _) {
          return SizedBox(
            width: widget.size + 40,
            height: widget.size + 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRing(widget.size + 36, color, _ring3Opacity()),
                _buildRing(widget.size + 18, color, _ring2Opacity()),
                _buildRing(widget.size + 4, color, _ring1Opacity()),
                _buildCore(color),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRing(double diameter, Color color, double opacity) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 1.0,
        ),
      ),
    );
  }

  Widget _buildCore(Color color) {
    final rotation = widget.state == OrbState.thinking
        ? _rotationController.value * 2 * pi
        : 0.0;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              color.withValues(alpha: 0.75),
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(child: _buildIcon(color)),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    switch (widget.state) {
      case OrbState.idle:
      case OrbState.listening:
        return Icon(
          PhosphorIcons.microphone(),
          color: Colors.white.withValues(alpha: 0.88),
          size: widget.size * 0.28,
        );
      case OrbState.speaking:
        return _buildWaveform(color);
      case OrbState.thinking:
        return Icon(
          PhosphorIcons.sparkle(),
          color: Colors.white.withValues(alpha: 0.88),
          size: widget.size * 0.28,
        );
    }
  }

  Widget _buildWaveform(Color color) {
    final bars = [0.4, 0.7, 1.0, 0.6, 0.85, 0.5, 0.75];
    final maxHeight = widget.size * 0.28;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: bars.asMap().entries.map((e) {
        final phase = (e.key / bars.length) * 2 * pi;
        final t = (sin(_pulseController.value * 2 * pi + phase) + 1) / 2;
        final height = maxHeight * (e.value * 0.4 + t * e.value * 0.6);
        return Container(
          width: widget.size * 0.035,
          height: height,
          margin: EdgeInsets.symmetric(horizontal: widget.size * 0.018),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }

  double _ring1Opacity() {
    switch (widget.state) {
      case OrbState.idle: return 0.18 + _idleController.value * 0.07;
      case OrbState.listening: return 0.28 + _pulseController.value * 0.18;
      case OrbState.speaking: return 0.22 + _pulseController.value * 0.14;
      case OrbState.thinking: return 0.16;
    }
  }

  double _ring2Opacity() {
    switch (widget.state) {
      case OrbState.idle: return 0.10 + _idleController.value * 0.04;
      case OrbState.listening: return 0.16 + _pulseController.value * 0.12;
      case OrbState.speaking: return 0.14 + _pulseController.value * 0.08;
      case OrbState.thinking: return 0.10;
    }
  }

  double _ring3Opacity() {
    switch (widget.state) {
      case OrbState.idle: return 0.05 + _idleController.value * 0.03;
      case OrbState.listening: return 0.08 + _pulseController.value * 0.07;
      case OrbState.speaking: return 0.07 + _pulseController.value * 0.05;
      case OrbState.thinking: return 0.06;
    }
  }
}
