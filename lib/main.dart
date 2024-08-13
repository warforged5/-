
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'dart:convert';
import 'package:toastification/toastification.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hcuygigxjucxutavjvsc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdXlnaWd4anVjeHV0YXZqdnNjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTI4NzU1NjgsImV4cCI6MjAyODQ1MTU2OH0.0x6jIeOANj6_Y5s7EQ9tuU3GhZLZblobDAt_W2dOLJA',
  );

  final themeNotifier = ThemeNotifier();
  final themeProvider = ThemeProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeNotifier),
        ChangeNotifierProvider(create: (_) => themeProvider),
      ],
      child: MyApp(themeNotifier: themeNotifier),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const MyApp({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeNotifier),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: FutureBuilder<void>(
        future: _fetchUserThemeColor(themeNotifier),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return AnimatedBuilder(
                animation: themeNotifier,
                builder: (context, _) {
                  return MaterialApp(
                    title: 'NHS Hour Tracking',
                    debugShowCheckedModeBanner: false,
                    theme: themeProvider.isDarkMode
                        ? ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: themeNotifier.themeColor,
                              brightness: Brightness.dark,
                            ),
                          )
                        : ThemeData(
                            colorSchemeSeed: themeNotifier.themeColor,
                            useMaterial3: true,
                          ),
                    initialRoute: '/',
                    routes: {
                      '/': (context) => AuthenticationPage(),
                      '/main': (context) => MainScreen(),
                      '/admin/events': (context) => AdminEventsPage(),
                      '/admin/attendance': (context) => AdminAttendancePage(),
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _fetchUserThemeColor(ThemeNotifier themeNotifier) async {
  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('themeColor');
  final color = colorValue != null ? Color(colorValue) : Colors.blue;
  themeNotifier.updateThemeColor(color);
}
}
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  PageController _pageController = PageController();
  bool _isAdmin = false;
  

  

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchUserAdminStatus();
  }

  Future<void> _fetchUserAdminStatus() async {
  final User? user = supabase.auth.currentUser;
  final userId = user?.id;

  if (userId != null) {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('admin')
        .eq('user_id', userId);

    if (response != null && response.length > 0) {
      setState(() {
        _isAdmin = response[0]['admin'] ?? false;
      });
    }
  }
}

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;
    final List<Widget> pages = [

      if (_isAdmin) ...[
        AdminTotalHoursPage(),
        AdminEventsPage(),
        AdminAttendancePage(),
        AdminListPage(),
        SettingsPage(),
      ] else ...[
        HomePage(),
        CompletedHoursPage(),
        SettingsPage(),
      ],
    ];

    final List<BottomNavyBarItem> navItems = [
      if (_isAdmin) ...[
        BottomNavyBarItem(
          title: Text('Total Hours'),
          icon: Icon(Icons.home),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
        BottomNavyBarItem(
          title: Text('Add'),
          icon: Icon(Icons.add_circle),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
        BottomNavyBarItem(
          title: Text('Attendance'),
          icon: Icon(Icons.check_circle),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
        BottomNavyBarItem(
          title: Text('List'),
          icon: Icon(Icons.view_list),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
         BottomNavyBarItem(
          title: Text('Profile'),
          icon: Icon(Icons.account_circle),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
      ] else ...[
        BottomNavyBarItem(
        title: Text('Home'),
        icon: Icon(Icons.home),
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
        BottomNavyBarItem(
        title: Text('Hours'),
        icon: Icon(Icons.watch_later),
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.onSurface,
      ),
        BottomNavyBarItem(
          title: Text('Profile'),
          icon: Icon(Icons.account_circle),
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface,
        ),
      ],
    ];
    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                    _pageController.jumpToPage(index);
                  },
                  labelType: NavigationRailLabelType.selected,
                  destinations: navItems.map((item) {
                    return NavigationRailDestination(
                      icon: item.icon,
                      label: item.title,
                    );
                  }).toList(),
                ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavyBar(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              selectedIndex: _currentIndex,
              onItemSelected: (index) {
                setState(() => _currentIndex = index);
                _pageController.jumpToPage(index);
              },
              items: navItems,
            ),
    );
  }
}

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  @override
void initState() {
  super.initState();
  _checkAndRecoverSession();
}
  
  final _formKey = GlobalKey<FormState>();
  late String _email;
  late String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 50, 0, 230),
              Color.fromARGB(255, 46, 33, 230),
              Color.fromARGB(255, 74, 71, 241),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: Duration(milliseconds: 1000),
                    child: Text(
                      "Login",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                  SizedBox(height: 10),
                  FadeInUp(
                    duration: Duration(milliseconds: 1300),
                    child: Text(
                      "Welcome Back",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 60),
                        FadeInUp(
                          duration: Duration(milliseconds: 1400),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(47, 27, 225, 0.298),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _email = value!;
                                    },
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: TextFormField(
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _password = value!;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 40),
                        FadeInUp(
                          duration: Duration(milliseconds: 1600),
                          child: MaterialButton(
                            onPressed: _signIn,
                            height: 50,
                            color: const Color.fromARGB(255, 35, 0, 230),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _signIn() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    try {
      final response = await supabase.auth.signInWithPassword(
        email: _email,
        password: _password,
        
      );
      if (response.session != null) {
        // Sign-in successful, store the session data with an expiration time
        final prefs = await SharedPreferences.getInstance();
        final expiresAt = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
        await prefs.setString('sessionData', json.encode(response.session));
        print(json.encode(response.session));
        // Navigate to the home page
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // Sign-in failed, show an error message
        toastification.show(
	  context: context,
	  type: ToastificationType.error,
	  style: ToastificationStyle.simple,
	  title: Text("Sign-In Failed. Please try again"),
	  description: Text(""),
	  alignment: Alignment.bottomCenter,
	  autoCloseDuration: const Duration(seconds: 4),
	  borderRadius: BorderRadius.circular(12.0),
	  boxShadow: lowModeShadow,
    applyBlurEffect: true
	);
      }
    } catch (error) {
      toastification.show(
	  context: context,
	  type: ToastificationType.error,
	  style: ToastificationStyle.simple,
	  title: Text("An error occurred. Please try again."),
	  description: Text(""),
	  alignment: Alignment.center,
	  autoCloseDuration: const Duration(seconds: 4),
	  borderRadius: BorderRadius.circular(12.0),
	  boxShadow: lowModeShadow,
     applyBlurEffect: true
	  
	);
    }
  }
}

  Future<void> _checkAndRecoverSession() async {
  final prefs = await SharedPreferences.getInstance();
  final sessionDataJson = prefs.getString('sessionData');

  if (sessionDataJson != null) {
    try {
      print("error 1");
      final sessionData = json.decode(sessionDataJson);
      final accessToken = sessionData['access_token'];
      final refreshToken = sessionData['refresh_token'];
      final expiresAt = sessionData['expires_at'];
      final timeNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
     
      if (expiresAt < timeNow) {
        if (refreshToken != null) {
          final response = await supabase.auth.refreshSession(refreshToken);
          if (response.session != null) {
            // Token refreshed successfully, update the stored session data
            final newExpiresAt = DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
            final newSessionData = {
              'access_token': response.session!.accessToken,
              'refresh_token': response.session!.refreshToken,
              'expires_in': response.session!.expiresIn,
              'expires_at': newExpiresAt,
            };
            await prefs.setString('sessionData', json.encode(newSessionData));

            // Navigate to the home page
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            // Token refresh failed, remove the session data
            await prefs.remove('sessionData');
          }
        } else {
          // Refresh token not available, remove the session data
          await prefs.remove('sessionData');
        }
      } else {
        // Session is still valid, recover the session
        final response = await supabase.auth.recoverSession(sessionDataJson);
        if (response.session != null) {
          // Session recovered successfully, navigate to the home page
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          // Session recovery failed, remove the session data
          await prefs.remove('sessionData');
        }
      }
    } catch (error) {
      // Handle any errors that occur during session recovery
      print('Session recovery failed: $error');
    }
  }
}

}
// navigation

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;
   double _serviceHoursCompleted = 0;
  double _tutoringHoursCompleted = 0;
  double _meetingHoursCompleted = 0;
  double _servicePotentialHours = 0;
  double _tutoringPotentialHours = 0;
  double  _meetingPotentialHours = 0;

  List<Event> _events = [];

  @override
void initState() {
  super.initState();
  _fetchEvents();
}

  Future<void> _fetchEvents() async {
    final response = await Supabase.instance.client
        .from('Events')
        .select('*')
        .gt('date', DateTime.now().subtract(Duration(days: 1)).toIso8601String())
        .order('date');

    final List<dynamic> data = response;
    if (this.mounted) {
  setState(() {
      _events = data.map((json) => Event.fromJson(json)).toList();
    });
    _fetchCompletedHours();
}
    
  }

 Future<void> _fetchCompletedHours() async {
  final User? user = supabase.auth.currentUser;
  final userId = user?.id;

  if (userId != null) {
    final response = await Supabase.instance.client
        .from('Service hours')
        .select('hours, type')
        .eq('user_id', userId as String);

    if (response != null && _events != null) {
      final data = response;
      double serviceHours = 0;
      double tutoringHours = 0;
      double meetingHours = 0;
      double serviceHoursC = 0;
      double tutoringHoursC = 0;
      double meetingHoursC = 0;

      for (final entry in data) {
        final hours = entry['hours'];
        final eventType = entry['type'] as String;

        if (eventType == 'service' || eventType == 'Service') {
          serviceHours += hours;
          serviceHoursC += hours;
        } else if (eventType == 'tutoring' || eventType == 'Tutoring') {
          tutoringHours += hours;
          tutoringHoursC += hours;
        } else if (eventType == 'meeting' || eventType == 'Meeting') {
          meetingHours += hours;
          meetingHoursC += hours;
        }
      }

      for (final event in _events) {
        for (final timeSlot in event.timeSlots) {
          final isSignedUp = timeSlot.attendees.any((attendee) => attendee.name == userId);
          final isNotPresent = timeSlot.attendees.any((attendee) => attendee.name == userId && !attendee.isPresent);

          if (isSignedUp && isNotPresent) {
            final duration = _calculateDuration(timeSlot.time, timeSlot.endTime);
            if (event.type == 'Service') {
              serviceHours += duration;
            } else if (event.type == 'Tutoring') {
              tutoringHours += duration;
            } else if (event.type == 'Meeting') {
              meetingHours += duration;
            }
          }
        }
      }

      if (this.mounted) {
        setState(() {
          _servicePotentialHours = serviceHours;
          _tutoringPotentialHours = tutoringHours;
          _meetingPotentialHours = meetingHours;
          _serviceHoursCompleted = serviceHoursC;
          _tutoringHoursCompleted = tutoringHoursC;
          _meetingHoursCompleted = meetingHoursC;
        });
      } else {
        // Handle the error case
        print('Error fetching completed hours: ${response}');
      }
    }
  }
}

double _calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
  final startMinutes = startTime.hour * 60 + startTime.minute;
  final endMinutes = endTime.hour * 60 + endTime.minute;
  final duration = (endMinutes - startMinutes) / 60;
  return duration;
}

Widget _buildDoubleProgressBar(context, String title, double completedHours, double potentialHours, int hoursNeeded) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed: ${completedHours.toStringAsFixed(2)} hours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Stack(
          children: [
            LinearProgressIndicator(
              value: potentialHours / hoursNeeded,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5)),
              minHeight: 10,
              borderRadius: BorderRadius.all(Radius.circular(33)),
            ),
            LinearProgressIndicator(
              value: completedHours / hoursNeeded,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              minHeight: 10,
              borderRadius: BorderRadius.all(Radius.circular(33)),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          'Potential $title: ${potentialHours.toStringAsFixed(2)} hours',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

  Widget _buildEventCard(Event event) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: CustomExpansionTile(
      title: ListTile(
        title: Text(
          event.name + " - " + event.date.month.toString() + "/" + event.date.day.toString() + "/" + event.date.year.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        subtitle: Text(
          event.description + " - " + event.type,
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[600],
          ),
        ),
      ),
      children: event.timeSlots.map((timeSlot) {
        final isSignedUp = timeSlot.attendees.any((attendee) => attendee.name == supabase.auth.currentUser?.id);
        final isEventInFuture = event.date.isAfter(DateTime.now().add(Duration(days: 1)));
        return ListTile(
          title: Text(
            'Time: ${timeSlot.time.format(context)} - ${timeSlot.endTime.format(context)}',
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
          subtitle: Text(
            'Number of People: ${timeSlot.numberOfPeople}',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
            ),
          ),
          trailing: isSignedUp
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () {
                        _addEventToCalendar(event, timeSlot);
                      },
                    ),
                    if (isEventInFuture)
                      IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () {
                          _removeAttendee(event, timeSlot);
                        },
                      ),
                  ],
                )
              : ElevatedButton(
                  child: Text('  Sign Up  '),
                  onPressed: () {
                    _showSignUpForm(event, timeSlot);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
        );
      }).toList(),
    ),
  );
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      elevation: 20,
      shadowColor: Theme.of(context).colorScheme.shadow,
      title: Text(
        'Home',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24.0,
          color: Theme.of(context).colorScheme.onPrimary
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(13),
        ),
      ),
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          _buildDoubleProgressBar(context, 'Service Hours', _serviceHoursCompleted, _servicePotentialHours, 14),
          _buildDoubleProgressBar(context, 'Tutoring Hours', _tutoringHoursCompleted, _tutoringPotentialHours, 6),
          _buildDoubleProgressBar(context, 'Meeting Hours', _meetingHoursCompleted, _meetingPotentialHours, 5),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              return _buildEventCard(event);
            },
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the website when the button is pressed
          _openWebsite();
        },
        child:const Icon(Icons.school),
      ),
      
  );
}

  void _showSignUpForm(Event event, TimeSlot timeSlot) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Sign Up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Event: ${event.name}'),
            SizedBox(height: 8),
            Text('Time: ${timeSlot.time.format(context)}'),
            SizedBox(height: 8),
            Text('Number of People: ${timeSlot.numberOfPeople}'),
          ],
        ),
        actions: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(width: 3),
                ElevatedButton(
                  child: Text('Sign Up'),
                  onPressed: () {
                    _signUpForTimeSlot(event, timeSlot);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text('Add to Calendar'),
              onPressed: () {
                _addEventToCalendar(event, timeSlot);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
  void _removeAttendee(Event event, TimeSlot timeSlot) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      await Supabase.instance.client.from('Events').update({
        'timeSlots': event.timeSlots.map((slot) {
          if (slot == timeSlot) {
            return {
              'time': '${slot.time.hour}:${slot.time.minute}',
              'endTime': '${slot.endTime.hour}:${slot.endTime.minute}',
              'numberOfPeople': slot.numberOfPeople + 1,
              'attendees': slot.attendees
                  .where((attendee) => attendee.name != userId)
                  .map((attendee) => {
                        'name': attendee.userId,
                        'isPresent': attendee.isPresent,
                      })
                  .toList(),
            };
          } else {
            return {
              'time': '${slot.time.hour}:${slot.time.minute}',
              'endTime': '${slot.endTime.hour}:${slot.endTime.minute}',
              'numberOfPeople': slot.numberOfPeople,
              'attendees': slot.attendees.map((attendee) => {
                    'name': attendee.userId,
                    'isPresent': attendee.isPresent,
                  }).toList(),
            };
          }
        }).toList(),
      }).eq('name', event.name);

      _fetchEvents();
    }
  }
  void _signUpForTimeSlot(Event event, TimeSlot timeSlot) async {
  // Get the current user's UUID
  final User? user = supabase.auth.currentUser;
  final userId = user?.id;
  final userName = await _getUserName(userId);

  // Update the event in the Supabase database
  await Supabase.instance.client.from('Events').update({
    'timeSlots': event.timeSlots.map((slot) {
      if (slot == timeSlot && (slot.numberOfPeople > 0)) {
        final updatedAttendees = slot.attendees.where((attendee) => attendee.name != userId).toList();
        final updatedNumberOfPeople = slot.numberOfPeople - 1;

        if (slot.numberOfPeople > 0) {
          // Update the time slot with the user signed up
          return {
            'time': '${slot.time.hour}:${slot.time.minute}',
            "endTime": '${slot.endTime.hour}:${slot.endTime.minute}',
            'numberOfPeople': updatedNumberOfPeople,
            'attendees': [
              ...updatedAttendees.map((attendee) => {
                    'name': attendee.userId,
                    'isPresent': attendee.isPresent,
                  }).toList(),
              {'name': userId, 'isPresent': false},
            ],
          };
        }
      } else {
        // Keep the other time slots unchanged
        return {
          'time': '${slot.time.hour}:${slot.time.minute}',
          "endTime": '${slot.endTime.hour}:${slot.endTime.minute}',
          'numberOfPeople': slot.numberOfPeople,
          'attendees': slot.attendees.map((attendee) => {
                'name': attendee.userId,
                'isPresent': attendee.isPresent,
              }).toList(),
        };
      }
    }).toList(),
  }).eq('name', event.name);

  _fetchEvents();
  // Refresh the events list after signing up
}
  void _addEventToCalendar(Event event, TimeSlot timeSlot) {
  final calendarEvent = addEvent(
    title: event.name,
    description: event.description,
    startDate: DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      timeSlot.time.hour,
      timeSlot.time.minute,
    ),
    endDate: DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      timeSlot.endTime.hour,
      timeSlot.endTime.minute,
    ),
    iosParams: IOSParams(
      reminder: Duration(minutes: 10),
    ),
    androidParams: AndroidParams(
      emailInvites: [],
    ),
  );

  Add2Calendar.addEvent2Cal(calendarEvent);
}
  void _openWebsite() async {
      final Uri url = Uri.parse('https://docs.google.com/forms/d/1ZcXKKctcGjxJYi5KXuqmZ8u1BQP-825KSFJmP-rcKtA/viewform?edit_requested=true');
    if (!await launchUrl(url)) {
          throw Exception('Could not launch url');
      }
    }

}

