import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_flags/country_flags.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'main_page.dart';
import 'constant.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _selectedCard = '';
  Conference? _selectedConference;
  
  CountryList _selectedCountryList = CountryList(id: 1, name: "", userId: "", forAll: false);
  List<Country> _selectedCountries = [];
  String countrySearchQuery = '';
  

  List<Widget Function(BuildContext)> _buildScreens() {
    return [
      (_) => _buildHomeScreen(),
      (_) => _buildSettingsScreen(),
    ];
  }

  Widget _buildHomeScreen() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth <= 600) {
          return _buildSmallBody();
        } else {
          return _buildBody();
        }
      },
    );
  }

  Widget _buildSettingsScreen() {
    return Container(
      color: Colors.blue.shade100,
      child: Center(
        child: Text(
          'Settings Screen',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      smallBreakpoint: const WidthPlatformBreakpoint(end: 700),
      mediumBreakpoint: const WidthPlatformBreakpoint(begin: 700, end: 1000),
      largeBreakpoint: const WidthPlatformBreakpoint(begin: 1000),
      onSelectedIndexChange: (int index) {
        setState(() {
          _selectedIndex = index;
          _selectedCard = '';
        });
      },
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      body: (context) => _buildScreens()[_selectedIndex](context),
      secondaryBody: (context) => _buildSecondaryBody(context),
    );
  }

  Widget _buildBody() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildConferenceCard(),
        _buildAccountCard(),
        _buildCreateConferenceCard(),
        _buildCreateCountryListCard(),
      ],
    );
  }

  Widget _buildSmallBody() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildConferenceCard(),
        const SizedBox(height: 16.0),
        _buildAccountCard(),
        const SizedBox(height: 16.0),
        _buildCreateConferenceCard(),
        const SizedBox(height: 16.0),
        _buildCreateCountryListCard(),
      ],
    );
  }

  Widget _buildSecondaryBody(BuildContext context) {
  switch (_selectedCard) {
    case 'conferences':
      return _buildConferencesContent();
    case 'account':
      return _buildAccountContent();
    case 'create_conference':
      return _buildCreateConferenceContent(context);
    case 'create_country_list':
      return _buildCreateCountryListContent();
    case 'country_list_details':
      return _buildCountryListDetailsContent();
    case 'committees_list':
      return _buildCommitteesListContent();
    default:
      return Container();
  }
}

  Widget _buildConferenceCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.event),
        title: Text('Saved Conferences'),
        onTap: () {
          setState(() {
            _selectedCard = 'conferences';
          });
        },
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.account_circle),
        title: Text('Manage Account'),
        onTap: () {
          setState(() {
            _selectedCard = 'account';
          });
        },
      ),
    );
  }

  Widget _buildCreateConferenceCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.add),
        title: Text('Create Conference'),
        onTap: () {
          setState(() {
            _selectedCard = 'create_conference';
          });
        },
      ),
    );
  }

  Widget _buildCreateCountryListCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.flag),
        title: Text('Create Country List'),
        onTap: () {
          setState(() {
            _selectedCard = 'create_country_list';
          });
        },
      ),
    );
  }

  Widget _buildConferencesContent() {
  return FutureBuilder<List<Conference>>(
    future: fetchConferences(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        List<Conference> conferences = snapshot.data!;
        return ListView.builder(
          itemCount: conferences.length,
          itemBuilder: (context, index) {
            Conference conference = conferences[index];
            return ListTile(
              title: Text(conference.name),
              subtitle: Text('Date: ${conference.date.toString()}'),
              onTap: () {
                // Update the selected conference and show the committees list
                setState(() {
                  _selectedConference = conference;
                  _selectedCard = 'committees_list';
                });
              },
            );
          },
        );
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else {
        return Center(child: CircularProgressIndicator());
      }
    },
  );
}


Widget _buildAccountContent() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text('Name: John Doe'),
        Text('Email: john.doe@example.com'),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Handle edit account button tap
            print('Edit Account');
          },
          child: Text('Edit Account'),
        ),
      ],
    ),
  );
}

Widget _buildCreateConferenceContent(BuildContext context) {
  TextEditingController nameController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Conference',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Conference Name',
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: dateController,
          decoration: InputDecoration(
            labelText: 'Conference Date',
          ),
          onTap: () async {
            // Show date picker
            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (selectedDate != null) {
              dateController.text = selectedDate.toString();
            }
          },
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            String name = nameController.text;
            String date = dateController.text;

            final response = await Supabase.instance.client
                .from('conferences')
                .insert({'name': name, 'date': date});

            if (response != null) {
              // Handle error
              print('Error creating conference: ${response}');
            } else {
              // Conference created successfully
              print('Conference created successfully');
              nameController.clear();
              dateController.clear();
            }
          },
          child: Text('Create'),
        ),
      ],
    ),
  );
}

