import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'job_feed.dart';
import '../student/notifications_screen.dart';
import 'student_profile_edit.dart';
import 'offers_screen.dart';
import 'placement_calendar_screen.dart';
import 'bookmarked_jobs_screen.dart';
import '../shared/announcements_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    JobFeed(),
    PlacementCalendarScreen(),
    OffersScreen(),
    BookmarkedJobsScreen(),
    AnnouncementsScreen(),
    NotificationsScreen(),
    StudentProfileEdit(),
  ];

  final _icons = const [
    Icons.work_rounded,
    Icons.calendar_month_rounded,
    Icons.card_giftcard_rounded,
    Icons.bookmark_rounded,
    Icons.campaign_rounded,
    Icons.notifications_rounded,
    Icons.person_rounded,
  ];

  final _labels = const ['Jobs', 'Calendar', 'Offers', 'Saved', 'Notices', 'Alerts', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_labels[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(_labels.length, (i) => NavigationDestination(
          icon: Icon(_icons[i]),
          label: _labels[i],
        )),
      ),
    );
  }
}