Future<String> _getUserName(String? userId) async {
  if (userId != null) {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('user_id', userId)
        .single();

    if (response != null) {
      return response['name'] ?? 'Unknown User';
    }
  }
  return 'Unknown User';
}

Widget _buildProgressBar(context, String title, double completedHours, int hoursNeeded,) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ${completedHours.toStringAsFixed(2)} hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: completedHours / hoursNeeded,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            minHeight: 10,
            borderRadius: BorderRadius.all(Radius.circular(33)),
          ),
        ],
      ),
    );
  }

class CompletedHoursPage extends StatefulWidget {
  @override
  _CompletedHoursPageState createState() => _CompletedHoursPageState();
}

class _CompletedHoursPageState extends State<CompletedHoursPage> {
  double _serviceHoursCompleted = 0;
  double _tutoringHoursCompleted = 0;
  double _meetingHoursCompleted = 0;
  List<CompletedHour> _completedServiceHours = [];
  List<CompletedHour> _completedTutoringHours = [];
  List<CompletedHour> _completedMeetingHours = [];

  @override
  void initState() {
    super.initState();
    _fetchCompletedHours();
  }

  Future<void> _fetchCompletedHours() async {
  final User? user = supabase.auth.currentUser;
  final userId = user?.id;

  final response = await Supabase.instance.client
      .from('Service hours')
      .select('hours, type, event_name, date')
      .eq('user_id', userId as String);

  if (response != null) {
    final data = response;
    double serviceHours = 0;
    double tutoringHours = 0;
    double meetingHours = 0;
    List<CompletedHour> serviceHoursList = [];
    List<CompletedHour> tutoringHoursList = [];
    List<CompletedHour> meetingHoursList = [];

    for (final entry in data) {
      final hours = entry['hours'] + 0.0 ?? 0.0 ;
      final eventType = entry['type'] as String?;
      final eventName = entry['event_name'] as String?;
      final dateString = entry['date'] as String?;
      final date = DateTime(0);

      if (dateString != null) {
        final date = DateTime.parse(dateString);
      }

      
      if (eventType == 'Service' || eventType == 'Service') {
        serviceHours += hours;
        serviceHoursList.add(CompletedHour(
          title: eventName ?? 'Unknown Event',
          date: date,
          hours: hours,
        ));
      } else if (eventType == 'Tutoring' || eventType == 'tutoring') {
        tutoringHours += hours;
        tutoringHoursList.add(CompletedHour(
          title: eventName ?? 'Unknown Event',
          date: date,
          hours: hours,
        ));
      } else if (eventType == 'Meeting' || eventType == 'meeting') {
        meetingHours += hours;
        meetingHoursList.add(CompletedHour(
          title: eventName ?? 'Unknown Event',
          date: date,
          hours: hours,
        ));
      }
    }

    setState(() {
      _serviceHoursCompleted = serviceHours;
      _tutoringHoursCompleted = tutoringHours;
      _meetingHoursCompleted = meetingHours;
      _completedServiceHours = serviceHoursList;
      _completedTutoringHours = tutoringHoursList;
      _completedMeetingHours = meetingHoursList;
    });
  } else {
    // Handle the error case
    print('Error fetching completed hours: ${response}');
  }
}
      
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: Text(
          'Completed Hours',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProgressBar(context, 'Service Hours', _serviceHoursCompleted, 14),
            _buildCompletedHoursList(_completedServiceHours),
            SizedBox(height: 20),
            _buildProgressBar(context, 'Tutoring Hours', _tutoringHoursCompleted, 6),
            _buildCompletedHoursList( _completedTutoringHours),
            SizedBox(height: 20),
            _buildProgressBar(context, 'Meeting Hours', _meetingHoursCompleted, 5),
            _buildCompletedHoursList( _completedMeetingHours),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the website when the button is pressed
          _openWebsite();
        },
        child: Icon(Icons.report_problem),
      ),
    );
  }

  

  Widget _buildCompletedHoursList( List<CompletedHour> hours) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: hours.length,
          itemBuilder: (context, index) {
            final hour = hours[index];
            if (hour.date.year == 0){
              return Card(
              child: ListTile(
              title: Text(hour.title),
              subtitle:
              Text('${hour.hours.round()} hours'),
            )
              );
            }else {
              return Card(
              child: ListTile(
              title: Text(hour.title),
              subtitle:
              Text('${hour.date.month}-${hour.date.day}-${hour.date.year} - ${hour.hours.round()} hours'),
              )
              );
            }
          },
        ),
      ],
    )
    );
  }

  void _openWebsite() async {
    final Uri url = Uri.parse('https://docs.google.com/forms/d/e/1FAIpQLSeXg0ctE8Lg3r4aLhUSZYWj8GlvxwxM4aTRhf3axEQRljeRtw/viewform');
   if (!await launchUrl(url)) {
        throw Exception('Could not launch url');
    }
  }
}


