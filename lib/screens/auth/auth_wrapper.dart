import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../farmer/farmer_dashboard.dart';
import '../marketplace/marketplace_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isCheckingAuth = true;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userDocumentFuture;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChanged,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleAuthStateChanged(User? user) {
    if (!mounted) {
      return;
    }

    setState(() {
      _user = user;
      _isCheckingAuth = false;
      _userDocumentFuture = user == null
          ? null
          : _fetchUserDocumentWithRetry(user.uid);
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserDocumentWithRetry(
    String uid,
  ) async {
    final DocumentReference<Map<String, dynamic>> reference = FirebaseFirestore
        .instance
        .collection(AppConstants.usersCollection)
        .doc(uid);

    DocumentSnapshot<Map<String, dynamic>> snapshot = await reference.get();

    // A newly created auth user may become available before the profile
    // document write has completed. Retry briefly before showing an error.
    int attempts = 0;
    while (!snapshot.exists && attempts < 5) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) {
        break;
      }
      snapshot = await reference.get();
      attempts++;
    }

    return snapshot;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const _AuthLoadingView();
    }

    if (_user == null || _userDocumentFuture == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDocumentFuture,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingView();
            }

            if (snapshot.hasError) {
              return const _AuthErrorView(
                message:
                    'We could not load your account profile. '
                    'Check your internet connection and try again.',
              );
            }

            final DocumentSnapshot<Map<String, dynamic>>? document =
                snapshot.data;
            if (document == null || !document.exists) {
              return const _AuthErrorView(
                message:
                    'No profile was found for this account. '
                    'Please sign out and create an account again.',
              );
            }

            final Map<String, dynamic> data =
                document.data() ?? <String, dynamic>{};
            final String role = (data['role'] as String? ?? '')
                .trim()
                .toLowerCase();

            switch (role) {
              case 'farmer':
                return const FarmerDashboard();
              case 'trader':
              case 'traders':
              case 'consumer':
                return const MarketplaceScreen();
              default:
                return const _AuthErrorView(
                  message:
                      'Your account role is missing or invalid. '
                      'Please sign out and contact support.',
                );
            }
          },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppConstants.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your account...',
              style: TextStyle(color: AppConstants.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorView extends StatelessWidget {
  const _AuthErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: AppConstants.errorColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unable to load your profile',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppConstants.textLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Back to login'),
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
