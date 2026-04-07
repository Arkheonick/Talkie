import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/cefr_level.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../shell/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  final UserProfileService profileService;

  const OnboardingScreen({super.key, required this.profileService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  CefrLevel? _selected;

  static const _levels = [
    _LevelInfo(CefrLevel.a1, 'Je commence tout juste', 'Je ne connais que quelques mots'),
    _LevelInfo(CefrLevel.a2, 'Je connais les bases', 'Je comprends les phrases simples'),
    _LevelInfo(CefrLevel.b1, 'Niveau intermédiaire', 'Je me débrouille dans la plupart des situations'),
    _LevelInfo(CefrLevel.b2, 'Assez à l\'aise', 'Je comprends l\'essentiel de sujets complexes'),
    _LevelInfo(CefrLevel.c1, 'Niveau avancé', 'Je m\'exprime avec aisance et précision'),
    _LevelInfo(CefrLevel.c2, 'Maîtrise', 'Je comprends pratiquement tout sans effort'),
  ];

  Future<void> _confirm() async {
    if (_selected == null) return;
    final profile = UserProfile(
      level: _selected!,
      onboardingCompleted: true,
    );
    await widget.profileService.save(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🎧', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quel est ton\nniveau d\'anglais ?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'On va adapter le contenu et le Prof IA à ton niveau.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final info = _levels[i];
                    final isSelected = _selected == info.level;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = info.level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  info.level.code,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isSelected ? Colors.white : AppTheme.muted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    info.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primary, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected != null ? _confirm : null,
                  child: const Text('Commencer'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelInfo {
  final CefrLevel level;
  final String title;
  final String subtitle;
  const _LevelInfo(this.level, this.title, this.subtitle);
}
