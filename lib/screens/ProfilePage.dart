import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/auth_provider.dart';
import 'package:untitled/screens/LoginPage.dart';
import 'package:untitled/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<String?> _getUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['username'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final usernameController = TextEditingController();
    
    // Get current username
    _getUserName(user!.uid).then((username) {
      if (username != null) {
        usernameController.text = username;
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'username': usernameController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }

              try {
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  // Reauthenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  
                  // Update password
                  await user.updatePassword(newPasswordController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: true, // Replace with actual state
              onChanged: (value) {
                // Implement notification toggle
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              value: true, // Replace with actual state
              onChanged: (value) {
                // Implement email notification toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Profile Visibility'),
              subtitle: const Text('Make your profile visible to other users'),
              value: true, // Replace with actual state
              onChanged: (value) {
                // Implement privacy toggle
              },
            ),
            SwitchListTile(
              title: const Text('Activity Status'),
              subtitle: const Text('Show when you\'re active'),
              value: true, // Replace with actual state
              onChanged: (value) {
                // Implement activity status toggle
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                // Implement language change
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              onTap: () {
                // Implement language change
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              onTap: () {
                // Implement language change
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Your travel companion app for creating and managing itineraries.'),
            SizedBox(height: 8),
            Text('© 2024 All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.watch<ThemeProvider>().isDarkMode
                    ? const Color(0xFF3D3F4B)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null && user != null
                        ? FutureBuilder<String?>(
                            future: _getUserName(user.uid),
                            builder: (context, snapshot) {
                              final username = snapshot.data;
                              return Text(
                                username != null && username.isNotEmpty ? username[0].toUpperCase() : 'A',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: context.watch<ThemeProvider>().isDarkMode
                                      ? Colors.white
                                      : Colors.white,
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (user != null)
                    FutureBuilder<String?>(
                      future: _getUserName(user.uid),
                      builder: (context, snapshot) {
                        final username = snapshot.data;
                        return Text(
                          username != null && username.isNotEmpty ? username : '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.watch<ThemeProvider>().isDarkMode
                                ? Colors.white
                                : Colors.blue,
                          ),
                        );
                      },
                    ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.watch<ThemeProvider>().isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context,
                    'Edit Profile',
                    Icons.edit,
                    () => _showEditProfileDialog(context),
                  ),
                  _buildSettingCard(
                    context,
                    'Change Password',
                    Icons.lock,
                    () => _showChangePasswordDialog(context),
                  ),
                  _buildSettingCard(
                    context,
                    'Notifications',
                    Icons.notifications,
                    () => _showNotificationSettings(context),
                  ),
                  _buildSettingCard(
                    context,
                    'Privacy',
                    Icons.privacy_tip,
                    () => _showPrivacySettings(context),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context,
                    'Language',
                    Icons.language,
                    () => _showLanguageSettings(context),
                  ),
                  _buildSettingCard(
                    context,
                    'Theme',
                    Icons.palette,
                    () => _showThemeDialog(context),
                  ),
                  _buildSettingCard(
                    context,
                    'About',
                    Icons.info,
                    () => _showAboutDialog(context),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                  context.read<AuthProvider>().signOut();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                    (route) => false,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: title == 'Theme'
            ? Switch(
                value: context.watch<ThemeProvider>().isDarkMode,
                onChanged: (value) {
                  context.read<ThemeProvider>().toggleTheme();
                },
                activeColor: const Color(0xFFFFB300), // yellow[700]
                activeTrackColor: const Color(0xFFFFB300).withOpacity(0.5),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light Mode'),
              leading: const Icon(Icons.light_mode),
              selected: !isDarkMode,
              selectedTileColor: Colors.blue.withOpacity(0.1),
              onTap: () {
                if (isDarkMode) {
                  context.read<ThemeProvider>().toggleTheme();
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark Mode'),
              leading: const Icon(Icons.dark_mode),
              selected: isDarkMode,
              selectedTileColor: const Color(0xFF3D3F4B).withOpacity(0.3),
              onTap: () {
                if (!isDarkMode) {
                  context.read<ThemeProvider>().toggleTheme();
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
