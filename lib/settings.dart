import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


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
                // You can toggle dark mode theme here
                // Example: Theme.of(context).brightness = _isNightMode ? Brightness.dark : Brightness.light;
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