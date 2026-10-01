import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/data/repositories/home_repository.dart';
import 'package:fatelinkfe/logic/blocs/home/home_bloc.dart';
import 'package:fatelinkfe/logic/blocs/home/home_event.dart';

import 'radar_intro_step.dart';
import 'radar_mood_step.dart';
import 'radar_result_step.dart';
import 'radar_signal_step.dart';
import 'radar_vibe_step.dart';

class EmotionRadarModal extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onStartChat;

  const EmotionRadarModal({
    super.key,
    required this.onDismiss,
    required this.onStartChat,
  });

  @override
  State<EmotionRadarModal> createState() => _EmotionRadarModalState();
}

class _EmotionRadarModalState extends State<EmotionRadarModal> {
  int _currentStep = 0; // 0: Intro, 1: Mood, 2: Vibe, 3: Signal, 4: Result
  String? _selectedMood;
  String? _selectedVibe;
  String? _selectedSignal;

  Future<void> _saveResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_started_chat', true);

    String moodIcon = '✨';
    String hertz = '528 Hz';
    if (_selectedMood != null) {
      final m = _selectedMood!.toLowerCase();
      if (m.contains('chùng') || m.contains('cô đơn') || m.contains('tĩnh')) {
        moodIcon = '🌧️';
        hertz = '528 Hz';
      } else if (m.contains('chill') || m.contains('bình yên') || m.contains('lắng đọng')) {
        moodIcon = '☕';
        hertz = '432 Hz';
      } else if (m.contains('hứng') || m.contains('năng lượng') || m.contains('high')) {
        moodIcon = '✨';
        hertz = '741 Hz';
      } else {
        moodIcon = '🎧';
        hertz = '639 Hz';
      }
      await prefs.setString('user_frequency_mood', _selectedMood!);
      await prefs.setString('user_frequency_icon', moodIcon);
      await prefs.setString('user_frequency_hertz', hertz);
    }

    if (_selectedVibe != null) {
      await prefs.setString('user_frequency_vibe', _selectedVibe!);
    }
    if (_selectedSignal != null) {
      await prefs.setString('user_frequency_signal', _selectedSignal!);
    }

    // Gửi tần số lên Backend để thuật toán tính toán tức thì
    if (mounted && _selectedMood != null && _selectedVibe != null && _selectedSignal != null) {
      try {
        await HomeRepository().updateUserFrequency(
          context: context,
          mood: _selectedMood!,
          vibe: _selectedVibe!,
          signal: _selectedSignal!,
          frequencyHertz: hertz,
        );
        if (mounted) {
          context.read<HomeBloc>().add(RefreshRecommendationsEvent(context));
        }
      } catch (e) {
        debugPrint('Error syncing frequency to backend: $e');
      }
    }
  }

  void _handleExploreMatches() async {
    await _saveResults();
    widget.onDismiss();
  }

  void _handleChatWithFaye() async {
    await _saveResults();
    widget.onStartChat();
  }

  void _handleSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_started_chat', true);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: Colors.black.withValues(alpha: 0.65),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return RadarIntroStep(
          key: const ValueKey('intro_step'),
          onStart: () => setState(() => _currentStep = 1),
          onSkip: _handleSkip,
        );
      case 1:
        return RadarMoodStep(
          key: const ValueKey('mood_step'),
          selectedMood: _selectedMood,
          onSelectMood: (val) => setState(() => _selectedMood = val),
          onNext: () => setState(() => _currentStep = 2),
          onBack: () => setState(() => _currentStep = 0),
        );
      case 2:
        return RadarVibeStep(
          key: const ValueKey('vibe_step'),
          selectedVibe: _selectedVibe,
          onSelectVibe: (val) => setState(() => _selectedVibe = val),
          onNext: () => setState(() => _currentStep = 3),
          onBack: () => setState(() => _currentStep = 1),
        );
      case 3:
        return RadarSignalStep(
          key: const ValueKey('signal_step'),
          selectedSignal: _selectedSignal,
          onSelectSignal: (val) => setState(() => _selectedSignal = val),
          onScan: () => setState(() => _currentStep = 4),
          onBack: () => setState(() => _currentStep = 2),
        );
      case 4:
        return RadarResultStep(
          key: const ValueKey('result_step'),
          mood: _selectedMood ?? 'Deep Talk',
          vibe: _selectedVibe ?? 'Ban công ngắm mưa',
          signal: _selectedSignal ?? 'Biết lắng nghe chân thành',
          onExploreMatches: _handleExploreMatches,
          onChatWithFaye: _handleChatWithFaye,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