class CompletedHour {
  final String title;
  final DateTime date;
  final double hours;

  CompletedHour({
    required this.title,
    required this.date,
    required this.hours,
  });
}

class ThemeNotifier with ChangeNotifier {
  Color _themeColor = Colors.blue;


  Color get themeColor => _themeColor;

  void updateThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    loadThemePreference();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    saveThemePreference();
    notifyListeners();
  }

  Future<void> loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _graduationYear;
  late String _password;
  Color _selectedColor = Colors.blue; 

  @override
  void initState() {
    super.initState();
    _name = '';
    _email = '';
    _graduationYear = '';
    _password = '';
    _fetchUserProfile();
    _fetchThemeColorFromPrefs();
  }

  Future<void> _fetchThemeColorFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('themeColor');
  setState(() {
    _selectedColor = colorValue != null ? Color(colorValue) : Colors.blue;
  });
}


  Future<void> _fetchUserProfile() async {
    final User? user = supabase.auth.currentUser;
    final userId = user?.id;

    if (userId != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      if (response != null) {
        if (this.mounted) {
        setState(() {
          _name = response['name'] ?? '';
          _email = response['email'] ?? '';
          _graduationYear = response['graduation_year']?.toString() ?? '';
        });
      }
      }
    }
  }

  Future<void> _updateUserProfile() async {
  final User? user = supabase.auth.currentUser;
  final userId = user?.id;

  if (userId != null) {
    await Supabase.instance.client
        .from('profiles')
        .update({
          'name': _name,
          'email': _email,
          'graduation_year': int.tryParse(_graduationYear) ?? 0,
        })
        .eq('user_id', userId);
  }
  }

  void _handleColorChange(Color color) {
  setState(() {
    _selectedColor = color;
  });
  _saveThemeColorToPrefs(color);
  Provider.of<ThemeNotifier>(context, listen: false).updateThemeColor(color);
}

