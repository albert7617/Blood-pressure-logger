class LoggingEntry {
  final int pulse, systolic, diastolic;
  final DateTime dateTime;
  LoggingEntry({this.dateTime, this.diastolic, this.systolic, this.pulse});
  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'datetime': dateTime.toIso8601String(),
      'pulse': pulse,
      'systolic': systolic,
      'diastolic': diastolic,
    };
  }
}

class DataModel {
  final int id, offset, pulse, systolic, diastolic;
  final bool isDay;
  DataModel({this.id, this.offset, this.isDay, this.diastolic, this.systolic, this.pulse});
}
