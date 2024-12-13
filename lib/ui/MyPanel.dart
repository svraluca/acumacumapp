import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class ServiceSearchData {
  final String serviceName;
  final int searchCount;
  final String category;

  ServiceSearchData({
    required this.serviceName,
    required this.searchCount,
    required this.category,
  });
}

class MyPanel extends StatefulWidget {
  @override
  _MyPanelState createState() => _MyPanelState();
}

class _MyPanelState extends State<MyPanel> {
  List<ServiceSearchData> topSearches = [];
  Map<String, dynamic> insights = {};
  bool isLoading = true;
  bool isSearchLoading = true;
  int currentWeekBookings = 0;
  int lastWeekBookings = 0;
  int currentMonthBookings = 0;
  int lastMonthBookings = 0;
  double weeklyGrowth = 0;
  double monthlyGrowth = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await fetchBookingStatistics();
    fetchTopSearchedServices();
  }

  Future<void> fetchBookingStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      print('Current User ID: ${user.uid}');

      // Get bookings
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Bookings')
          .where('status', isEqualTo: 'accepted')
          .get();

      print('Total bookings found: ${bookingsSnapshot.docs.length}');

      // Process each booking
      int currentWeekCount = 0;
      int lastWeekCount = 0;
      int currentMonthCount = 0;
      int lastMonthCount = 0;

      for (var doc in bookingsSnapshot.docs) {
        try {
          final data = doc.data();
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          
          if (isDateInCurrentWeek(createdAt)) currentWeekCount++;
          if (isDateInLastWeek(createdAt)) lastWeekCount++;
          if (isDateInCurrentMonth(createdAt)) currentMonthCount++;
          if (isDateInLastMonth(createdAt)) lastMonthCount++;
        } catch (e) {
          print('Error processing booking: $e');
        }
      }

      setState(() {
        currentWeekBookings = currentWeekCount;
        lastWeekBookings = lastWeekCount;
        currentMonthBookings = currentMonthCount;
        lastMonthBookings = lastMonthCount;

        weeklyGrowth = lastWeekBookings != 0 
            ? ((currentWeekBookings - lastWeekBookings) / lastWeekBookings) * 100 
            : (currentWeekBookings > 0 ? 100 : 0);
        
        monthlyGrowth = lastMonthBookings != 0
            ? ((currentMonthBookings - lastMonthBookings) / lastMonthBookings) * 100
            : (currentMonthBookings > 0 ? 100 : 0);
            
        isLoading = false;
      });

    } catch (e) {
      print('Error fetching booking statistics: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTopSearchedServices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isSearchLoading = false);
        return;
      }

      // Get user's category from the correct path
      final businessDetailDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('BusinessAccount')
          .doc('detail')
          .get();

      if (!businessDetailDoc.exists) {
        print('Business detail doc does not exist');
        setState(() => isSearchLoading = false);
        return;
      }

      final businessData = businessDetailDoc.data();
      print('Business detail data: $businessData');

      // Check both category and mainCategory fields
      final userCategory = businessData?['category'] ?? businessData?['mainCategory'];
      print('Current User Category: $userCategory');

      if (userCategory == null || userCategory.isEmpty) {
        print('No category found for user');
        setState(() => isSearchLoading = false);
        return;
      }

      // Query for both category and mainCategory
      final searchesSnapshot = await FirebaseFirestore.instance
          .collection('serviceSearches')
          .where('category', whereIn: [userCategory])  // Using whereIn for potential future expansion
          .where('isServiceSearch', isEqualTo: true)
          .orderBy('searchCount', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(5)
          .get();

      print('Found ${searchesSnapshot.docs.length} searches for category $userCategory');
      searchesSnapshot.docs.forEach((doc) {
        print('Document ID: ${doc.id}');
        print('Document data: ${doc.data()}');
      });

      final searches = searchesSnapshot.docs.map((doc) {
        final data = doc.data();
        return ServiceSearchData(
          serviceName: data['serviceName'] as String,
          searchCount: data['searchCount'] as int,
          category: data['category'] as String,
        );
      }).toList();

      setState(() {
        topSearches = searches;
        if (searches.isNotEmpty) {
          double average = searches.map((s) => s.searchCount).reduce((a, b) => a + b) / searches.length;
          int highest = searches.map((s) => s.searchCount).reduce((a, b) => a > b ? a : b);
          insights = {
            'average': average,
            'peak': highest,
            'trending': searches.first.searchCount > average,
          };
        }
        isSearchLoading = false;
      });

    } catch (e) {
      print('Error fetching search statistics: $e');
      print('Error details: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
      setState(() => isSearchLoading = false);
    }
  }

  bool isDateInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekEnd = currentWeekStart.add(Duration(days: 6));
    return date.isAfter(currentWeekStart.subtract(Duration(days: 1))) && 
           date.isBefore(currentWeekEnd.add(Duration(days: 1)));
  }

  bool isDateInLastWeek(DateTime date) {
    final now = DateTime.now();
    final lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
    final lastWeekEnd = lastWeekStart.add(Duration(days: 6));
    return date.isAfter(lastWeekStart.subtract(Duration(days: 1))) && 
           date.isBefore(lastWeekEnd.add(Duration(days: 1)));
  }

  bool isDateInCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  bool isDateInLastMonth(DateTime date) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return date.year == lastMonth.year && date.month == lastMonth.month;
  }

  Widget _buildSearchAnalytics() {
    if (topSearches.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cele mai căutate servicii din categoria ta',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vrem să îți oferim sugestii care te-ar putea inspira',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(fontSize: 12),
                labelRotation: 45,
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compact(),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x : point.y searches',
              ),
              series: <CartesianSeries>[
                ColumnSeries<ServiceSearchData, String>(
                  dataSource: topSearches,
                  xValueMapper: (ServiceSearchData data, _) => data.serviceName,
                  yValueMapper: (ServiceSearchData data, _) => data.searchCount,
                  name: 'Searches',
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                  ),
                  color: Colors.blue.shade300,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildInsightCards(),
        ],
      ),
    );
  }

  Widget _buildInsightCards() {
    return Column(
      children: [
        Text(
          'Statistici căutări servicii',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Media căutărilor',
                '${insights['average']?.toStringAsFixed(1) ?? 'N/A'}',
                Icons.analytics,
                Colors.blue.shade100,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard(
                'Căutări maxime',
                '${insights['peak']?.toString() ?? 'N/A'}',
                Icons.trending_up,
                Colors.green.shade100,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color, {double fontSize = 12}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingStatistics() {
    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistici servicii vândute',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Săptămâna aceasta',
                  '$currentWeekBookings',
                  weeklyGrowth,
                  'Săptămâna trecută: $lastWeekBookings',
                  Colors.blue.shade100,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Luna aceasta',
                  '$currentMonthBookings',
                  monthlyGrowth,
                  'Luna trecută: $lastMonthBookings',
                  Colors.green.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, double growth, String comparison, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: growth >= 0 ? Colors.green : Colors.red,
              ),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: growth >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            comparison,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Analytics Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookingStatistics(),
                if (!isSearchLoading && topSearches.isNotEmpty) 
                  _buildSearchAnalytics(),
              ],
            ),
          ),
    );
  }
}
