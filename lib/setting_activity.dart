import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingActivity extends StatefulWidget {
  @override
  _SettingActivityState createState() => _SettingActivityState();
}

class _SettingActivityState extends State<SettingActivity> {
  Future<Map<String,int>> _data;

  @override
  void initState() {
    _data = getStoredData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("設定")
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<Map<String,int>>(
            future: _data,
            builder: (BuildContext context, AsyncSnapshot<Map<String,int>> snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    ConfigSection(title: "心律", leadingIcon: Icon(MdiIcons.heartPulse), type: 'pulse',
                      danger: snapshot.data['pulseDanger'], waring: snapshot.data['pulseWarning'],),
                    Divider(),
                    ConfigSection(title: "收縮壓", leadingIcon: Icon(Icons.favorite), type: 'systolic',
                      danger: snapshot.data['systolicDanger'], waring: snapshot.data['systolicWarning'],),
                    Divider(),
                    ConfigSection(title: "舒張壓", leadingIcon: Icon(Icons.favorite_border), type: 'diastolic',
                      danger: snapshot.data['diastolicDanger'], waring: snapshot.data['diastolicWarning'],),
                    Divider(),
                  ],
                );
              } else {
                return Padding(padding: const EdgeInsets.all(4.0),);
              }
            }
          )
        )
    );
  }
}

Future<Map<String,int>> getStoredData() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    "diastolicDanger": prefs.getInt('diastolicDanger') ?? 140,
    "diastolicWarning": prefs.getInt('diastolicWarning') ?? 120,
    "systolicDanger": prefs.getInt('systolicDanger') ?? 90,
    "systolicWarning": prefs.getInt('systolicWarning') ?? 80,
    "pulseDanger": prefs.getInt('pulseDanger') ?? 90,
    "pulseWarning": prefs.getInt('pulseWarning') ?? 80,
  };
}

class ConfigSection extends StatelessWidget {
  const ConfigSection({
    Key key, @required this.title, @required this.leadingIcon, @required this.type, @required this.danger, @required this.waring,
  }) : super(key: key);
  final String title;
  final Icon leadingIcon;
  final String type;
  final int danger, waring;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: leadingIcon,
            title: Text(title, style: TextStyle(fontSize: 20),),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(flex: 1,child: Text("紅", style: TextStyle(fontSize: 20, color: Colors.red),)),
              Flexible(flex: 1,child: ValueField(index: type+"Danger", value: danger,)),
              Flexible(flex: 1,child: Text("橘", style: TextStyle(fontSize: 20, color: Colors.deepOrangeAccent),)),
              Flexible(flex: 1,child: ValueField(index: type+"Waring", value: waring,)),
              Flexible(flex: 1,child: Text("綠", style: TextStyle(fontSize: 20, color: Colors.green),)),
            ],
          )
        ],
      ),
    );
  }
}

class ValueField extends StatelessWidget {
  const ValueField({
    Key key, @required this.value, @required this.index,
  }) : super(key: key);
  final int value;
  final String index;
  @override
  Widget build(BuildContext context) {
    return TextFormField (
      style: TextStyle(fontSize: 24),
      initialValue: value.toString(),
      onFieldSubmitted: (String val) async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt(index, int.parse(val));
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        isCollapsed: true,
      ),
    );
  }
}

