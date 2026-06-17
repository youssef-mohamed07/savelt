import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/auth_api_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _typingController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  
  final String _text = 'Savlet';
  int _visibleCharacters = 0;

  @override
  void initState() {
    super.initState();

    // Make status bar transparent so splash fills edge-to-edge
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primary,
    ));
    
    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    // Glow pulse controller
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Typing animation controller
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // 200ms per character
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _mainController.forward();
    
    // Start typing animation with listener
    _typingController.addListener(() {
      final progress = _typingController.value;
      final newVisibleChars = (progress * _text.length).ceil()
          .clamp(0, _text.length);
      if (newVisibleChars != _visibleCharacters) {
        setState(() {
          _visibleCharacters = newVisibleChars;
        });
      }
    });

    // Ensure all characters show when animation finishes
    _typingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _visibleCharacters = _text.length);
      }
    });
    
    // Delay typing animation slightly
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _typingController.forward();
      }
    });
    
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    Timer(AppConstants.splashDuration, () async {
      if (mounted) {
        final authService = AuthApiService.instance;
        final isAuthenticated = await authService.isAuthenticated();
        
        if (isAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _glowController, _typingController]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Animated glow circles
                          ...List.generate(3, (index) {
                            return Transform.scale(
                              scale: 1.0 + (_glowAnimation.value * 0.3 * (index + 1)),
                              child: Container(
                                width: 200 + (index * 40).toDouble(),
                                height: 200 + (index * 40).toDouble(),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00CCFF).withValues(
                                      alpha: 0.15 * (1 - _glowAnimation.value) * (3 - index) / 3,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                          
                          // Typing animation - each character appears and glows
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_text.length, (index) {
                              final isVisible = index < _visibleCharacters;
                              final justAppeared = index == _visibleCharacters - 1;
                              
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 100),
                                opacity: isVisible ? 1.0 : 0.0,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: justAppeared ? 2.0 : 1.0,
                                    end: 1.0,
                                  ),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Text(
                                        _text[index],
                                        style: GoogleFonts.poppins(
                                          fontSize: 68,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF00CCFF),
                                          letterSpacing: 2,
                                          shadows: [
                                            if (justAppeared) ...[
                                              const Shadow(
                                                color: Color(0xFF00CCFF),
                                                blurRadius: 30,
                                              ),
                                              const Shadow(
                                                color: Color(0xFF00CCFF),
                                                blurRadius: 50,
                                              ),
                                            ],
                                            Shadow(
                                              color: const Color(0xFF00CCFF).withValues(alpha: 0.4),
                                              blurRadius: 15,
                                            ),
                                            const Shadow(
                                              color: Colors.black12,
                                              offset: Offset(0, 4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
