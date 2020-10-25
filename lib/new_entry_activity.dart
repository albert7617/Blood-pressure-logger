import 'package:blood_pressure_logger/model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AddEntryActivity extends StatefulWidget {
  const AddEntryActivity({
    Key key, this.argOffset, this.argIsDay, this.argSystolic, this.argDiastolic, this.argPulse, this.title,
  }) : super(key: key);
  final String title;
  final int argOffset;
  final int argSystolic;
  final int argDiastolic;
  final int argPulse;
  final bool argIsDay;
  @override
  _AddEntryActivityState createState() => _AddEntryActivityState();
}

class _AddEntryActivityState extends State<AddEntryActivity> {
  int _selectionDayNight;
  DateTime _selectionDate;

  final FocusNode _systolicFocus = FocusNode();
  final FocusNode _diastolicFocus = FocusNode();
  final FocusNode _pulseFocus = FocusNode();
  final FocusNode _saveFocus = FocusNode();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();

  Future<Null> _selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateFormat('yMd', 'zh_TW').parse(_dateController.text),
        firstDate: DateTime(1990, 1),
        lastDate: DateTime(2100));
    if (picked != null && picked != selectedDate)
      setState(() {
        _dateController.text = DateFormat('yMd', 'zh_TW').format(picked);
        _selectionDate = picked;
      });
  }

  @override
  void initState() {
    if(widget.argOffset == null) {
      _selectionDate = DateTime.now();
    } else {
      _selectionDate = DateTime.now().add(Duration(days: widget.argOffset));
    }
    if(widget.argIsDay == null) {
      _selectionDayNight = (_selectionDate.hour>5 && _selectionDate.hour<18) ? 0 : 1;
    } else {
      _selectionDayNight = widget.argIsDay ? 0 : 1;
    }
    _dateController.text = DateFormat('yMd', 'zh_TW').format(_selectionDate);
    if(widget.argDiastolic != null) {
      _diastolicController.text = widget.argDiastolic.toString();
    }
    if(widget.argSystolic != null) {
      _systolicController.text = widget.argSystolic.toString();
    }
    if(widget.argPulse != null) {
      _pulseController.text = widget.argPulse.toString();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.title)
        ),
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                    child: GestureDetector(
                        onTap:()=>_selectDate(context),
                        child:AbsorbPointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                            child: TextField(
                              controller: _dateController,
                              decoration: new InputDecoration(
                                labelText: "日期",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.today),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                            ),
                          ),
                        )
                    )
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  child: FlutterToggleTab(
                    labels: ["白天","晚上"],
                    width: 95.0,
                    icons: [Icons.brightness_low,Icons.brightness_3],
                    initialIndex: _selectionDayNight,
                    selectedIndex: _selectionDayNight,
                    selectedLabelIndex: (idx)=>{
                      setState(() {
                        _selectionDayNight = idx;
                      })
                    },
                    borderRadius: 10,
                    selectedTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                    unSelectedTextStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  child: TextField(
                    controller: _diastolicController,
                    onSubmitted: (val) {
                      _fieldFocusChange(context, _diastolicFocus, _systolicFocus);
                    },
                    keyboardType: TextInputType.number,
                    focusNode: _diastolicFocus,
                    textInputAction: TextInputAction.next,
                    decoration: new InputDecoration(
                        labelText: "舒張壓",
                        prefixIcon: Icon(Icons.favorite_border),
                        border: OutlineInputBorder()
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  child: TextField(
                    controller: _systolicController,
                    onSubmitted: (val) {
                      _fieldFocusChange(context, _systolicFocus, _pulseFocus);
                    },
                    keyboardType: TextInputType.number,
                    focusNode: _systolicFocus,
                    textInputAction: TextInputAction.next,
                    decoration: new InputDecoration(
                        labelText: "收縮壓",
                        prefixIcon: Icon(Icons.favorite),
                        border: OutlineInputBorder()
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  child: TextField(
                    controller: _pulseController,
                    onSubmitted: (val) {
                      _fieldFocusChange(context, _pulseFocus, _saveFocus);
                    },
                    keyboardType: TextInputType.number,
                    focusNode: _pulseFocus,
                    textInputAction: TextInputAction.done,
                    decoration: new InputDecoration(
                        labelText: "心律",
                        prefixIcon: Icon(MdiIcons.heartPulse),
                        border: OutlineInputBorder()
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0.0),
                  child: ButtonTheme(
                    minWidth: double.infinity,
                    child: RaisedButton(
                      focusNode: _saveFocus,
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      child: Text("儲存"),
                      onPressed: () {
                        if(_selectionDayNight == 0) {
                          _selectionDate = DateTime(_selectionDate.year, _selectionDate.month, _selectionDate.day, 8, 0);
                        } else {
                          _selectionDate = DateTime(_selectionDate.year, _selectionDate.month, _selectionDate.day, 20, 0);
                        }
                        final fido = LoggingEntry(
                          diastolic: int.parse(_diastolicController.text),
                          systolic: int.parse(_systolicController.text),
                          pulse: int.parse(_pulseController.text),
                          dateTime: _selectionDate
                        );
                        insertData(fido);
                        DateTime nowInDay = DateTime.now();
                        Navigator.of(context).pop(_selectionDate.difference(DateTime(nowInDay.year, nowInDay.month, nowInDay.day)).inDays);
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        )
    );
  }

  // Change focus function
  _fieldFocusChange(BuildContext context, FocusNode currentFocus,FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

// Define a function that inserts dogs into the database
Future<void> insertData(LoggingEntry entry) async {
  final Future<Database> database = openDatabase(join(await getDatabasesPath(), 'health_database.db'));
  // Get a reference to the database.
  final Database db = await database;
  await db.insert(
    'health',
    entry.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );


}
