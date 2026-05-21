import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/trend_service.dart';
import '/utils/recovery_decision_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'Dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  late DashboardModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  RecoveryTrendSummary? _trendSummary;
  PersonalisedRecoveryAdvice? _advice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
    _loadTrends();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadTrends() async {
    try {
      final summary = await TrendService().getRecoveryTrendSummary();
      final advice = buildPersonalisedRecoveryAdvice(trend: summary);

      if (!mounted) return;

      setState(() {
        _trendSummary = summary;
        _advice = advice;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _navigateFromMenu(String value) {
    switch (value) {
      case 'home':
        context.goNamed(OnboardingWidget.routeName);
        break;
      case 'dashboard':
        context.goNamed(DashboardWidget.routeName);
        break;
      case 'new':
        context.goNamed(NewAssessmentWidget.routeName);
        break;
      case 'progress':
        context.goNamed(FitnessProgressWidget.routeName);
        break;
      case 'history':
        context.goNamed(HistoryLogWidget.routeName);
        break;
      case 'settings':
        context.goNamed(ProfileSettingsWidget.routeName);
        break;
    }
  }

  PopupMenuButton<String> _menuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded),
      onSelected: _navigateFromMenu,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'home', child: Text('Home')),
        PopupMenuItem(value: 'dashboard', child: Text('Dashboard')),
        PopupMenuItem(value: 'new', child: Text('New Assessment')),
        PopupMenuItem(value: 'progress', child: Text('Fitness Progress')),
        PopupMenuItem(value: 'history', child: Text('History Log')),
        PopupMenuItem(value: 'settings', child: Text('Profile Settings')),
      ],
    );
  }

  String _latestRecoveryText() {
    final value = _trendSummary?.latestRecoveryPercent120;
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)}%';
  }

  String _averageRecoveryText() {
    final value = _trendSummary?.recentAverageRecoveryPercent120;
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)}%';
  }

  String _totalTestsText() {
    final count = _trendSummary?.assessmentCount;
    if (count == null) return '—';
    return count.toString();
  }

  Widget _summaryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
        ),
        child: Column(
          children: [
            Icon(icon, color: FlutterFlowTheme.of(context).primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    font: GoogleFonts.dmSans(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _todayFocusCard() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final advice = _advice;

    if (advice == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          'Complete a few assessments to unlock personalised recovery advice.',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Today’s recovery focus',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice.patternTitle,
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            advice.whatItMeans,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  lineHeight: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Coaching focus',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            advice.coachingFocus,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  lineHeight: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.goNamed(FitnessProgressWidget.routeName);
            },
            child: const Text('View trend details'),
          ),
        ],
      ),
    );
  }

  Widget _latestAssessmentCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).success,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Latest Assessment',
            style: FlutterFlowTheme.of(context).labelLarge.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  color: FlutterFlowTheme.of(context).onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            _latestRecoveryText(),
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).headlineLarge.override(
                  font: GoogleFonts.nunito(fontWeight: FontWeight.w900),
                  color: FlutterFlowTheme.of(context).onPrimaryContainer,
                  fontSize: 58,
                ),
          ),
          Text(
            '120-second recovery',
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.dmSans(),
                  color: FlutterFlowTheme.of(context).onPrimaryContainer80,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.goNamed(NewAssessmentWidget.routeName);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start New Assessment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadTrends,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userEmail.isEmpty ? 'Hello' : userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmSans(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                            ),
                            Text(
                              'Pulse Recovery',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded),
                        onPressed: () {
                          context.goNamed(ProfileSettingsWidget.routeName);
                        },
                      ),
                      _menuButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _latestAssessmentCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _summaryMetric(
                        label: 'Avg recovery',
                        value: _averageRecoveryText(),
                        icon: Icons.favorite_rounded,
                      ),
                      const SizedBox(width: 12),
                      _summaryMetric(
                        label: 'Total tests',
                        value: _totalTestsText(),
                        icon: Icons.history_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _todayFocusCard(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.goNamed(HistoryLogWidget.routeName);
                    },
                    child: const Text('See All History'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      context.go('/');
                    },
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}