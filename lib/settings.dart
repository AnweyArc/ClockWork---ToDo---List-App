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
  Color _timeTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNightMode = prefs.getBool('isDarkMode') ?? false;
      _timeTextColor = Color(prefs.getInt('timeTextColor') ?? Colors.white.value);
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isNightMode);
    prefs.setInt('timeTextColor', _timeTextColor.value);
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
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(); // Ensure toggleTheme is accessible
                _saveSettings();
              });
            },
          ),
          ListTile(
            title: Text('Time Text Color'),
            trailing: GestureDetector(
              onTap: () {
                _showColorPickerDialog(context);
              },
              child: Container(
                width: 24,
                height: 24,
                color: _timeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick Time Text Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _timeTextColor,
              onColorChanged: (color) {
                setState(() {
                  _timeTextColor = color;
                  _saveSettings();
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
