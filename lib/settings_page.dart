import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkModeEnabled = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: (_) => _buildBody(),
      smallBody: (_) => _buildSmallBody(),
      secondaryBody: (_) => _buildSecondaryBody(),
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.list),
          label: 'Voting List',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDarkModeToggle(),
          SizedBox(height: 16.0),
          _buildLanguageDropdown(),
          SizedBox(height: 16.0),
          _buildNotificationSettings(),
          SizedBox(height: 16.0),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSmallBody() {
    return _buildBody();
  }

  Widget _buildSecondaryBody() {
    return Container(
      color: Colors.blue.shade100,
      child: Center(
        child: Text(
          'Secondary Body',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return SwitchListTile(
      title: Text('Dark Mode'),
      value: _darkModeEnabled,
      onChanged: (value) {
        setState(() {
          _darkModeEnabled = value;
        });
      },
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButtonFormField<String>(
      value: _language,
      onChanged: (value) {
        setState(() {
          _language = value!;
        });
      },
      items: ['English', 'Spanish', 'French']
          .map((language) => DropdownMenuItem(
                value: language,
                child: Text(language),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: 'Language',
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return ExpansionTile(
      title: Text('Notification Settings'),
      children: [
        CheckboxListTile(
          title: Text('Enable Notifications'),
          value: true,
          onChanged: (value) {
            // Update notification settings
          },
        ),
        CheckboxListTile(
          title: Text('Sound'),
          value: true,
          onChanged: (value) {
            // Update sound settings
          },
        ),
        CheckboxListTile(
          title: Text('Vibrate'),
          value: false,
          onChanged: (value) {
            // Update vibration settings
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.0),
        Text('Version 1.0.0'),
        SizedBox(height: 8.0),
        Text('Developed by Your Company'),
      ],
    );
  }
}