Future<void> _saveThemeColorToPrefs(Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeColor', color.value);
}
  
  
 Future<void> _updatePassword(String newPassword) async {
  final User? user = supabase.auth.currentUser;

  if (newPassword.length >= 6){
   try {final response = await supabase.auth.updateUser(UserAttributes(password: newPassword));}
   catch (e) {}
   
   
  }
  else {
  const snackBar = SnackBar(content: Text('Password must Be more than 6 Characters'),);
   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
 }

 Future<void> _updateEmail(String newEmail) async {
  final User? user = supabase.auth.currentUser;
  if (user?.email != newEmail){
   try {final response = await supabase.auth.updateUser(UserAttributes(email: newEmail));
   toastification.show(
	  context: context,
	  type: ToastificationType.success,
	  style: ToastificationStyle.simple,
	  title: const Text("Check your Email To Confirm Change"),
	  description: const Text(""),
	  alignment: Alignment.center,
	  autoCloseDuration: const Duration(seconds: 4),
	  borderRadius: BorderRadius.circular(12.0),
	  boxShadow: lowModeShadow,
	  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
   );
   
   }
   catch (e) {toastification.show(
	  context: context,
	  type: ToastificationType.error,
	  style: ToastificationStyle.simple,
	  title: const Text("Email overflow, Try again later"),
	  description: const Text(""),
	  alignment: Alignment.center,
	  autoCloseDuration: const Duration(seconds: 4),
	  borderRadius: BorderRadius.circular(12.0),
	  boxShadow: lowModeShadow,
	  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
	);
    }
  }
  else {}
   
 }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
            color: Theme.of(context).colorScheme.onPrimary
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Account Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Name: $_name'),
                      Text('Email: $_email'),
                      Text('Graduation Year: $_graduationYear'),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.logout),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _name = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    initialValue: _email,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _email = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[ FilteringTextInputFormatter.digitsOnly],
                    initialValue: _graduationYear,
                    decoration: InputDecoration(labelText: 'Graduation Year'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your graduation year';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _graduationYear = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onChanged: (value) {
                      setState(() {
                        _password = value;
                      });
                    },
                  ),
                  SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (_password.isNotEmpty) {
                          if(_password.length > 7){
                            try {final response = await supabase.auth.updateUser(UserAttributes(password: _password,));}
                          catch (e) {};
                          }
                          else {
                          toastification.show(
                                context: context,
                                type: ToastificationType.error,
                                style: ToastificationStyle.simple,
                                title: const Text("Password must be longer than 6 characters"),
                                description: const Text(""),
                                alignment: Alignment.center,
                                autoCloseDuration: const Duration(seconds: 4),
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: lowModeShadow,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                 foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              );
                       }
                        }
                        _updateEmail(_email);
                        _updateUserProfile();
                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          style: ToastificationStyle.simple,
                          title: const Text("Settings Successfully Updated"),
                          description: const Text(""),
                          alignment: Alignment.center,
                          autoCloseDuration: const Duration(seconds: 4),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: lowModeShadow,
                           backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                 foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        );
                      }
                    },
                    child: Text('Update'),
                  ),
                 SizedBox(height: 24.0),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Theme Color'),
            trailing: CircleAvatar(
              backgroundColor: _selectedColor,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Select Theme Color'),
                    content: SingleChildScrollView(
                      child: SlidePicker(
                        pickerColor: _selectedColor,
                        onColorChanged: _handleColorChange,
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
           SwitchListTile(
            title: Text('Dark Mode'),
            value: Provider.of<ThemeProvider>(context).isDarkMode,
            onChanged: (_) {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
    ),
          ],
        ),
      ),
  );
}

Future<void> _signOut() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('sessionData');
  await supabase.auth.signOut();
  Navigator.pushReplacementNamed(context, '/');
}

}
// admin_events_page.dart
class AdminEventsPage extends StatefulWidget {
  @override
  _AdminEventsPageState createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final _formKey = GlobalKey<FormState>();
  late String _eventName;
  late String _eventDescription;
  late DateTime _eventDate;
  List<TimeSlot> _timeSlots = [];

  List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final response = await Supabase.instance.client
        .from('Events')
        .select('*')
        .order('date');

