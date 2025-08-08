import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../themes/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.user;
          if (user == null) {
            // This should not happen if the user is authenticated
            // but as a fallback, we can show a loading or error state.
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: AppTheme.safePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryColor,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.onPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        user.name,
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        user.email,
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.onSurfaceColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Listening History'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to listening history screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Favorites'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed('/favorites');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: const Text('Playlists'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed('/playlists');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to settings screen
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    authService.logout();
                    // The AuthWrapper will handle navigation
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: AppTheme.onErrorColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
