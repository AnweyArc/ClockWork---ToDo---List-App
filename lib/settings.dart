import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNightMode = false;
  Color _taskListBackgroundColor = Colors.white;
  double _fontSize = 16.0;
  FontStyle _fontStyle = FontStyle.normal;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNightMode = prefs.getBool('isNightMode') ?? false;
      _taskListBackgroundColor = Color(prefs.getInt('backgroundColor') ?? Colors.white.value);
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _fontStyle = FontStyle.values[prefs.getInt('fontStyle') ?? FontStyle.normal.index];
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isNightMode', _isNightMode);
    prefs.setInt('backgroundColor', _taskListBackgroundColor.value);
    prefs.setDouble('fontSize', _fontSize);
    prefs.setInt('fontStyle', _fontStyle.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSwitchListTile(
            'Night Mode',
            'Enable dark theme',
            _isNightMode,
            (value) {
              setState(() {
                _isNightMode = value;
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                _saveSettings();
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildSwitchListTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}