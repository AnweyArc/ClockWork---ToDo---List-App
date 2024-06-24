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
          ),
          Divider(),
          _buildColorPickerListTile(
            'Task List Background Color',
            _taskListBackgroundColor,
            (color) {
              setState(() {
                _taskListBackgroundColor = color;
                _saveSettings();
              });
            },
          ),
          Divider(),
          _buildFontSizeListTile(),
          Divider(),
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

  Widget _buildColorPickerListTile(String title, Color color, ValueChanged<Color> onColorChanged) {
    return ListTile(
      title: Text(title),
      trailing: CircleAvatar(
        backgroundColor: color,
        radius: 20,
      ),
      onTap: () async {
        final selectedColor = await showDialog<Color>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: color,
                onColorChanged: onColorChanged,
                showLabel: true,
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(color);
                },
              ),
            ],
          ),
        );
        if (selectedColor != null && selectedColor != color) {
          onColorChanged(selectedColor);
          _saveSettings();
        }
      },
    );
  }

  Widget _buildFontSizeListTile() {
    return ExpansionTile(
      title: Text('Appearance'),
      children: [
        ListTile(
          title: Text('Font Size'),
          subtitle: Text('Current Font Size: ${_fontSize.toStringAsFixed(1)}'),
          trailing: Slider(
            value: _fontSize,
            min: 12,
            max: 24,
            divisions: 12,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
                _saveSettings();
              });
            },
          ),
        ),
        ListTile(
          title: Text('Font Style'),
          subtitle: Text('Current Font Style: ${_fontStyle.toString().split('.').last}'),
          trailing: DropdownButton<FontStyle>(
            value: _fontStyle,
            onChanged: (FontStyle? newValue) {
              if (newValue != null) {
                setState(() {
                  _fontStyle = newValue;
                  _saveSettings();
                });
              }
            },
            items: FontStyle.values.map<DropdownMenuItem<FontStyle>>((FontStyle style) {
              return DropdownMenuItem<FontStyle>(
                value: style,
                child: Text(style.toString().split('.').last),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
