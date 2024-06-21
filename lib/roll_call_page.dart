import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

class RollCallPage extends StatefulWidget {
  @override
  _RollCallPageState createState() => _RollCallPageState();
}

class _RollCallPageState extends State<RollCallPage> {
  List<Country> _countries = [
    Country('Country 1', 'Present'),
    Country('Country 2', 'Present and Voting'),
    Country('Country 3', 'Absent'),
    // Add more countries as needed
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: (_) => _buildBody(),
      smallBody: (_) => _buildSmallBody(),
      secondaryBody: (_) => _buildSecondaryBody(),
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.list),
          label: 'Voting List',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(child: _buildCountriesList()),
        _buildAddCountry(),
      ],
    );
  }

  Widget _buildSmallBody() {
    return Column(
      children: [
        Expanded(child: _buildCountriesList()),
        _buildAddCountry(),
      ],
    );
  }

  Widget _buildSecondaryBody() {
    return Container(
      color: Colors.blue.shade100,
      child: Center(
        child: Text(
          'Secondary Body',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }

  Widget _buildCountriesList() {
    return ListView.builder(
      itemCount: _countries.length,
      itemBuilder: (context, index) {
        final country = _countries[index];
        return ListTile(
          title: Text(country.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _updateAttendanceStatus(index, 'Present');
                },
                child: Text('Present'),
              ),
              SizedBox(width: 8.0),
              ElevatedButton(
                onPressed: () {
                  _updateAttendanceStatus(index, 'Present and Voting');
                },
                child: Text('Present and Voting'),
              ),
              SizedBox(width: 8.0),
              ElevatedButton(
                onPressed: () {
                  _updateAttendanceStatus(index, 'Absent');
                },
                child: Text('Absent'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddCountry() {
  String newCountry = '';

  return Container(
    padding: EdgeInsets.all(16.0),
    child: TextField(
      onChanged: (value) {
        newCountry = value;
      },
      decoration: InputDecoration(
        labelText: 'Add Country',
        suffixIcon: IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            if (newCountry.isNotEmpty) {
              setState(() {
                _countries.add(Country(newCountry, 'Present'));
                newCountry = '';
              });
            }
          },
        ),
      ),
    ),
  );
}

  void _updateAttendanceStatus(int index, String status) {
    setState(() {
      _countries[index].attendanceStatus = status;
    });
  }
}

class Country {
  final String name;
  String attendanceStatus;

  Country(this.name, this.attendanceStatus);
}