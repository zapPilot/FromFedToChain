import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/navigation_service.dart';

/// Demo utility to test and showcase the navigation flow
class NavigationDemo {
  
  /// Reset the app to initial state (useful for testing)
  static Future<void> resetToInitialState() async {
    await NavigationService.resetAppState();
    print('✅ App state reset - will show onboarding on next launch');
  }

  /// Mark onboarding as completed (skip onboarding)
  static Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    print('✅ Onboarding marked as completed - will skip onboarding on next launch');
  }

  /// Check current app state
  static Future<void> checkAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('onboarding_completed') ?? false;
    
    print('📊 Current App State:');
    print('   - Onboarding completed: $hasSeenOnboarding');
    print('   - Next screen: ${hasSeenOnboarding ? "Home" : "Onboarding"}');
  }

  /// Demo widget to test navigation flows
  static Widget createDemoControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Navigation Demo Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Reset app state button
          ElevatedButton(
            onPressed: () async {
              await resetToInitialState();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('App state reset! Restart to see onboarding.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Reset App State'),
          ),
          
          const SizedBox(height: 8),
          
          // Mark onboarding completed button
          ElevatedButton(
            onPressed: () async {
              await markOnboardingCompleted();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Onboarding marked completed! Restart to skip onboarding.'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text('Skip Onboarding'),
          ),
          
          const SizedBox(height: 8),
          
          // Check app state button
          ElevatedButton(
            onPressed: () async {
              await checkAppState();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Check console for app state info'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Check State'),
          ),
        ],
      ),
    );
  }
}