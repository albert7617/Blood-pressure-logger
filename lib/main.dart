import 'package:blood_pressure_logger/setting_activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';

import 'cells_and_tiles.dart';
import 'model.dart';
import 'new_entry_activity.dart';

void main() async {
  initializeDateFormatting('zh_TW', null);
  Intl.defaultLocale = 'zh-TW';
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  // Open the database and store the reference.
  final Future<Database> database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'health_database.db'),
    // When the database is first created, create a table to store data.
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        "CREATE TABLE health(datetime TEXT PRIMARY KEY, diastolic INTEGER, systolic INTEGER, pulse INTEGER);",
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '血壓日記',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
            bodyText1: TextStyle(fontSize: 24),
        )
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final InfiniteScrollController _infiniteController = InfiniteScrollController(
    initialScrollOffset: 200.0,
  );
  Future<Map<String,int>> _data;
  final Map<int, Tuple2<DataModel, DataModel>>_dataList = Map();
  bool _isLoading = true;
  int _upperLoaded = -30, _lowerLoaded = 30;

  @override
  void initState() {
    super.initState();
    _data = getStoredData();
    _isLoading = true;
    _upperLoaded = -30;
    _lowerLoaded = 30;
    _loadMore(0, 60);
  }

  void _loadMore(int offset, int quantity) {
    _isLoading = true;
    fetch(offset, quantity).then((Map<int, Tuple2<DataModel, DataModel>> fetchedList) {
      _isLoading = false;
      if (fetchedList.isNotEmpty) {
        setState(() {
          fetchedList.forEach((key, value) {
            _dataList[key] = value;
          });
        });
      }
    });
  }

  void _loadSingle(int offset) {
    _isLoading = true;
    fetchSingle(offset).then((Map<int, Tuple2<DataModel, DataModel>> fetchedList) {
      _isLoading = false;
      if (fetchedList.isNotEmpty) {
        setState(() {
          fetchedList.forEach((key, value) {
            _dataList[key] = value;
          });
        });
      }
    });
  }

  Future<Map<String,int>> getStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "diastolicDanger": prefs.getInt('diastolicDanger') ?? 140,
      "diastolicWarning": prefs.getInt('diastolicWarning') ?? 120,
      "systolicDanger": prefs.getInt('systolicDanger') ?? 90,
      "systolicWarning": prefs.getInt('systolicWarning') ?? 80,
      "pulseDanger": prefs.getInt('diastolicDanger') ?? 90,
      "pulseWarning": prefs.getInt('diastolicWarning') ?? 80,
    };
  }

  void updateHomePage(int offset) {
    print(offset);
    if(offset != null) {
      _dataList.remove(offset);
      _dataList.remove(offset+1);
      _dataList.remove(offset-1);
      _loadSingle(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('血壓日記'),
        actions: [
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              _infiniteController.animateTo(200.0,
                  duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SettingActivity(),
              )).then((value) => setState(() {
                _data = getStoredData();
              }));
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _data,
        builder: (BuildContext context, AsyncSnapshot<Map<String,int>> snapshot) {
          if(snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListHeader(),
                Container(height: 1, color: Colors.grey),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InfiniteListView.separated(
                      controller: _infiniteController,
                      itemBuilder: (BuildContext context, int index) {
                        if(index <= _upperLoaded) {
                          // Load more above
                          if (!_isLoading) {
                            _loadMore(index-30, 60);
                            _upperLoaded -= 60;
                          }
                        } else if(index >= _lowerLoaded) {
                          // Load more below
                          if (!_isLoading) {
                            _loadMore(index+30, 60);
                            _lowerLoaded += 60;
                          }
                        }
                        int key = index;
                        return ListItemTile(widget: widget,
                          index: index,
                          dataModel: _dataList[key],
                          dateTime: DateTime.now().add(Duration(days: key)),
                          threshold: snapshot.data,
                          callback: this.updateHomePage,);
                      },
                      separatorBuilder: (BuildContext context, int index) => const Divider(height: 2.0),
                      anchor: 0.5,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Padding(padding: const EdgeInsets.all(4.0),);
          }

        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final retOffset = await Navigator.of(context).push(
              new MaterialPageRoute(builder: (context) => AddEntryActivity())
          );
          updateHomePage(retOffset);
        },
        tooltip: '新增資料',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Future<Map<int, Tuple2<DataModel, DataModel>>> fetch(int offset, int quantity) async {
  final Map<int, Tuple2<DataModel, DataModel>> retVal = new Map();
  final Future<Database> database = openDatabase(join(await getDatabasesPath(), 'health_database.db'));
  // Get a reference to the database.
  final Database db = await database;

  // Query the table for all The Dogs.
  //final List<Map<String, dynamic>> maps = await db.query('health');

  final DateTime center = DateTime.now().add(Duration(days: offset));
  final String startDate = DateFormat('yyyy-MM-dd').format(center.add(Duration(days: quantity~/2+1)));
  final String endDate = DateFormat('yyyy-MM-dd').format(center.add(Duration(days: -quantity~/2-1)));
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM health WHERE datetime BETWEEN \'$endDate\' AND \'$startDate\';');
  maps.forEach((element) {
    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);
    DateTime dateTime = DateTime.parse(element['datetime']);
    int offset = dateTime.difference(date).inDays;
    if(retVal.containsKey(offset)) {
      Tuple2<DataModel, DataModel> temp = retVal[offset];
      DataModel day = temp.item1;
      DataModel night = temp.item2;
      if(dateTime.hour>5&&dateTime.hour<18) {
        retVal[offset] = Tuple2<DataModel, DataModel>(DataModel(
            id: element['id'],
            offset: offset,
            isDay: true,
            diastolic: element['diastolic'],
            systolic: element['systolic'],
            pulse: element['pulse']), night);
      } else {
        retVal[offset] = Tuple2<DataModel, DataModel>(day, DataModel(
            id: element['id'],
            offset: offset,
            isDay: false,
            diastolic: element['diastolic'],
            systolic: element['systolic'],
            pulse: element['pulse']));
      }
    } else {
      if(dateTime.hour>5&&dateTime.hour<18) {
        retVal[offset] = Tuple2<DataModel, DataModel>(DataModel(
          id: element['id'],
          offset: offset,
          isDay: true,
          diastolic: element['diastolic'],
          systolic: element['systolic'],
          pulse: element['pulse']), null);
      } else {
        retVal[offset] = Tuple2<DataModel, DataModel>(null, DataModel(
          id: element['id'],
          offset: offset,
          isDay: false,
          diastolic: element['diastolic'],
          systolic: element['systolic'],
          pulse: element['pulse']));
      }
    }
  });
  return retVal;
}

Future<Map<int, Tuple2<DataModel, DataModel>>> fetchSingle(int offset) async {
  final Map<int, Tuple2<DataModel, DataModel>> retVal = new Map();
  final Future<Database> database = openDatabase(join(await getDatabasesPath(), 'health_database.db'));
  // Get a reference to the database.
  final Database db = await database;

  // Query the table for all The Dogs.
  final DateTime center = DateTime.now().add(Duration(days: offset));
  final String startDate = DateFormat('yyyy-MM-dd').format(center.add(Duration(days: -1)));
  final String endDate = DateFormat('yyyy-MM-dd').format(center.add(Duration(days: 1)));
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM health WHERE datetime BETWEEN \'$startDate\' AND \'$endDate\';');
  maps.forEach((element) {
    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);
    DateTime dateTime = DateTime.parse(element['datetime']);
    int offset = dateTime.difference(date).inDays;
    if(retVal.containsKey(offset)) {
      Tuple2<DataModel, DataModel> temp = retVal[offset];
      DataModel day = temp.item1;
      DataModel night = temp.item2;
      if(dateTime.hour>5&&dateTime.hour<18) {
        retVal[offset] = Tuple2<DataModel, DataModel>(DataModel(
            id: element['id'],
            offset: offset,
            isDay: true,
            diastolic: element['diastolic'],
            systolic: element['systolic'],
            pulse: element['pulse']), night);
      } else {
        retVal[offset] = Tuple2<DataModel, DataModel>(day, DataModel(
            id: element['id'],
            offset: offset,
            isDay: false,
            diastolic: element['diastolic'],
            systolic: element['systolic'],
            pulse: element['pulse']));
      }
    } else {
      if(dateTime.hour>5&&dateTime.hour<18) {
        retVal[offset] = Tuple2<DataModel, DataModel>(DataModel(
          id: element['id'],
          offset: offset,
          isDay: true,
          diastolic: element['diastolic'],
          systolic: element['systolic'],
          pulse: element['pulse']), null);
      } else {
        retVal[offset] = Tuple2<DataModel, DataModel>(null, DataModel(
          id: element['id'],
          offset: offset,
          isDay: false,
          diastolic: element['diastolic'],
          systolic: element['systolic'],
          pulse: element['pulse']));
      }
    }
  });
  return retVal;
}

class CustomTextStyle {
  static TextStyle pulseTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle pulseTextStyleWarning(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle pulseTextStyleDanger(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle diastolicTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle diastolicTextStyleWaring(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle diastolicTextStyleDanger(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle systolicTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle systolicTextStyleWarning(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
  static TextStyle systolicTextStyleDanger(BuildContext context) {
    return Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 24.0);
  }
}