    final List<dynamic> data = response;
    setState(() {
      _events = data.map((json) => Event.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: Text(
          'Events',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: 
      ListView.separated(
        scrollDirection: Axis.vertical,
        itemCount: _events.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = _events[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomExpansionTile(
              title: ListTile(
                title: Text(
                  event.name + " - " + event.date.month.toString() + "/" + event.date.day.toString() + "/" + event.date.year.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                subtitle: Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              
              
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _showEditEventDialog(event);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteEvent(event);
                    },
                  ),
                ],
              ),
              ),
              children: event.timeSlots.map((timeSlot) {
                return ListTile(
                                  title: Text(
                      'Time: ${timeSlot.time.format(context)} - ${timeSlot.endTime.format(context)}',
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Text(
                      'Number of People: ${timeSlot.numberOfPeople}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  String? _selectedEventType;


void _showAddEventDialog() async {
  _eventDate = DateTime.now();
  _timeSlots = [];
  _selectedEventType = null;
  final result = await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Add Event'),
            content: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the event name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _eventName = value!;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the event description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _eventDescription = value!;
                  },
                ),
                    SizedBox(height: 16.0),
                InkWell(
                  onTap: () => _selectDate(setState),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Event Date',
                    ),
                    child: Text(
                      '${_eventDate.year}/${_eventDate.month}/${_eventDate.day}',
                    ),
                  ),
                ),
                 DropdownButtonFormField<String>(
                    value: _selectedEventType,
                    onChanged: (value) {
                      setState(() {
                        _selectedEventType = value;
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    dropdownColor: Theme.of(context).colorScheme.primaryContainer,
                    items: [
                      DropdownMenuItem(
                        value: 'Service',
                        child: Text('Service'),
                      ),
                      DropdownMenuItem(
                        value: 'Tutoring',
                        child: Text('Tutoring'),
                      ),
                      DropdownMenuItem(
                        value: 'Meeting',
                        child: Text('Meeting'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Event Type',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an event type';
                      }
                      return null;
                    },
                  ),

                SizedBox(height: 16.0),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < _timeSlots.length; i++)
                                ListTile(
                                  title: Text('${_timeSlots[i].time.format(context)} - ${_timeSlots[i].endTime.format(context)}'),
                                  subtitle: Text('Number of people: ${_timeSlots[i].numberOfPeople}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _timeSlots.removeAt(i);
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        child: Text('Add Time Slot'),
                        onPressed: () {
                          _addTimeSlot(setState);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Add'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _addEvent();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

void _removeTimeSlot(int index) {
  setState(() {
    _timeSlots.removeAt(index);
  });
}

void _addTimeSlot(StateSetter setState) async {
  final TimeOfDay? selectedStartTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (selectedStartTime != null) {
    final TimeOfDay? selectedEndTime = await showTimePicker(
      context: context,
      initialTime: selectedStartTime,
    );
    if (selectedEndTime != null) {
      int? numberOfPeople;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Number of People'),
            content: TextFormField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                numberOfPeople = int.tryParse(value);
              },
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      if (numberOfPeople != null) {
        setState(() {
          _timeSlots.add(TimeSlot(
            time: selectedStartTime,
            endTime: selectedEndTime,
            numberOfPeople: numberOfPeople!,
          ));
        });
      }
    }
  }
}

  void _showEditEventDialog(Event event) async {
  _eventName = event.name;
  _eventDescription = event.description;
  _eventDate = event.date;
  _timeSlots = List<TimeSlot>.from(event.timeSlots);
  _selectedEventType = event.type;

  final result = await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Edit Event'),
            content: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    TextFormField(
                      initialValue: _eventName,
                      decoration: InputDecoration(
                        labelText: 'Event Name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the event name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventName = value!;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      initialValue: _eventDescription,
                      decoration: InputDecoration(
                        labelText: 'Event Description',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the event description';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventDescription = value!;
                      },
                    ),
                    SizedBox(height: 16.0),
                    InkWell(
                      onTap: () => _selectDate(setState),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Event Date',
                        ),
                        child: Text(
                          '${_eventDate.year}/${_eventDate.month}/${_eventDate.day}',
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _selectedEventType,
                      onChanged: (value) {
                        setState(() {
                          _selectedEventType = value;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'Service',
                          child: Text('Service'),
                        ),
                        DropdownMenuItem(
                          value: 'Tutoring',
                          child: Text('Tutoring'),
                        ),
                        DropdownMenuItem(
                          value: 'Meeting',
                          child: Text('Meeting'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Event Type',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an event type';
                        }
                        return null;
                      },
                    ),
                    Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < _timeSlots.length; i++)
                                ListTile(
                        title: Text('${_timeSlots[i].time.format(context)} - ${_timeSlots[i].endTime.format(context)}'),
                        subtitle: Text('Number of people: ${_timeSlots[i].numberOfPeople}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _timeSlots.removeAt(i);
                            });
                          },
                        ),
                      ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        child: Text('Add Time Slot'),
                        onPressed: () {
                          _addTimeSlot(setState);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Save'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _updateEvent(event);
                    Navigator.of(context).pop();
                  }
                },
              ),
              ],
          );
        },
      );
    },
  );
}

void _updateEvent(Event event) async {
  final updatedEvent = Event(
    name: _eventName,
    description: _eventDescription,
    date: _eventDate,
    type: _selectedEventType!, // Add the updated event type
    timeSlots: _timeSlots,
  );

  await Supabase.instance.client
      .from('Events')
      .update({
        'name': updatedEvent.name,
        'description': updatedEvent.description,
        'date': updatedEvent.date.toIso8601String(),
        'type': updatedEvent.type, // Update the event type in Supabase
        'timeSlots': updatedEvent.timeSlots.map((slot) => {
              'time': '${slot.time.hour}:${slot.time.minute}',
              'endTime': '${slot.endTime.hour}:${slot.endTime.minute}',
              'numberOfPeople': slot.numberOfPeople,
              'attendees': slot.attendees.map((attendee) => {
                    'name': attendee.name,
                    'isPresent': attendee.isPresent,
                  }).toList(),
            }).toList(),
      })
      .eq('name', event.name);

  setState(() {
    final index = _events.indexWhere((e) => e.name == event.name);
    if (index != -1) {
      _events[index] = updatedEvent;
    }
  });
}

void _addEvent() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    final newEvent = Event(
      name: _eventName,
      description: _eventDescription,
      date: _eventDate,
      type: _selectedEventType!, // Add the selected event type
      timeSlots: _timeSlots.map((slot) => TimeSlot(
        time: slot.time,
        endTime: slot.endTime,
        numberOfPeople: slot.numberOfPeople,
        attendees: [],
      )).toList(),
    );
    setState(() {
      _events.add(newEvent);
    });
    Navigator.of(context).pop();
    // Save to Supabase
    await Supabase.instance.client.from('Events').insert({
      'name': newEvent.name,
      'description': newEvent.description,
      'date': newEvent.date.toIso8601String(),
      'type': newEvent.type, // Add the event type to the Supabase insert
      'timeSlots': newEvent.timeSlots.map((slot) => {
        'time': '${slot.time.hour}:${slot.time.minute}',
        'endTime': '${slot.endTime.hour}:${slot.endTime.minute}',
        'numberOfPeople': slot.numberOfPeople,
        'attendees': slot.attendees.map((attendee) => {
          'name': attendee.name,
          'isPresent': attendee.isPresent,
        }).toList(),
      }).toList(),
      'attendees': "Null"
    });
  }
}

  void _deleteEvent(Event event) async {
    setState(() {
      _events.remove(event);
    });
    await Supabase.instance.client.from('Events').delete().eq('name', event.name);
    
  }

  Future<void> _selectDate(StateSetter setState) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _eventDate,
    firstDate: DateTime(2023),
    lastDate: DateTime(2100),
  );
  if (picked != null && picked != _eventDate) {
    setState(() {
      _eventDate = picked;
    });
  }
}

}

