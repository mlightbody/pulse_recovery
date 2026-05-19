import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_settings_model.dart';
export 'profile_settings_model.dart';

class ProfileSettingsWidget extends StatefulWidget {
  const ProfileSettingsWidget({super.key});

  static String routeName = 'ProfileSettings';
  static String routePath = '/profileSettings';

  @override
  State<ProfileSettingsWidget> createState() => _ProfileSettingsWidgetState();
}

class _ProfileSettingsWidgetState extends State<ProfileSettingsWidget> {
  late ProfileSettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final displayNameController = TextEditingController();
  final restingHrController = TextEditingController();
  final maxHrController = TextEditingController();

  DateTime? dateOfBirth;
  String? fitnessLevel;
  String? primaryGoal;

  bool consentForPersonalisation = true;
  bool consentForResearch = false;

  bool isLoading = true;
  bool isSaving = false;
  bool profileExists = false;

  final List<String> fitnessLevels = [
    'Beginner',
    'Improving',
    'Regular exerciser',
    'Fit / active',
    'Competitive athlete',
  ];

  final List<String> goals = [
    'Improve recovery',
    'Build aerobic fitness',
    'Run faster',
    'Improve general health',
    'Monitor readiness',
    'Return to fitness',
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileSettingsModel());
    _loadProfile();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    restingHrController.dispose();
    maxHrController.dispose();
    _model.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>>? _profileRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Future<void> _loadProfile() async {
    final ref = _profileRef();

    if (ref == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await ref.get();
    final data = snapshot.data();

    if (data != null) {
      profileExists = true;

      displayNameController.text = data['displayName'] ?? '';

      final dob = data['dateOfBirth'];
      if (dob is Timestamp) {
        dateOfBirth = dob.toDate();
      }

      final restingHr = data['typicalRestingHr'];
      if (restingHr != null) {
        restingHrController.text = restingHr.toString();
      }

      final maxHr = data['knownMaxHr'];
      if (maxHr != null) {
        maxHrController.text = maxHr.toString();
      }

      fitnessLevel = data['fitnessLevel'];
      primaryGoal = data['primaryGoal'];

      consentForPersonalisation =
          data['consentForPersonalisation'] ?? true;
      consentForResearch = data['consentForResearch'] ?? false;
    } else {
      displayNameController.text = user.displayName ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final ref = _profileRef();

    if (ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save profile.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    final restingHr = int.tryParse(restingHrController.text.trim());
    final maxHr = int.tryParse(maxHrController.text.trim());

    if (restingHrController.text.trim().isNotEmpty &&
        (restingHr == null || restingHr < 30 || restingHr > 120)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Typical resting HR should be between 30 and 120.'),
        ),
      );
      return;
    }

    if (maxHrController.text.trim().isNotEmpty &&
        (maxHr == null || maxHr < 80 || maxHr > 230)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Known max HR should be between 80 and 230.'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    final data = <String, dynamic>{
      'email': user.email,
      'displayName': displayNameController.text.trim(),
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'typicalRestingHr': restingHr,
      'restingHrSource': restingHr != null ? 'manual' : null,
      'knownMaxHr': maxHr,
      'fitnessLevel': fitnessLevel,
      'primaryGoal': primaryGoal,
      'consentForPersonalisation': consentForPersonalisation,
      'consentForResearch': consentForResearch,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!profileExists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    try {
      await ref.set(data, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        profileExists = true;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 40),
      firstDate: DateTime(1920),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        dateOfBirth = picked;
      });
    }
  }

  int? _calculatedAge() {
    if (dateOfBirth == null) return null;

    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;

    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month &&
            today.day < dateOfBirth!.day)) {
      age--;
    }

    return age;
  }

  InputDecoration _decoration(String label, String helper) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final age = _calculatedAge();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            context.goNamed(DashboardWidget.routeName);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Profile',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  font: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            child: Text(
                              (displayNameController.text.isNotEmpty
                                      ? displayNameController.text[0]
                                      : email.isNotEmpty
                                          ? email[0]
                                          : '?')
                                  .toUpperCase(),
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayNameController.text.isNotEmpty
                                ? displayNameController.text
                                : 'Your profile',
                            style: FlutterFlowTheme.of(context)
                                .titleLarge
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).onPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  color:
                                      FlutterFlowTheme.of(context).onPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionCard(
                      title: 'Personal details',
                      children: [
                        TextFormField(
                          controller: displayNameController,
                          decoration: _decoration(
                            'Display name',
                            'This is how the app will address you.',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        InkWell(
                          onTap: _pickDateOfBirth,
                          borderRadius: BorderRadius.circular(16),
                          child: InputDecorator(
                            decoration: _decoration(
                              'Date of birth optional',
                              'Providing this improves the accuracy of age-adjusted recovery advice.',
                            ),
                            child: Text(
                              dateOfBirth == null
                                  ? 'Tap to select'
                                  : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
                                      '${age != null ? '  •  Age $age' : ''}',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _sectionCard(
                      title: 'Heart rate profile',
                      children: [
                        TextFormField(
                          controller: restingHrController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(
                            'Typical resting HR optional',
                            'Use your usual morning resting heart rate. Leave blank if unknown.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: maxHrController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(
                            'Known max HR optional',
                            'Only enter this if you know it from a reliable test or device history.',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _sectionCard(
                      title: 'Training context',
                      children: [
                        DropdownButtonFormField<String>(
                          value: fitnessLevel,
                          decoration: _decoration(
                            'Fitness level optional',
                            'Helps make advice more relevant.',
                          ),
                          items: fitnessLevels
                              .map(
                                (level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              fitnessLevel = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: primaryGoal,
                          decoration: _decoration(
                            'Primary goal optional',
                            'Used to shape coaching recommendations.',
                          ),
                          items: goals
                              .map(
                                (goal) => DropdownMenuItem(
                                  value: goal,
                                  child: Text(goal),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              primaryGoal = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _sectionCard(
                      title: 'Data preferences',
                      children: [
                        SwitchListTile(
                          value: consentForPersonalisation,
                          onChanged: (value) {
                            setState(() {
                              consentForPersonalisation = value;
                            });
                          },
                          title: const Text('Personalised advice'),
                          subtitle: const Text(
                            'Use my profile and assessment history to personalise feedback.',
                          ),
                        ),
                        SwitchListTile(
                          value: consentForResearch,
                          onChanged: (value) {
                            setState(() {
                              consentForResearch = value;
                            });
                          },
                          title: const Text('Anonymised improvement data'),
                          subtitle: const Text(
                            'Allow anonymised data to help improve future recommendations.',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator()
                          : const Text('Save profile'),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Your profile is stored privately under your account.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodySmall,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}