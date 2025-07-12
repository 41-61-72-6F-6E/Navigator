import 'package:flutter/material.dart';

class DateAndTime {
  final int day;
  final int month;
  final int year;
  final int hour;
  final int minute;
  final int timeZoneHourShift;
  final int timeZoneMinuteShift;
  
  DateAndTime({
    required this.day,
    required this.month,
    required this.year,
    required this.hour,
    required this.minute,
    required this.timeZoneHourShift,
    required this.timeZoneMinuteShift
  });

  Map<String, dynamic> toJson()
  {
    return {
      'day': day,
      'month' : month,
      'year' : year,
      'hour' : hour,
      'minute' : minute,
      'timeZoneHourShift' : timeZoneHourShift,
      'timeZoneMinuteShift' : timeZoneMinuteShift
    };
  }

  factory DateAndTime.fromJson(Map<String, dynamic> json)
  {
    return DateAndTime(day: json['day'] as int, 
    month: json['month'] as int, 
    year: json['year'] as int, 
    hour: json['hour'] as int, 
    minute: json['minute'] as int, 
    timeZoneHourShift: json['timeZoneHourShift'] as int, 
    timeZoneMinuteShift: json['timeZoneMinuteShift'] as int);
  }
  
  String ISO8601String() {
    String y = year.toString().padLeft(4, '0');
    String m = month.toString().padLeft(2, '0');
    String d = day.toString().padLeft(2, '0');
    String h = hour.toString().padLeft(2, '0');
    String min = minute.toString().padLeft(2, '0');
    String tzH = timeZoneHourShift.abs().toString().padLeft(2, '0');
    String tzM = timeZoneMinuteShift.abs().toString().padLeft(2, '0');
    String tzSign = timeZoneHourShift >= 0 ? '+' : '-';
    return '$y-$m-$d'
           'T$h:$min'
           '$tzSign$tzH:$tzM';
  }
  
  factory DateAndTime.fromDateTimeAndTime(DateTime date, TimeOfDay time) {
    final now = DateTime.now();
    final tzOffset = now.timeZoneOffset;
    
    return DateAndTime(
      day: date.day, 
      month: date.month, 
      year: date.year, 
      hour: time.hour, 
      minute: time.minute, 
      timeZoneHourShift: tzOffset.inHours,
      timeZoneMinuteShift: tzOffset.inMinutes % 60
    );
  }
}