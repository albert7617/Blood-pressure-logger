import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import 'main.dart';
import 'model.dart';
import 'new_entry_activity.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          child: Row(
            children: [
              Container(
                width: 140,
                child: Text(
                  "日期",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Expanded(child: Row(
                children: [
                  ListHeaderCell(isDay: "白天"),
                  ListHeaderCell(isDay: "晚上"),
                ],
              ),),
            ],
          ),
        ),
      ),
    );
  }
}

class ListHeaderCell extends StatelessWidget {
  const ListHeaderCell({
    Key key,
    @required this.isDay
  }) : super(key: key);
  final String isDay;
  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 1,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(isDay),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Text("心律"),
                    Text("收縮壓"),
                    Text("舒張壓"),
                  ],
                ),
              )
            ],
          ),
        ),),
    );
  }
}

class ListItemTile extends StatelessWidget {
  const ListItemTile({
    Key key,
    @required this.widget,
    @required this.index,
    @required this.dataModel,
    @required this.dateTime,
    @required this.threshold,
    @required this.callback,
  }) : super(key: key);

  final Function callback;
  final DateTime dateTime;
  final MyHomePage widget;
  final int index;
  final Tuple2<DataModel, DataModel> dataModel;
  final Map<String, int> threshold;

  @override
  Widget build(BuildContext context) {
    Color highlight;
    if(index == 0) {
      highlight = Colors.blue;
    } else {
      highlight = Colors.black;
    }
    Widget leftCell, rightCell;
    if (dataModel == null) {
      leftCell = AddEntryCell(dateTime: dateTime, isDay: true, callback: callback, offset: index,);
      rightCell = AddEntryCell(dateTime: dateTime, isDay: false, callback: callback, offset: index);
    } else {
      if (dataModel.item1 == null) {
        leftCell = AddEntryCell(dateTime: dateTime, isDay: true, callback: callback, offset: index,);
      } else {
        leftCell = DataEntryCell(data: dataModel.item1, thresholds: threshold, callback: callback,);
      }
      if (dataModel.item2 == null) {
        rightCell = AddEntryCell(dateTime: dateTime, isDay: false, callback: callback, offset: index,);
      } else {
        rightCell = DataEntryCell(data: dataModel.item2, thresholds: threshold, callback: callback,);
      }
    }
    return Row(
      children: [
        Container(
          width: 140,
          child: Text(
            DateFormat('yMd', 'zh_TW').format(DateTime.now().add(Duration(days: index))),
            style: Theme.of(context).textTheme.bodyText1.apply(color: highlight),
          ),
        ),
        Expanded(child: Row(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            leftCell,
            rightCell,
          ],
        )
        ),
      ],
    );
  }
}

class AddEntryCell extends StatelessWidget {
  const AddEntryCell({
    Key key,
    @required this.dateTime,
    @required this.isDay,
    @required this.callback,
    @required this.offset,
  }) : super(key: key);
  final Function callback;
  final DateTime dateTime;
  final bool isDay;
  final int offset;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Material(child: InkWell(
      onTap: () async {
        final retOffset = await Navigator.of(context).push(
          new MaterialPageRoute(
            builder: (context) {return AddEntryActivity(title: '新增一筆資料', argOffset: offset, argIsDay: isDay);}
          )
        );
        callback(retOffset);
      },
      child: Container(
        height: 96,
        child: Icon(Icons.add),
      ),
    ),),);
  }
}

class DataEntryCell extends StatelessWidget {
  const DataEntryCell({
    Key key,
    @required this.data,
    @required this.thresholds,
    @required this.callback,
  }) : super(key: key);
  final Function callback;
  final DataModel data;
  final Map<String, int> thresholds;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Material(child: InkWell(
      onTap: () async {
        final retOffset = await Navigator.of(context).push(
          new MaterialPageRoute(
            builder: (context) {
              return AddEntryActivity(
                title: '編輯一筆資料',
                argOffset: data.offset, argIsDay: data.isDay, argPulse: data.pulse,
                argDiastolic: data.diastolic, argSystolic: data.systolic,);
            }
          )
        );
        callback(retOffset);
      },
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Container(
          height: 84,
          child: Column(
            children: [
              Text(data.diastolic.toString(), style: Theme.of(context).textTheme.bodyText1.apply(
                  color: data.diastolic>thresholds['diastolicDanger'] ? Colors.red :
                    (data.diastolic>thresholds['diastolicWarning']) ? Colors.orange : Colors.green
                )
              ),
              Text(data.systolic.toString(), style: Theme.of(context).textTheme.bodyText1.apply(
                  color: data.systolic>thresholds['systolicDanger'] ? Colors.red :
                  data.systolic>thresholds['systolicWarning'] ? Colors.orange : Colors.green
                )
              ),
              Text(data.pulse.toString(), style: Theme.of(context).textTheme.bodyText1.apply(
                  color: data.pulse>thresholds['pulseDanger'] ? Colors.red :
                  data.pulse>thresholds['pulseWarning'] ? Colors.orange : Colors.green
                )
              ),
            ],
          ),
        ),
      ),
      // child: Icon(Icons.add),
    )));
  }
}
