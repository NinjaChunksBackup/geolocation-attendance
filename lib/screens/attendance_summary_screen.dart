// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';

// class AttendanceSummaryScreen extends StatefulWidget {
//   @override
//   _AttendanceSummaryScreenState createState() =>
//       _AttendanceSummaryScreenState();
// }

// class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
//   late CalendarFormat _calendarFormat;
//   late DateTime _focusedDay;
//   late DateTime _selectedDay;
//   late Map<DateTime, List<AttendanceRecord>> _attendanceRecords;

//   @override
//   void initState() {
//     super.initState();
//     _calendarFormat = CalendarFormat.month;
//     _focusedDay = DateTime.now();
//     _selectedDay = _focusedDay;
//     _attendanceRecords = _generateDummyData();
//   }

//   Map<DateTime, List<AttendanceRecord>> _generateDummyData() {
//     final Map<DateTime, List<AttendanceRecord>> dummyData = {};
//     final now = DateTime.now();
//     for (int i = 0; i < 60; i++) {
//       final date = now.subtract(Duration(days: i));
//       if (date.weekday < DateTime.saturday) {
//         final startTime = DateTime(date.year, date.month, date.day, 9, 0);
//         final endTime = DateTime(date.year, date.month, date.day, 17, 30);
//         final duration = endTime.difference(startTime);
//         dummyData[date] = [
//           AttendanceRecord(
//             date: date,
//             checkIn: startTime,
//             checkOut: endTime,
//             duration: duration,
//           )
//         ];
//       }
//     }
//     return dummyData;
//   }

//   List<AttendanceRecord> _getAttendanceForDay(DateTime day) {
//     return _attendanceRecords[day] ?? [];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           _buildAppBar(),
//           SliverToBoxAdapter(child: _buildCalendar()),
//           SliverToBoxAdapter(child: _buildAttendanceDetails()),
//           SliverToBoxAdapter(child: _buildWeeklyChart()),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return SliverAppBar(
//       expandedHeight: 200.0,
//       floating: false,
//       pinned: true,
//       flexibleSpace: FlexibleSpaceBar(
//         title:
//             Text('Attendance Summary', style: TextStyle(color: Colors.white)),
//         background: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topRight,
//               end: Alignment.bottomLeft,
//               colors: [Colors.blue[400]!, Colors.blue[900]!],
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.access_time, size: 60, color: Colors.white),
//               SizedBox(height: 8),
//               Text(
//                 'Your Time, Your Success',
//                 style: TextStyle(color: Colors.white70, fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCalendar() {
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(8.0),
//         child: TableCalendar(
//           firstDay: DateTime.utc(2021, 1, 1),
//           lastDay: DateTime.utc(2030, 12, 31),
//           focusedDay: _focusedDay,
//           calendarFormat: _calendarFormat,
//           selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//           onDaySelected: (selectedDay, focusedDay) {
//             setState(() {
//               _selectedDay = selectedDay;
//               _focusedDay = focusedDay;
//             });
//           },
//           onFormatChanged: (format) {
//             setState(() {
//               _calendarFormat = format;
//             });
//           },
//           eventLoader: _getAttendanceForDay,
//           calendarStyle: CalendarStyle(
//             markerDecoration: BoxDecoration(
//               color: Colors.blue[700],
//               shape: BoxShape.circle,
//             ),
//             selectedDecoration: BoxDecoration(
//               color: Colors.blue[400],
//               shape: BoxShape.circle,
//             ),
//             todayDecoration: BoxDecoration(
//               color: Colors.blue[200],
//               shape: BoxShape.circle,
//             ),
//           ),
//           headerStyle: HeaderStyle(
//             formatButtonDecoration: BoxDecoration(
//               color: Colors.blue[400],
//               borderRadius: BorderRadius.circular(20.0),
//             ),
//             formatButtonTextStyle: TextStyle(color: Colors.white),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceDetails() {
//     final records = _getAttendanceForDay(_selectedDay);
//     if (records.isEmpty) {
//       return Card(
//         margin: EdgeInsets.all(8.0),
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Text(
//             'No attendance record for ${DateFormat('MMMM d, y').format(_selectedDay)}',
//             style: TextStyle(fontSize: 16),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }

//     final record = records[0];
//     return Card(
//       margin: EdgeInsets.all(8.0),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               DateFormat('MMMM d, y').format(_selectedDay),
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             _buildDetailRow(
//                 'Check In', DateFormat('HH:mm').format(record.checkIn)),
//             _buildDetailRow(
//                 'Check Out', DateFormat('HH:mm').format(record.checkOut)),
//             _buildDetailRow('Duration',
//                 '${record.duration.inHours}h ${record.duration.inMinutes % 60}m'),
//             SizedBox(height: 16),
//             LinearProgressIndicator(
//               value: record.duration.inHours / 8,
//               backgroundColor: Colors.grey[200],
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Daily Goal: 8 hours',
//               style: TextStyle(color: Colors.grey[600], fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: TextStyle(color: Colors.grey[600])),
//           Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// Widget _buildWeeklyChart() {
//   final weekDays = List.generate(7, (index) => _selectedDay.subtract(Duration(days: _selectedDay.weekday - index - 1)));
//   final attendanceData = weekDays.map((day) {
//     final records = _getAttendanceForDay(day);
//     return records.isNotEmpty ? records[0].duration.inHours : 0;
//   }).toList();

//   return Card(
//     margin: EdgeInsets.all(8.0),
//     elevation: 4,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     child: Padding(
//       padding: EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Weekly Overview',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 16),
//           Container(
//             height: 200,
//             child: BarChart(
//               BarChartData(
//                 alignment: BarChartAlignment.spaceAround,
//                 maxY: 10,
//                 barTouchData: BarTouchData(enabled: false),
//                 titlesData: FlTitlesData(
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         final style = TextStyle(
//                           color: Colors.grey,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         );
//                         String text;
//                         switch (value.toInt()) {
//                           case 0:
//                             text = 'M';
//                             break;
//                           case 1:
//                             text = 'T';
//                             break;
//                           case 2:
//                             text = 'W';
//                             break;
//                           case 3:
//                             text = 'T';
//                             break;
//                           case 4:
//                             text = 'F';
//                             break;
//                           case 5:
//                             text = 'S';
//                             break;
//                           case 6:
//                             text = 'S';
//                             break;
//                           default:
//                             text = '';
//                             break;
//                         }
//                         return Text(text, style: style);
//                       },
//                       reservedSize: 30,
//                     ),
//                   ),
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) => Text(
//                         value.toString(),
//                         style: TextStyle(
//                           color: Colors.grey,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                       ),
//                       reservedSize: 40,
//                       margin: 16,
//                     ),
//                   ),
//                 ),
//                 borderData: FlBorderData(show: false),
//                 barGroups: List.generate(7, (i) {
//                   return BarChartGroupData(
//                     x: i,
//                     barRods: [
//                       BarChartRodData(
//                         fromY: 0,
//                         toY: attendanceData[i].toDouble(),
//                         color: Colors.lightBlueAccent,
//                         width: 20,
//                       ),
//                     ],
//                   );
//                 }),
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// class AttendanceRecord {
//   final DateTime date;
//   final DateTime checkIn;
//   final DateTime checkOut;
//   final Duration duration;

//   AttendanceRecord({
//     required this.date,
//     required this.checkIn,
//     required this.checkOut,
//     required this.duration,
//   });
// };