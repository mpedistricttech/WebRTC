import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_button.dart';

class HomeScreenV2 extends StatefulWidget {
  final List<dynamic> items;

  const HomeScreenV2({Key? key, required this.items}) : super(key: key);

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Row(
                      children: [
                        // Logo
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusL),
                                  boxShadow: AppTheme.shadowMedium,
                                ),
                                child: const Icon(
                                  Icons.video_call,
                                  color: AppTheme.textPrimary,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: const Text(
                                  'CM Relief Fund',
                                  style: AppTheme.heading2,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: const Text(
                                  'Connecting video calls',
                                  style: AppTheme.body2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification icon
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppTheme.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome message
                    /*
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.shadowMedium,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: const Icon(
                                  Icons.waving_hand,
                                  color: AppTheme.textPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome back!',
                                      style: AppTheme.heading3,
                                    ),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    const Text(
                                      'Hemraj Mehra',
                                      style: AppTheme.body2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
*/
                    //   const SizedBox(height: AppTheme.spacingXL),

                    // Quick Stats
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: StatsCard(
                                title: 'Total Calls',
                                value: '1,234',
                                icon: Icons.call,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: StatsCard(
                                title: 'Active Users',
                                value: '567',
                                icon: Icons.people,
                                color: AppTheme.secondaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Features Section
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Video Calling Features',
                              style: AppTheme.heading3,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            const Text(
                              'Choose your preferred calling experience',
                              style: AppTheme.body2,
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                          ],
                        ),
                      ),
                    ),

                    // Feature Cards
                    ...widget.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: AppTheme.spacingM,
                              top: index == 0 ? 0 : AppTheme.spacingM,
                            ),
                            child: FeatureCard(
                              title: item.title,
                              subtitle: item.subtitle,
                              icon: index == 0
                                  ? Icons.video_call
                                  : Icons.phone_iphone,
                              gradient: index == 0
                                  ? AppTheme.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        AppTheme.secondaryPurple,
                                        AppTheme.accentRed,
                                      ],
                                    ),
                              onTap: () => item.push(context),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: AppTheme.spacingXXL),

                    // Quick Actions
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: AppTheme.heading3,
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            Row(
                              children: [
                                Expanded(
                                  child: QuickActionButton(
                                    title: 'Recent Calls',
                                    icon: Icons.history,
                                    onTap: () {
                                      // Handle recent calls
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: QuickActionButton(
                                    title: 'Contacts',
                                    icon: Icons.contacts,
                                    onTap: () {
                                      // Handle contacts
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingXXL),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