class TimeSlot {
  final TimeOfDay time;
  final TimeOfDay endTime;
  final int numberOfPeople;
  final List<Attendee> attendees;

  TimeSlot({
    required this.time,
    required this.endTime,
    required this.numberOfPeople,
    this.attendees = const [],
  });
}

class Event {
  final String name;
  final String description;
  final DateTime date;
  final String type;
  final List<TimeSlot> timeSlots;

  Event({
    required this.name,
    required this.description,
    required this.date,
    required this.type,
    required this.timeSlots,
  });

   Event.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        description = json['description'] ?? '',
        date = json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        type = json['type'] ?? '',
        timeSlots = json['timeSlots'] != null
            ? (json['timeSlots'] as List<dynamic>)
                .map((slot) => TimeSlot(
                      time: TimeOfDay(
                        hour: int.parse(slot['time'].split(':')[0]),
                        minute: int.parse(slot['time'].split(':')[1]),
                      ),
                      endTime: slot['endTime'] != null
                          ? TimeOfDay(
                              hour: int.parse(slot['endTime'].split(':')[0]),
                              minute: int.parse(slot['endTime'].split(':')[1]),
                            )
                          : TimeOfDay.now(),
                      numberOfPeople: slot['numberOfPeople'] ?? 0,
                      attendees: slot['attendees'] != null
                          ? (slot['attendees'] as List<dynamic>)
                              .map((attendee) => Attendee(
                                    name: attendee['name'] ?? '',
                                    isPresent: attendee['isPresent'] ?? false,
                                    userId: attendee['name'] ?? '',
                                  ))
                              .toList()
                          : [],
                    ))
                .toList()
            : [];
}

class CustomExpansionTile extends ExpansionTile {
  CustomExpansionTile({
    Key? key,
    required Widget title,
    required List<Widget> children,
    bool initiallyExpanded = false,
    EdgeInsetsGeometry? tilePadding,
  }) : super(
          key: key,
          title: title,
          children: children,
          initiallyExpanded: initiallyExpanded,
          tilePadding: tilePadding,
        );

  @override
  Widget _buildChildren(BuildContext context, Widget? child, AnimationController? controller, bool expanded) {
    return Container(
      child: Column(
        children: children,
      ),
    );
  }
}

// admin_attendance_page.dart
class AdminAttendancePage extends StatefulWidget {
  @override
  _AdminAttendancePageState createState() => _AdminAttendancePageState();
}