Widget _buildCreateCountryListContent() {
  TextEditingController countryListNameController = TextEditingController();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Country Lists',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      TextField(
        controller: countryListNameController,
        decoration: InputDecoration(
          labelText: 'Country List Name',
        ),
      ),
      SizedBox(height: 16),
      ElevatedButton(
        onPressed: () async {
          String countryListName = countryListNameController.text;
          if (countryListName.isNotEmpty) {
            final userId = Supabase.instance.client.auth.currentUser?.id;
            final response = await Supabase.instance.client
                .from('countrylists')
                .insert({
              'name': countryListName,
              'user_id': userId,
              'for_all': false,
            });
          }
        },
        child: Text('Create Country List'),
      ),
      SizedBox(height: 16),
      Expanded(
        child: FutureBuilder<List<CountryList>>(
          future: fetchCountryLists(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<CountryList> countryLists = snapshot.data!;
              return ListView.builder(
                itemCount: countryLists.length,
                itemBuilder: (context, index) {
                  CountryList countryList = countryLists[index];
                  return ListTile(
                    title: Text(countryList.name),
                    trailing: countryList.forAll ? Text('For All') : null,
                    onTap: () {
                      setState(() {
                        _selectedCard = 'country_list_details';
                        _selectedCountryList = countryList;
                      
                      });
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    ],
  );
}

Widget _buildCommitteesListContent() {
  TextEditingController _newCommitteeController = TextEditingController();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _selectedCard = 'conferences';
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _newCommitteeController,
              decoration: InputDecoration(
                labelText: 'Create New Committee',
              ),
              onSubmitted: (value) async {
                // Handle creating a new committee
                String newCommitteeName = value.trim();
                if (newCommitteeName.isNotEmpty) {
                  final response = await Supabase.instance.client
                      .from('committees')
                      .insert({
                    'name': newCommitteeName,
                    'conference_id': _selectedConference!.id,
                  });
                  if (response != null) {
                    // Committee created successfully
                    _newCommitteeController.clear();
                    setState(() {});
                  } else {
                    // Handle error
                    print('Error creating committee');
                  }
                }
              },
            ),
          ),
        ],
      ),
      Expanded(
        child: FutureBuilder<List<Committee>>(
          future: fetchCommittees(_selectedConference!.id),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Committee> committees = snapshot.data!;
              return ListView.builder(
                itemCount: committees.length,
                itemBuilder: (context, index) {
                  Committee committee = committees[index];
                  return ListTile(
                    title: Text(committee.name),
                    onTap: () {
                      // Handle committee tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                            conference: _selectedConference!,
                            committee: committee,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    ],
  );
}

Future<List<Committee>> fetchCommittees(int conferenceId) async {
  final response = await Supabase.instance.client
      .from('committees')
      .select('*')
      .eq('conference_id', conferenceId)
      .order('name');

  return response.map((data) => Committee.fromJson(data)).toList();
}

Widget _buildCountryListDetailsContent() {
  TextEditingController searchController = TextEditingController();
  TextEditingController newCountryController = TextEditingController();
  
   if (_selectedCountries.isEmpty) {
    fetchCountriesForCountryList(_selectedCountryList.id).then((countries) {
      setState(() {
        _selectedCountries.addAll(countries);
      });
    });
  }
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _selectedCountryList!.name,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Countries',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(33.0),
              ),
              ),
              onChanged: (value) {
                setState(() {
                  countrySearchQuery = value;
                });
              },
            ),
          ),
          SizedBox(width: 16),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(33),
            ),
            child: Text(
              'Total:  ${_selectedCountries.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: newCountryController,
              decoration: InputDecoration(
                labelText: 'Add Country',
              ),
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              String newCountry = newCountryController.text;
              if (newCountry.isNotEmpty) {
                final response = await Supabase.instance.client
                    .from('countries')
                    .insert({'name': newCountry});
                // Country created successfully
                print('Country created successfully');
                newCountryController.clear();
                setState(() {});
              }
            },
            child:Icon(
              Icons.add,
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      SizedBox(height: 16),
    
       Expanded(
        child: FutureBuilder<List<Country>>(
          future: fetchCountries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              List<Country> allCountries = snapshot.data!;
              allCountries = allCountries.where((country) {
                return country.name.toLowerCase().contains(countrySearchQuery.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: allCountries.length,
                itemBuilder: (context, index) {
                  Country country = allCountries[index];
                  return CheckboxListTile(
                    title: Row(
                      children: [
                        CountryFlag.fromCountryCode(
                          country.name,
                          height: 24,
                          width: 32,
                          borderRadius: 4,
                        ),
                        SizedBox(width: 8),
                        Text(country.code),
                      ],
                    ),
                    value: _selectedCountries.contains(country),
                    onChanged: (selected) {
                      setState(() {
                        if (selected!) {
                          _selectedCountries.add(country);
                        } else {
                          _selectedCountries.remove(country);
                        }
                      });
                      saveCountryList(); // Save changes in the background
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      SizedBox(height: 16),
    ],
  );
}

Future<void> saveCountryList() async {
  final countryListId = _selectedCountryList!.id;
  
  final selectedCountries = _selectedCountries.map((country) => {
    'countrylist_id': countryListId,
    'country_code': country.code,
    'country_name': country.name,
  }).toList();

  // Delete existing country list countries
  await Supabase.instance.client
      .from('countrylist_countries')
      .delete()
      .eq('countrylist_id', countryListId);
  // Insert selected countries into the countrylist_countries table
  await Supabase.instance.client
      .from('countrylist_countries')
      .insert(selectedCountries);
}

Future<void> saveCountryListCountries(int countryListId, List<Country> selectedCountries) async {
  // Delete existing country list countries
  await Supabase.instance.client
      .from('countrylist_countries')
      .delete()
      .eq('countrylist_id', countryListId);

  // Insert selected countries into the countrylist_countries table
  await Supabase.instance.client
      .from('countrylist_countries')
      .insert(selectedCountries.map((country) => {
            'countrylist_id': countryListId,
            'countries': {
              'name': country.name,
              'code': country.code,
            },
          }).toList());
}

Future<List<Country>> fetchCountries() async {
  return loadCountries();
}


}

Future<List<Country>> loadCountries() async {
  String jsonString = await rootBundle.loadString('assets/countries.json');
  return compute(parseCountries, jsonString);
}

Future<List<Conference>> fetchConferences() async {
  final response = await Supabase.instance.client
      .from('conferences')
      .select('id, name, date')
      .order('date');

  return response.map((data) => Conference.fromJson(data)).toList();
}








