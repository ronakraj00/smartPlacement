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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Offers'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _appBarTitle() {
    switch (_selectedIndex) {
      case 0: return 'Jobs';
      case 1: return 'Calendar';
      case 2: return 'My Offers';
      case 3: return 'Saved Jobs';
      case 4: return 'Announcements';
      case 5: return 'Notifications';
      case 6: return 'My Profile';
      default: return 'Smart Placement';
    }
  }
}
