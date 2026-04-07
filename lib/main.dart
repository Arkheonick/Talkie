import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'services/user_profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox('sessions');

  final profileService = UserProfileService();
  await profileService.init();
  final profile = profileService.load();

  runApp(TalkieApp(
    showOnboarding: !profile.onboardingCompleted,
    profileService: profileService,
  ));
}

class TalkieApp extends StatelessWidget {
  final bool showOnboarding;
  final UserProfileService profileService;

  const TalkieApp({
    super.key,
    required this.showOnboarding,
    required this.profileService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talkie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: showOnboarding
          ? OnboardingScreen(profileService: profileService)
          : const MainShell(),
    );
  }
}