class _AdminAttendancePageState extends State<AdminAttendancePage> {
  List<Event> _events = [];
  List<UserProfile> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchAllUsers();
  }

  Future<void> _fetchEvents() async {
    final response = await Supabase.instance.client
        .from('Events')
        .select('*')
        .order('date');

    final List<dynamic> data = response;
    setState(() {
      _events = data.map((json) => Event.fromJson(json)).toList();
    });
  }

  Future<void> _fetchAllUsers() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('*');

    final List<dynamic> data = response;
    setState(() {
      _allUsers = data.map((json) => UserProfile(
        name: json['name'] ?? 'Unknown',
        id: json['user_id'],
        completedHours: [],
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: Text(
          'Attendance',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: _events.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = _events[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomExpansionTile(
              title: ListTile(
                title: Text(
                  event.name + " - " + event.date.month.toString() + "/" + event.date.day.toString() + "/" + event.date.year.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                subtitle: Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              children: event.timeSlots.map((timeSlot) {
                return ListTile(
                  title: Text(
                    'Time: ${timeSlot.time.format(context)} - ${timeSlot.endTime.format(context)}',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  subtitle: Text(
                    'Number of People: ${timeSlot.numberOfPeople}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.checklist_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      _showAttendanceDialog(event, timeSlot);
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showAttendanceDialog(Event event, TimeSlot timeSlot) async {
    final updatedAttendees = await Future.wait(
      timeSlot.attendees.map((attendee) async {
        final userId = attendee.name;
        final userName = await _getUserName(userId);
        return Attendee(
          name: userName,
          isPresent: attendee.isPresent,
          userId: userId,
        );
      }),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Attendance for ${event.name}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time: ${timeSlot.time.format(context)}',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Attendees:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    height: 200.0,
                    child: SingleChildScrollView(
                      child: Column(
                        children: updatedAttendees.map((attendee) {
                          return ListTile(
                            title: Text(
                              attendee.name,
                              style: TextStyle(
                                fontSize: 16.0,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!attendee.isPresent)
                                  IconButton(
                                    icon: Icon(Icons.swap_horiz),
                                    onPressed: () {
                                      _showSwapDialog(attendee, updatedAttendees, setState);
                                    },
                                  ),
                                Checkbox(
                                  value: attendee.isPresent,
                                  onChanged: (value) {
                                    setState(() {
                                      attendee.isPresent = value!;
                                    });
                                  },
                                  activeColor: Colors.blue,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16.0,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  onPressed: () {
                    timeSlot.attendees.clear();
                    timeSlot.attendees.addAll(updatedAttendees.map((attendee) => Attendee(
                      name: attendee.userId,
                      isPresent: attendee.isPresent,
                      userId: attendee.userId,
                    )));
                    _saveAttendance(event, timeSlot);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSwapDialog(Attendee currentAttendee, List<Attendee> updatedAttendees, StateSetter parentSetState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<UserProfile> filteredUsers = List.from(_allUsers);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Swap Attendee'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filteredUsers = _allUsers
                            .where((user) => user.name.toLowerCase().contains(searchQuery.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 300,
                    width: 300,
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return ListTile(
                          title: Text(user.name),
                          onTap: () {
                            parentSetState(() {
                              int index = updatedAttendees.indexOf(currentAttendee);
                              updatedAttendees[index] = Attendee(
                                name: user.name,
                                isPresent: false,
                                userId: user.id,
                              );
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveAttendance(Event event, TimeSlot timeSlot) async {
    final attendees = timeSlot.attendees
        .map((attendee) => {
              'name': attendee.userId,
              'isPresent': attendee.isPresent,
            })
        .toList();

    final serviceHoursToAdd = <Map<String, dynamic>>[];
    final serviceHoursToRemove = <Map<String, dynamic>>[];

    for (final attendee in timeSlot.attendees) {
      final existingServiceHour = await Supabase.instance.client
          .from('Service hours')
          .select()
          .eq('event_name', event.name)
          .eq('timeslot', '${timeSlot.time.hour}:${timeSlot.time.minute}')
          .eq('user_id', attendee.userId);

      if (attendee.isPresent) {
        if (existingServiceHour.isEmpty) {
          final duration = _calculateDuration(timeSlot.time, timeSlot.endTime);
          serviceHoursToAdd.add({
            'event_name': event.name,
            'event_description': event.description,
            'date': event.date.toIso8601String(),
            'timeslot': '${timeSlot.time.hour}:${timeSlot.time.minute}',
            'user_id': attendee.userId,
            'hours': duration,
            'type': event.type,
          });
        }
      } else {
        if (existingServiceHour.isNotEmpty) {
          serviceHoursToRemove.add({
            'event_name': event.name,
            'timeslot': '${timeSlot.time.hour}:${timeSlot.time.minute}',
            'user_id': attendee.userId,
          });
        }
      }
    }

    if (serviceHoursToAdd.isNotEmpty) {
      await Supabase.instance.client.from('Service hours').insert(serviceHoursToAdd);
    }

    if (serviceHoursToRemove.isNotEmpty) {
      for (final serviceHour in serviceHoursToRemove) {
        await Supabase.instance.client
            .from('Service hours')
            .delete()
            .eq('event_name', serviceHour['event_name'])
            .eq('timeslot', serviceHour['timeslot'])
            .eq('user_id', serviceHour['user_id']);
      }
    }

    await Supabase.instance.client.from('Events').update({
      'timeSlots': event.timeSlots
          .map((slot) => {
                'time': '${slot.time.hour}:${slot.time.minute}',
                'endTime': '${slot.endTime.hour}:${slot.endTime.minute}',
                'numberOfPeople': slot.numberOfPeople,
                'attendees': slot == timeSlot
                    ? attendees
                    : slot.attendees
                        .map((attendee) => {
                              'name': attendee.userId,
                              'isPresent': attendee.isPresent,
                            })
                        .toList(),
              })
          .toList(),
    }).eq('name', event.name);

    setState(() {
      final eventIndex = _events.indexWhere((e) => e.name == event.name);
      final timeSlotIndex = _events[eventIndex].timeSlots.indexOf(timeSlot);
      
      final updatedTimeSlot = TimeSlot(
        time: timeSlot.time,
        endTime: timeSlot.endTime,
        numberOfPeople: timeSlot.numberOfPeople,
        attendees: timeSlot.attendees,
      );
      
      _events[eventIndex].timeSlots[timeSlotIndex] = updatedTimeSlot;
    });
  }

  double _calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final duration = (endMinutes - startMinutes) / 60;
    return duration;
  }
}

class AdminListPage extends StatefulWidget {
  @override
  _AdminListPageState createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  List<UserProfile> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
     setState(() {
        _users.clear();
      });

    final profileResponse = await Supabase.instance.client.from('profiles').select('*');
    final List<dynamic> profileData = profileResponse;

    for (final profileJson in profileData) {
      final userId = profileJson['user_id'] as String;
      final userName = profileJson['name'] as String;

      final hoursResponse = await Supabase.instance.client
          .from('Service hours')
          .select('event_name, hours, type')
          .eq('user_id', userId);

      final List<dynamic> hoursData = hoursResponse;
      final List<CompletedUserHour> completedHours = hoursData
          .map((hourJson) => CompletedUserHour.fromJson(hourJson))
          .toList();

      final user = UserProfile(
        name: userName,
        completedHours: completedHours,
        id: userId,
      );

      if (this.mounted) {
      setState(() {
        _users.add(user);
      });
    }
    }
  }

  List<UserProfile> _getFilteredUsers() {
  if (_searchQuery.isEmpty) {
    return _users;
  }

  final lowercaseQuery = _searchQuery.toLowerCase();
  return _users.where((user) {
    final lowercaseName = user.name.toLowerCase();
    return lowercaseName.contains(lowercaseQuery);
  }).toList();
}



 void _openCustomEventForm(BuildContext context, String userId,
      {String eventName = '',
      TimeOfDay? selectedTime,
      double hours = 0,
      String type = 'Service'}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Add Custom Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: eventName,
              decoration: InputDecoration(labelText: 'Event Name'),
              onChanged: (value) {
                eventName = value;
              },
            ),
            Padding(padding: EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              child: Text(selectedTime != null
                  ? '${selectedTime.format(context)}'
                  : 'Select Time'),
              onPressed: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  // Rebuild the dialog with the selected time and preserved form data
                  Navigator.of(context).pop();
                  _openCustomEventForm(context, userId,
                      eventName: eventName,
                      selectedTime: pickedTime,
                      hours: hours,
                      type: type);
                }
              },
            )
            ),
            TextFormField(
              initialValue: hours.toString(),
              decoration: InputDecoration(labelText: 'Hours'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                hours = double.tryParse(value) ?? 0.0;
              },
            ),
            DropdownButtonFormField<String>(
                      value: type,
                      onChanged: (value) {
                        type = value ?? "Service";
                      },
                    borderRadius: BorderRadius.circular(30),
                    dropdownColor: Theme.of(context).colorScheme.primaryContainer,
                    items: [
                      DropdownMenuItem(
                        value: 'Service',
                        child: Text('Service'),
                      ),
                      DropdownMenuItem(
                        value: 'Tutoring',
                        child: Text('Tutoring'),
                      ),
                      DropdownMenuItem(
                        value: 'Meeting',
                        child: Text('Meeting'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Event Type',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an event type';
                      }
                      return null;
                    },
                  ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Save'),
            onPressed: () {
              if (selectedTime != null) {
                String timeSlot = '${selectedTime.hour}:${selectedTime.minute}';
                _saveCustomEvent(userId, eventName, timeSlot, hours.toDouble(), type); // Pass userId directly
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}

Future<void> _saveCustomEvent(
  String userId,
  String eventName,
  String timeSlot,
  double hours,
  String type,
) async {
  await Supabase.instance.client.from('Service hours').insert({
    'user_id': userId,
    'event_name': eventName,
    'timeslot': timeSlot,
    'hours': hours.toDouble(),
    'type': type,
  });

  _fetchUsers(); // Refresh the user list after saving the custom event
}

Future<void> _deleteServiceHour(CompletedUserHour hour, String userId) async {
  await Supabase.instance.client
      .from('Service hours')
      .delete()
      .eq('event_name', hour.eventName)
      .eq('user_id', userId);

      _fetchUsers();
}


  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: Text(
          'List',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
      children: [
        Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                ElevatedButton.icon(
                  onPressed: () {
                    _openBulkCustomEventForm(context);
                  },
                  icon: Icon(Icons.add),
                  label: Text('Bulk'),
                ),
              ],
            ),
          ),
        Expanded(
            child: ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => SizedBox(height: 16),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomExpansionTile(
              title: ListTile(
                title: Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                 user.hasCompletedHours()
                    ? Icon(Icons.check, color: Colors.green)
                    : Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                   IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      _openCustomEventForm(context, user.id);
                    },
                   ),
                ],
              ),
              ),
              children: user.completedHours.map((hour) {
                  return ListTile(
                    title: Text(
                      hour.eventName,
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    subtitle: Text(
                      '${hour.hours} hours - ${hour.type}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        _deleteServiceHour(hour, user.id);
                      },
                    ),
                  );
                }).toList(),
              
            ),
          );
            },
          ),
        ),
      ],
    ),
  );
}

void _openBulkCustomEventForm(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkCustomEventFormPage(users: _users),
      ),
    );

    if (result == true) {
      // Refresh the user list if the bulk custom event was saved successfully
      _fetchUsers();
    }
  }
}




class BulkCustomEventFormPage extends StatefulWidget {
  final List<UserProfile> users;

  BulkCustomEventFormPage({required this.users});

  @override
  _BulkCustomEventFormPageState createState() => _BulkCustomEventFormPageState();
}

class _BulkCustomEventFormPageState extends State<BulkCustomEventFormPage> {
  String eventName = '';
  TimeOfDay? selectedTime;
  double hours = 0;
  String type = 'Service';
  List<String> selectedUserIds = [];
  String searchQuery = '';

  List<UserProfile> get filteredUsers {
    return widget.users.where((user) {
      final lowercaseName = user.name.toLowerCase();
      final lowercaseQuery = searchQuery.toLowerCase();
      return lowercaseName.contains(lowercaseQuery);
    }).toList();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Bulk Custom Event'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        eventName = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          onChanged: (value) {
                            setState(() {
                              type = value ?? "Service";
                            });
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'Service',
                              child: Text('Service'),
                            ),
                            DropdownMenuItem(
                              value: 'Tutoring',
                              child: Text('Tutoring'),
                            ),
                            DropdownMenuItem(
                              value: 'Meeting',
                              child: Text('Meeting'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Event Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: ElevatedButton(
                          child: Text(selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Select Time'),
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: TextFormField(
                          initialValue: hours.toString(),
                          decoration: InputDecoration(
                            labelText: 'Hours',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              hours = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Members',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isSelected = selectedUserIds.contains(user.id);

                  bool isFirstItem = index == 0;
                  bool isLastItem = index == filteredUsers.length - 1;
                  bool isPrevSelected = isFirstItem ? false : selectedUserIds.contains(filteredUsers[index - 1].id);
                  bool isNextSelected = isLastItem ? false : selectedUserIds.contains(filteredUsers[index + 1].id);

                  BorderRadius borderRadius = BorderRadius.zero;
                  if(!isSelected){

                  }
                  else if (isSelected && isNextSelected) {
                    if (isPrevSelected) {
                      borderRadius = BorderRadius.all((Radius.circular(6)));
                    } else {
                      borderRadius = BorderRadius.vertical(top: Radius.circular(15), bottom: Radius.circular(6));
                    }
                  } else if (isSelected && isPrevSelected) {
                    borderRadius = BorderRadius.vertical(bottom: Radius.circular(15), top: Radius.circular(6));
                  }
                  else{
                    borderRadius = BorderRadius.all(Radius.circular(15));
                  }

                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.secondaryContainer : null,
                          borderRadius: borderRadius,
                        ),
                        child: CheckboxListTile(
                          title: Text(user.name),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value!) {
                                selectedUserIds.add(user.id);
                              } else {
                                selectedUserIds.remove(user.id);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.0),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
       floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: () {
              Navigator.of(context).pop();
            },
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.surfaceContainerHighest),
          ),
          SizedBox(width: 16.0),
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: () {
              if (selectedTime != null) {
                String timeSlot = '${selectedTime!.hour}:${selectedTime!.minute}';
                _saveBulkCustomEvent(
                  selectedUserIds,
                  eventName,
                  timeSlot,
                  hours,
                  type,
                );
              }
            },
            child: Icon(Icons.save, color: Theme.of(context).colorScheme.onSurfaceVariant,),
          ),
        ],
      ),
    );
    
  }
  
  Future<void> _saveBulkCustomEvent(
    List<String> userIds,
    String eventName,
    String timeSlot,
    double hours,
    String type,
  ) async {
    try {
      final List<Map<String, dynamic>> bulkEvents = userIds.map((userId) {
        return {
          'user_id': userId,
          'event_name': eventName,
          'timeslot': timeSlot,
          'hours': hours.toDouble(),
          'type': type,
        };
      }).toList();

      await Supabase.instance.client.from('Service hours').insert(bulkEvents);

      // Show a success message using toastification
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.simple,
        title: const Text("Bulk custom event saved successfully"),
        description: const Text(""),
        alignment: Alignment.center,
        autoCloseDuration: const Duration(seconds: 3),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: lowModeShadow,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      );

      // Return true to indicate successful saving
      Navigator.of(context).pop(true);
    } catch (error) {
      // Show an error message using toastification
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.simple,
        title: const Text("Failed to save bulk custom event"),
        description: const Text(""),
        alignment: Alignment.center,
        autoCloseDuration: const Duration(seconds: 3),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: lowModeShadow,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      );
    }
  }
}

// ... existing code ...
class AdminTotalHoursPage extends StatefulWidget {
  @override
  _AdminTotalHoursPageState createState() => _AdminTotalHoursPageState();
}
class _AdminTotalHoursPageState extends State<AdminTotalHoursPage> {
  double _totalHours = 0;
  double _totalServiceHours = 0;
  double _totalTutoringHours = 0;
  double _totalMeetingHours = 0;

  @override
  void initState() {
    super.initState();
    _fetchTotalHours();
  }

  Future<void> _fetchTotalHours() async {
    final response = await Supabase.instance.client
        .from('Service hours')
        .select('hours, type');

    if (response != null) {
      final data = response as List<dynamic>;
      double serviceHours = 0;
      double tutoringHours = 0;
      double meetingHours = 0;

      print(response);
      for (final entry in data) {
        final hours = entry['hours'];
        final eventType = entry['type'] as String?;

        if (eventType == 'Service') {
          serviceHours += hours;
        } else if (eventType == 'Tutoring') {
          tutoringHours += hours;
        } else if (eventType == 'Meeting') {
          meetingHours += hours;
        }
      }

      setState(() {
        _totalServiceHours = serviceHours;
        _totalTutoringHours = tutoringHours;
        _totalMeetingHours = meetingHours;
        _totalHours = serviceHours + tutoringHours + meetingHours;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        shadowColor: Theme.of(context).colorScheme.shadow,
        title: Text(
          'Total NHS Hours',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _totalHours / 100,
                    strokeWidth: 16,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  Center(
                    child: Text(
                      '${_totalHours.toStringAsFixed(2)}\nHours',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHoursCard('Service', _totalServiceHours, Theme.of(context).colorScheme.primary),
                _buildHoursCard('Tutoring', _totalTutoringHours, Theme.of(context).colorScheme.secondary),
                _buildHoursCard('Meeting', _totalMeetingHours, Theme.of(context).colorScheme.tertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursCard(String title, double hours, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${hours.toStringAsFixed(2)} hours',
              style: TextStyle(
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class UserProfile {
  final String name;
  final String id;
  final List<CompletedUserHour> completedHours;

  UserProfile({
    required this.name,
    required this.completedHours,
    required this.id,
  });

  bool hasCompletedHours() {
    int serviceHours = 0;
    int tutoringHours = 0;
    int meetingHours = 0;

    for (final hour in completedHours) {
      if (hour.type == 'Service') {
        serviceHours += hour.hours.round();
      } else if (hour.type == 'Tutoring') {
        tutoringHours += hour.hours.round();
      } else if (hour.type == 'Meeting') {
        meetingHours += hour.hours.round();
      }
    }

    return serviceHours >= 14 && tutoringHours >= 6 && meetingHours >= 5;
  }
}

class CompletedUserHour {
  final String eventName;
  final double hours;
  final String type;

  CompletedUserHour({
    required this.eventName,
    required this.hours,
    required this.type,
  });

  factory CompletedUserHour.fromJson(Map<String, dynamic> json) {
    final dynamic hoursValue = json['hours'];
    final double hours;
    if (hoursValue is int) {
      hours = hoursValue.toDouble();
    } else if (hoursValue is double) {
      hours = hoursValue;
    } else {
      throw FormatException('Invalid hours value: $hoursValue');
    }

    return CompletedUserHour(
      eventName: json['event_name'] ?? '',
      hours: hours,
      type: json['type'] ?? '',
    );
  }
}

class Attendee {
  final String name;
  bool isPresent;
  final String userId;

  Attendee({
    required this.name,
    required this.isPresent,
    required this.userId,
  });
}