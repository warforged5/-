import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import "constant.dart";
import "home_page.dart";
import "dart:async";
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_flags/country_flags.dart';
import 'package:getwidget/getwidget.dart';
import 'package:toastification/toastification.dart';

class MainPage extends StatefulWidget {
  final Conference conference;
  final Committee committee;

  MainPage({required this.conference, required this.committee});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  int _speakerTime = 60; // Default speaker time in seconds
  int _remainingTime = 60;
  int _caucusTime = 0;
  int _remainingCaucusTime = 0;
  int currentSpeakersListTime = 60; // Remaining time in seconds


  List<Speaker> _speakersList = [];
  List<Speaker> _currentMod = [];

  List<Motion> _motions = [];
  Timer? _timer;
  bool _isTimerRunning = false;
  CountryList? _selectedCountryList;
  List<Country> selectedCountries = [];
  List<Motion> _votingMotions = [];
  String _resolutionName = '';
  bool _isRollCallVote = false;
  Map<String, String> _votes = {};
  
  TextEditingController _speakerTimeController = TextEditingController();
  TextEditingController _caucusTimeController = TextEditingController();
  TextEditingController _caucusSpeakerTimeController = TextEditingController();
  TextEditingController _diasNotesController = TextEditingController();
  TextEditingController _caucusTopicController = TextEditingController();

  FocusNode _diasNotesFocusNode = FocusNode();
  

  String modType = 'Mod';
  String runningModType = 'Mod';

  String selectedMotionCountry = 'United Kingdom';
  String _notes = "";
  String _currentMode = 'Speakers List';
  Country? dropdownValue;
  Speaker? currentSpeaker;
  Speaker? currentModSpeaker;
  bool fullSpeakersList = false;
  Motion? runningMotion;
  bool _enableTinting = true;

  //Not implimented yet
  bool isAblePreferLast = true;
  bool isAuthorFirstOnSpeakersList = false;
  


  @override
  void initState() {
    super.initState();
    _fetchCommitteeData();
    _diasNotesFocusNode.addListener(_onDiasNotesFocusChange);
  }

  @override
  void dispose() {
    _diasNotesFocusNode.removeListener(_onDiasNotesFocusChange);
    _diasNotesFocusNode.dispose();
    super.dispose();
  }

  void _onDiasNotesFocusChange() {
    if (!_diasNotesFocusNode.hasFocus) {
      _saveNotesToDatabase();
    }
  }

   Future<void> _saveNotesToDatabase() async {
    final response = await Supabase.instance.client
        .from('committees')
        .update({'notes': _diasNotesController.text})
        .eq('id', widget.committee.id);
  }

  Future<void> _fetchCommitteeData() async {
    final response = await Supabase.instance.client
        .from('committees')
        .select('countrylist_id, notes')
        .eq('id', widget.committee.id)
        .single();

    final response3 = await Supabase.instance.client
        .from('motions')
        .select('*')
        .eq('id', widget.committee.id);

        if (response['countrylist_id'] != null) {

    final response2 = await Supabase.instance.client
        .from('countrylists')
        .select('*')
        .eq('id', response['countrylist_id'])
        .single();

      
      setState(() {
        _selectedCountryList = CountryList(id: response['countrylist_id'], name: response2['name'] , userId: response2['user_id'], forAll: response2['for_all']);
        _notes = response['notes'];
        _diasNotesController.text = _notes;
        _motions = _motions = (response3 as List)
          .map((motionData) => Motion.fromMap(motionData))
          .toList();
      });

      selectedCountries = await fetchCountriesForCountryList(_selectedCountryList!.id);
        }
        else{
          setState(() {
        _notes = response['notes'];
        _diasNotesController.text = _notes;
      });
        }
  }
  
 @override
Widget build(BuildContext context) {
  return AdaptiveScaffold(
    selectedIndex: _selectedIndex,
    onSelectedIndexChange: (int index) {
      setState(() {
        _selectedIndex = index;
      });
    },
    destinations: [
      const NavigationDestination(
        icon: Icon(Icons.list),
        selectedIcon: Icon(Icons.list),
        label: 'Speakers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.how_to_vote),
        selectedIcon: Icon(Icons.how_to_vote),
        label: 'Voting',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
      const NavigationDestination(
        icon: Icon(Icons.exit_to_app),
        selectedIcon: Icon(Icons.exit_to_app),
        label: 'Back',
      ),
    ],
    body: (_) => _buildBody(),
    smallBody: (_) => _buildSmallBody(),
    secondaryBody: (_) => _buildSecondaryBody(),
  );
}

Widget _buildBody() {
  switch (_selectedIndex) {
    case 0:
      return Column(
        children: [
          SizedBox(height: 16.0),
          _buildTimer(),
          SizedBox(height: 8.0),
          _buildButtons(),
          Visibility(
            visible: (runningMotion?.type == "Mod" ||
            runningMotion?.type == "Unmod" ||
            runningMotion?.type == "Seated Mod" ||
            runningMotion?.type == "Round Robin" ||
            runningMotion?.type == "Consulation of the Whole")
            &&
            _currentMode != "Speakers List"
          , child: SizedBox(height: 8.0),),
          Visibility(
            visible: (runningMotion?.type == "Mod" ||
            runningMotion?.type == "Unmod" ||
            runningMotion?.type == "Seated Mod" ||
            runningMotion?.type == "Round Robin" ||
            runningMotion?.type == "Consulation of the Whole") &&
            _currentMode != "Speakers List"
          , child: _buildModInfo()),
          SizedBox(height: 8.0),
          Expanded(child: _buildSpeakersList()),
          SizedBox(height: 8.0),
        ],
      );
    case 1:
      return _buildVotingPage();
    case 2:
      return _buildSettingsPage();
    case 3:
      // Handle the "Back" button action
    
      return Container();
    default:
      return Container();
  }
}

  Widget _buildSmallBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTimer(),
          _buildButtons(),
          _buildSpeakersList(),
        ],
      ),
    );
  }

  Widget _buildSecondaryBody() {
  
    switch (_selectedIndex) {
    case 0:
      if (fullSpeakersList == false) {return Column(
      children: [
        SizedBox(height: 8.0),
        _buildMotionList(),
        _buildAddMotion(),
        Row(
          children: [
            SizedBox(height: 8.0),
            _buildStatistics(),
            SizedBox(height: 8.0),
            Expanded(child: _buildDiasNotes()),
            SizedBox(width: 8.0),
          ],
        ),
      ],
    );}
    else{
      return Column(
      children: [
        
        SizedBox(height: 8.0),
        _buildFullSpeakersList(),
        Row(
          children: [
            SizedBox(height: 8.0),
            _buildStatistics(),
            SizedBox(height: 8.0),
            Expanded(child: _buildDiasNotes()),
            SizedBox(width: 8.0),
          ],
        ),
      ],
    );
    }
    case 1:
      return Column(
      children: [
        SizedBox(height: 8.0),
        if (_isRollCallVote) _buildVoteCountBar(),
        Expanded(
          child: _buildMotionList(),
        ),
        _buildAddMotion(),
        
      ],
    );
    case 2:
      return Container();
    case 3:
      // Handle the "Back" button action
    
      return Container();
    default:
      return Container();
  }
  }

  void _startTimer() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      if (_remainingTime > 0) {
        _remainingTime--;
      } else {
        _timer?.cancel();
        _isTimerRunning = false;
      }
      if (_remainingCaucusTime > 0) {
        _remainingCaucusTime--;
      }
    });
  });
  _isTimerRunning = true;
}

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = _speakerTime;
      _isTimerRunning = false;
    });
  }

  void _setSpeakerTime(int seconds) {
    setState(() {
      if(_currentMode == "Speakers List"){
        currentSpeakersListTime = seconds;
      }
      _speakerTime = seconds;
      _remainingTime = seconds;
    });
  }

  Widget _buildTimer() {
    String formattedTime = _formatTime(_remainingTime);
    String formattedTotalTime = _formatTime(_speakerTime);
    
      Speaker? timerSpeaker;
    if(_currentMode == "Speakers List"){timerSpeaker = currentSpeaker;}
    else{timerSpeaker = currentModSpeaker;}

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(15))
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              CountryFlag.fromCountryCode(
                          timerSpeaker?.country.name ?? "None",
                          height: 48,
                          width: 64,
                          borderRadius: 10,
                        ),
                        SizedBox(width: 16,),
          Text(timerSpeaker?.country.code ?? "No Speaker Selected", textScaler: TextScaler.linear(2),),
          
            ],
          ),
          SizedBox(height: 16.0),
          Text(
          '$formattedTime / $formattedTotalTime',
          style: TextStyle(fontSize: 100.0),
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _showYieldSpeakerDialog();
                },
                icon: Icon(Icons.volunteer_activism),
              ),
              SizedBox(width: 16.0),
              SegmentedButton<int>(
                   segments: [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.settings),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: _isTimerRunning ? Icon(Icons.pause) : Icon(Icons.play_arrow),
                      ),
                      ButtonSegment(
                        value: 2,
                        icon: Icon(Icons.replay),
                      ),
                    ],
                  selected: {},
                  emptySelectionAllowed: true,
                  onSelectionChanged: (Set<int> newSelection) {
                        if (newSelection.contains(0)) {
                          _showSpeakerTimeDialog();
                        } else if (newSelection.contains(1)) {
                          if (_isTimerRunning) {
                            _timer?.cancel();
                            _isTimerRunning = false;
                            
                          } else {
                            _startTimer();
                          }
                          // Deselect the segment after clicking play
                          Future.delayed(Duration.zero, () {
                            setState(() {
                              newSelection.clear();
                            });
                          });
                        } else if (newSelection.contains(2)) {
                          _resetTimer();
                        }
                        setState(() { newSelection.clear(); });
                      },
                ),
                SizedBox(width: 16.0),
                IconButton(
                onPressed: () {
                  if(_currentMode == "Speakers List"){
                    if (_speakersList.isNotEmpty) {
                    setState(() {
                      currentSpeaker = _speakersList.removeAt(0);
                    });
                    } else {
                      setState(() {
                        currentSpeaker = null;
                      });
                    }
                  }
                  else{
                    if (_currentMod.isNotEmpty) {
                    setState(() {
                        currentModSpeaker = _currentMod.removeAt(0);
                    });
                    } else {
                      setState(() {
                        currentModSpeaker = null;
                      });
                    }
                  }
                },
                icon: Icon(Icons.next_plan, size: 30,),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSpeakerTimeDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      TextEditingController _speakerTimeController = TextEditingController(text: _speakerTime.toString());
      return AlertDialog(
        title: Text('Set Speaking Time'),
        content: TextField(
          controller: _speakerTimeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Time (in seconds)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              int? time = int.tryParse(_speakerTimeController.text);
              if (time != null) {
                _setSpeakerTime(time);
                Navigator.of(context).pop();
              }
            },
            child: Text('Set'),
          ),
        ],
      );
    },
  );
}

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: ElevatedButton(
          onPressed: () {
            setState(() {
              _currentMode = _currentMode == 'Speakers List'
                  ? 'Moderated Caucus'
                  : 'Speakers List';
              if (_currentMode == "Speakers List"){
                _setSpeakerTime(currentSpeakersListTime);
              }
              else if(_currentMode == "Moderated Caucus"){
                _setSpeakerTime(runningMotion?.speakingTime ?? 60);
              }
            });
          },
          child: Text(_currentMode),
        ),
        ),
        
        IconButton(
          onPressed: () {
            setState(() {
              _speakersList.clear();
            });
          },
          icon: Icon(Icons.layers_clear_outlined),
        ),
        IconButton(
          onPressed: () {
            _showAddSpeakerDialog();
          },
          icon: Icon(Icons.add_circle_outline),
        ),
        IconButton(
          onPressed: () {
            fullSpeakersList = !fullSpeakersList;
            setState(() {});
          },
          icon: Icon(Icons.change_circle_outlined),
        ),
      ],
    );
  }

  Widget _buildModInfo(){
    String formattedCaucusTime = _formatTime(_remainingCaucusTime);
    String formattedTotalCaucusTime = _formatTime(_caucusTime);

      return Container(
        decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(15))
        
      ),
      padding: EdgeInsets.all(16.0),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Visibility(
            visible: runningMotion?.description != null,
          child:
            Text(
              "Topic: " + (runningMotion?.description ?? 'None'),
              style: TextStyle(fontSize: 20.0),
          ),),
          Expanded(child: SizedBox(),),
            Text(
              'Total Time: $formattedCaucusTime / $formattedTotalCaucusTime',
              style: TextStyle(fontSize: 20.0),
          ),
          
        
        ],
            ),
      );
  }

  void _showAddSpeakerDialog() async{
     TextEditingController _searchController = TextEditingController();
    List<Country> countries = await fetchCountriesForCountryList(_selectedCountryList!.id);
    List<Country> _filteredCountries = countries;

  if (_selectedCountryList == null) {
    // No country list selected, show navigation button
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Country List Selected'),
          content: Text('Please select a country list in the settings.'),
          actions: [
            TextButton(
              onPressed: () {
                _buildSettingsPage();
              },
              child: Text('Go to Settings'),
            ),
          ],
        );
      },
    );
  } else {
    // Country list selected, show search and selection dialog
     showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Add Speaker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Countries',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filteredCountries = countries
                          .where((country) => country.name.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Container(
                  height: 300.0, // Fixed height for the scrollable area
                  child: SingleChildScrollView(
                    child: Column(
                      children: _filteredCountries.map((country) {
                        return ListTile(
                          title: Text(country.code),
                          onTap: () {
                            setState(() {
                              if (_currentMode == "Speakers List"){_speakersList.add(Speaker(name: country.code, country: country));}
                              else {_currentMod.add(Speaker(name: country.code, country: country));}
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ).then((_) {
    setState(() {});  // Ensure the main widget rebuilds after closing the dialog
  });
  }
}

  Widget _buildSpeakersList() {

  List<Speaker> smallSpeakersList;

  if (fullSpeakersList && _speakersList.length > 12 && _currentMode == 'Speakers List'){
    smallSpeakersList = _speakersList.sublist(0,12);
  }
  else if(fullSpeakersList && _currentMod.length > 12 && _currentMode == 'Moderated Caucus'){
    smallSpeakersList = _currentMod.sublist(0,12);
  }
  else if(_currentMod.length <= 12 && _currentMode == 'Moderated Caucus'){
    smallSpeakersList = _currentMod;
  }
  else{
    smallSpeakersList = _speakersList;
  }
  return Container(
    decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(15))
      ),
    child: ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: smallSpeakersList.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CountryFlag.fromCountryCode(
                          smallSpeakersList[index].country.name,
                          height: 48,
                          width: 64,
                          borderRadius: 10,
                        ),
          title: Text(smallSpeakersList[index].country.code, textScaler: TextScaler.linear(2),),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index == 0) Text('On Deck', style: TextStyle(fontWeight: FontWeight.bold), textScaler: TextScaler.linear(2),), SizedBox(width: 5),
              IconButton(
                icon: Icon(Icons.clear, size: 33,),
                onPressed: () {
                  setState(() {
                    smallSpeakersList.removeAt(index);
                  });
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildMotionList() {
    
    return Expanded(
      child: Container(
      padding: EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        child: ListView.builder(
          itemCount: _motions.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:[
                    Text("Type:  " + _motions[index].type),
                    Text("Length:  " + _motions[index].caucusTime.toString()),
                    Text("Speaking Time:  " + _motions[index].speakingTime.toString()),
                    Text("Proposed By:  " + _motions[index].author.code),
                    ]),
                    Text(_motions[index].description),
                ],
              ),
              trailing: SegmentedButton<int>(
                emptySelectionAllowed: true,
                style: ButtonStyle(backgroundColor:  WidgetStateProperty.all(Theme.of(context).colorScheme.primaryFixedDim)),
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Icon(Icons.check),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Icon(Icons.remove),
                  ),
                ],
                selected: {},
                onSelectionChanged: (Set<int> newSelection) {
                  if (newSelection.contains(0)) {
                    _preformMotionFunction(_motions[index]);
                    _deleteMotion(_motions[index]);
                    // Motion passed
                    setState(() {
                      _motions.removeAt(index);
                    });
                  } else if (newSelection.contains(1)) {
                    // Motion failed
                    _deleteMotion(_motions[index]);
                    setState(() {
                      _motions.removeAt(index);
                    });
                  }
                },
              ),
            );
          },
        ),
      ),
      ),
    );
  }

 Widget _buildAddMotion() {
  return Container(
    padding: EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).colorScheme.primaryFixedDim,
                  ),
                  child: DropdownMenu<String>(
                    requestFocusOnTap: true,
                    expandedInsets: EdgeInsets.zero,
                    inputDecorationTheme: const InputDecorationTheme(
                          filled: false,
                          
                          border: InputBorder.none,
                        ),
                    initialSelection: modType,
                    dropdownMenuEntries: <String>['Mod', 'Unmod', 'Seated Mod', 'Open Speakers List', 'Round Robin', 'Introduce Working Papers', 'Table Debate', "Reintroduce", 'Enter voting procedure', "Supend Debate", "Consultation of the whole", 'Adjourn Meeting'].map((String value) {
                      return DropdownMenuEntry<String>(
                        value: value,
                        label: value,
                      );
                    }).toList(),
                    onSelected: (String? newValue) {
                      setState(() {
                        modType = newValue!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Visibility(
                visible: modType != 'Open Speakers List' &&
                 modType != 'Introduce Working Papers' &&
                  modType != 'Table Debate' &&
                   modType != 'Reintroduce' &&
                    modType != 'Enter voting procedure' &&
                     modType != 'Supend Debate' &&
                      modType != 'Consultation of the whole' &&
                       modType != 'Adjourn Meeting',
              child: Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).colorScheme.primaryFixedDim,
                  ),
                  child: TextField(
                    controller: _caucusTimeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Caucus Time',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              ),
              Visibility(
                visible: modType != 'Open Speakers List' &&
                 modType != 'Introduce Working Papers' &&
                  modType != 'Table Debate' &&
                   modType != 'Reintroduce' &&
                    modType != 'Enter voting procedure' &&
                     modType != 'Supend Debate' &&
                      modType != 'Consultation of the whole' &&
                       modType != 'Adjourn Meeting',
                child:
              SizedBox(width: 16.0),
              ),
              
               Visibility(
                visible: modType != 'Unmod' &&
                 modType != 'Open Speakers List' &&
                  modType != 'Open Speakers List' &&
                 modType != 'Introduce Working Papers' &&
                  modType != 'Table Debate' &&
                   modType != 'Reintroduce' &&
                    modType != 'Enter voting procedure' &&
                     modType != 'Supend Debate' &&
                       modType != 'Adjourn Meeting',
                child: Expanded(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Theme.of(context).colorScheme.primaryFixedDim,
                    ),
                    child: TextField(
                      controller: _caucusSpeakerTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Speaker Time',
                      ),
                    ),
                  ),
                ),
              ),

              Visibility(
                visible: modType != 'Unmod' &&
                 modType != 'Open Speakers List' &&
                  modType != 'Open Speakers List' &&
                 modType != 'Introduce Working Papers' &&
                  modType != 'Table Debate' &&
                   modType != 'Reintroduce' &&
                    modType != 'Enter voting procedure' &&
                     modType != 'Supend Debate' &&
                       modType != 'Adjourn Meeting',
                child: SizedBox(width: 16.0),
                ),

              Visibility(
                child: Expanded(
                child:  Container(
                  padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).colorScheme.primaryFixedDim,
                  ),
                  child: DropdownMenu<Country>(
                        hintText: "Country",
                        enableFilter: true,
                        requestFocusOnTap: true,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: false,
                          
                          border: InputBorder.none,
                        ),
                        onSelected: (Country? selectedCountry) {
                          setState(() {
                            dropdownValue = selectedCountry;
                          });
                        },
                        dropdownMenuEntries:
                            selectedCountries.map<DropdownMenuEntry<Country>>(
                          (Country selectedCountry) {
                            return DropdownMenuEntry<Country>(
                              value: selectedCountry,
                              label: selectedCountry.code,
                            );
                          },
                        ).toList(),
                      ),
                ),
              ),
              ),
             SizedBox(width: 16.0),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Theme.of(context).primaryColor,
                ),
                child: IconButton(
                  icon: Icon(Icons.add),
                  color: Colors.white,
                  onPressed: () {
                    _saveMotion();
                    print('Motion saved');
                  },
                ),
              ),
            ],
          ),
          Visibility(
                visible: modType != 'Open Speakers List' &&
                 modType != 'Introduce Working Papers' &&
                  modType != 'Table Debate' &&
                    modType != 'Enter voting procedure' &&
                     modType != 'Supend Debate' &&
                      modType != 'Adjourn Meeting',
            child: TextField(
            controller: _caucusTopicController,
            decoration: InputDecoration(
              labelText: 'Caucus Topic',
            ),
          ),
          ),
        ],
      ),
    ),
  );
}

 Future<void> _saveMotion() async {
  try{
    final response = await Supabase.instance.client
        .from('motions')
        .insert({
          'committee_id': widget.committee.id,
          'type': modType,
          'created_by': dropdownValue!.toJson(),
          'description': _caucusTopicController.text,
          'status': 'pending',
          'caucus_time': int.tryParse(_caucusTimeController.text) ?? 0,
          'speaking_time': int.tryParse(_caucusSpeakerTimeController.text) ?? 0,
        });
      setState(() {
        _motions.add(Motion(id: 1, author: dropdownValue!, committeeId: widget.committee.id, type: modType, description: _caucusTopicController.text, status: 'pending', caucusTime: int.tryParse(_caucusTimeController.text) ?? 0, speakingTime: int.tryParse(_caucusSpeakerTimeController.text) ?? 0));
        _caucusTimeController.clear();
        _caucusSpeakerTimeController.clear();
        _caucusTopicController.clear();
        dropdownValue = null;
      });
  }
  catch (e){
   toastification.show(
	  context: context,
	  type: ToastificationType.error,
	  style: ToastificationStyle.minimal,
	  title: Text("Motion Adding Failed"),
	  alignment: Alignment.bottomCenter,
	  autoCloseDuration: const Duration(seconds: 4),
	  backgroundColor: Theme.of(context).colorScheme.onSurface,
	  boxShadow: highModeShadow,
	);
  }
  }

  Future<void> _deleteMotion(Motion deletedMotion) async{
    await Supabase.instance.client
        .from('motions').delete().eq('type', deletedMotion.type).eq('description', deletedMotion.description).eq('committee_id', widget.committee.id).eq("caucus_time", deletedMotion.caucusTime);
  }

  Widget _buildStatistics() {
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        constraints: BoxConstraints(maxWidth: 150, minHeight: 5),
         decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.radio_button_checked, size: 70, color: Theme.of(context).colorScheme.onPrimaryContainer,),SizedBox(width: 16,), Text("60", textScaler: TextScaler.linear(1.5),)],),
            Row(children: [Icon(Icons.radio_button_checked, size: 70, color: Theme.of(context).colorScheme.onPrimaryContainer,),SizedBox(width: 16,), Text("60", textScaler: TextScaler.linear(1.5),)],),
            Row(children: [Icon(Icons.timelapse, size: 70, color: Theme.of(context).colorScheme.onPrimaryContainer,),SizedBox(width: 16,), Text("60", textScaler: TextScaler.linear(1.5),)],),
          ],
        ),
      ),
    );
  }

  Widget _buildDiasNotes() {
  return Container(
  constraints: BoxConstraints(minHeight: 241),
     decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
    padding: EdgeInsets.all(16.0),
       child:  TextField(
          controller: _diasNotesController,
          focusNode: _diasNotesFocusNode,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Enter notes...',
            border: InputBorder.none,
          ),
          style: TextStyle(fontSize: 22.0),
        ),
  );
}

  Widget _buildSettingsPage() {
  return FutureBuilder<List<CountryList>>(
    future: fetchCountryLists(),
    builder: (BuildContext context, AsyncSnapshot<List<CountryList>> snapshot) {
      if (snapshot.hasData) {
        List<CountryList> _countryLists = snapshot.data!;
        return ListView.builder(
          itemCount: _countryLists.length,
          itemBuilder: (BuildContext context, int index) {
            CountryList countryList = _countryLists[index];
            return ListTile(
              title: Text(countryList.name),
              onTap: () {
                // Set the selected country list
                _selectedCountryList = countryList;
                setCountryList(countryList.id);
                setState(() {});
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

  Widget _buildFullSpeakersList() {
    if (_speakersList.length > 12 && _currentMode == 'Speakers List'){
    List<Speaker> _expandedSpeakersList = _speakersList.sublist(12);
    return Expanded(
      child: Container(
      padding: EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        child: ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _expandedSpeakersList.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CountryFlag.fromCountryCode(
                          _expandedSpeakersList[index].country.name,
                          height: 24,
                          width: 32,
                          borderRadius: 5,
                        ),
          title: Text(_expandedSpeakersList[index].country.code, textScaler: TextScaler.linear(1),),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.clear, size: 33,),
                onPressed: () {
                  setState(() {
                    _speakersList.removeAt(index);
                  });
                },
              ),
            ],
          ),
        );
      },
    ),
      ),
      ),
    );
    }
    else if( _currentMod.length > 12 && _currentMode == 'Moderated Caucus'){
      List<Speaker> _expandedSpeakersList = _currentMod.sublist(12);
    return Expanded(
      child: Container(
      padding: EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        child: ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _expandedSpeakersList.length,
      itemBuilder: (context, index) {
        return ListTile(
         
          leading: CountryFlag.fromCountryCode(
                          _expandedSpeakersList[index].country.name,
                          height: 24,
                          width: 32,
                          borderRadius: 5,
                        ),
          title: Text(_expandedSpeakersList[index].country.code, textScaler: TextScaler.linear(1),),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.clear, size: 33,),
                onPressed: () {
                  setState(() {
                    _speakersList.removeAt(index);
                  });
                },
              ),
            ],
          ),
        );
      },
    ),
      ),
      ),
    );
    }
    else{
      return Expanded(
       child: Container(
      padding: EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          ),
          ),
    );
    }
  }

  void setCountryList(int countryListID) async {
  await Supabase.instance.client.from('committees')
    .update({ 'countrylist_id': countryListID })
    .eq('id', widget.committee.id);
  }

 void _showYieldSpeakerDialog() async{
     TextEditingController _searchController = TextEditingController();
    List<Country> countries = await fetchCountriesForCountryList(_selectedCountryList!.id);
    List<Country> _filteredCountries = countries;

  if (_selectedCountryList == null) {
    // No country list selected, show navigation button
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Country List Selected'),
          content: Text('Please select a country list in the settings.'),
          actions: [
            TextButton(
              onPressed: () {
                _buildSettingsPage();
              },
              child: Text('Go to Settings'),
            ),
          ],
        );
      },
    );
  } else {
    // Country list selected, show search and selection dialog
     showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Add Speaker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Countries',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filteredCountries = countries
                          .where((country) => country.name.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Container(
                  height: 300.0, // Fixed height for the scrollable area
                  child: SingleChildScrollView(
                    child: Column(
                      children: _filteredCountries.map((country) {
                        return ListTile(
                          title: Text(country.code),
                          onTap: () {
                            setState(() {
                              currentSpeaker = Speaker(name: country.code, country: country);
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ).then((_) {
    setState(() {});  // Ensure the main widget rebuilds after closing the dialog
  });
  }
}

 void _preformMotionFunction(Motion _selectedMotion){
  if (_selectedMotion.type == "Mod"){
    runningModType = "Mod";
    _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setSpeakerTime(_selectedMotion.speakingTime);
    _setCaucusTime(_selectedMotion.caucusTime);
    _showSpeakerOrderDialog(_selectedMotion);
  }
  else if (_selectedMotion.type == "Unmod"){
    runningModType = "Unmod";
    _currentMode = 'Speakers List';
    _setSpeakerTime(_selectedMotion.speakingTime);
    _setCaucusTime(_selectedMotion.caucusTime);
  }
  else if (_selectedMotion.type == "Seated Mod"){
    runningModType = "Seated Mod";
     _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setSpeakerTime(_selectedMotion.speakingTime);
    _showSpeakerOrderDialog(_selectedMotion);
    _setCaucusTime(_selectedMotion.caucusTime);
  }
  else if (_selectedMotion.type == "Open Speakers List"){
    runningModType = "Open Speakers List";
    _currentMode = 'Speakers List';
    if(isAuthorFirstOnSpeakersList){
    _showSpeakerOrderDialog(_selectedMotion);
    }
  }
  else if (_selectedMotion.type == "Round Robin"){
    runningModType = "Round Robin";
     _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setCaucusTime(_selectedMotion.caucusTime);
    _setSpeakerTime(_selectedMotion.speakingTime);
    _showSpeakerOrderDialog(_selectedMotion);
  }
  else if (_selectedMotion.type == "Introduce Working Papers"){

  }
  else if (_selectedMotion.type == "Table Debate"){
    
  }
  else if (_selectedMotion.type == "Enter voting procedure"){
    
  }
  else if (_selectedMotion.type == "Supend Debate"){
    
  }
  else if (_selectedMotion.type == "Consultation of the whole"){
    runningModType = "Consultation of the whole";
     _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setCaucusTime(_selectedMotion.caucusTime);
    _setSpeakerTime(_selectedMotion.speakingTime);
    currentModSpeaker = Speaker(
                        name: _selectedMotion.author.code,
                        country: _selectedMotion.author,
                      );
  }
  else if (_selectedMotion.type == "Adjourn Meeting"){
    
  }
  else {

  }
  runningMotion = _selectedMotion;
  setState(() {
  });
 }

void _showSpeakerOrderDialog(Motion motion) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      bool _speakFirst = false;
      bool _speakLast = false;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Speaker Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Speak First'),
                  value: _speakFirst,
                  onChanged: (value) {
                    setState(() {
                      _speakFirst = value!;
                      _speakLast = false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Speak Last'),
                  value: _speakLast,
                  onChanged: (value) {
                    setState(() {
                      _speakLast = value!;
                      _speakFirst = false;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_speakFirst) {
                    setState(() {
                      currentModSpeaker = Speaker(
                        name: motion.author.code,
                        country: motion.author,
                      );
                    });
                  } else if (_speakLast) {
                    setState(() {
                      currentModSpeaker = Speaker(
                        name: motion.author.code,
                        country: motion.author,
                      );
                      _currentMod.add(currentModSpeaker!);
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    setState(() {});
  });
}

void _setCaucusTime(int seconds) {
  setState(() {
    _caucusTime = seconds * 60;
    _remainingCaucusTime = seconds * 60;
  });
}

Widget _buildVotingPage() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isRollCallVote = true;
                      });
                    },
                    child: Text('Roll Call Vote'),
                  ),
                  SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isRollCallVote = false;
                      });
                    },
                    child: Text('Vote by Acclimation'),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Resolution Name',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _resolutionName = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isRollCallVote ? _buildRollCallVoteList() : Container(),
        ),
      ],
    );
  }

Widget _buildVoteCountBar() {
    int yesCount = _votes.values.where((vote) => vote == 'Yes').length;
    int noCount = _votes.values.where((vote) => vote == 'No').length;
    int abstainCount = _votes.values.where((vote) => vote == 'Abstain').length;
    int totalCount = selectedCountries.length;

    return Container(
      height: 40.0,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            flex: yesCount,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(20.0),
                ),
              ),
            ),
          ),
          Expanded(
            flex: noCount,
            child: Container(
              color: Colors.red,
            ),
          ),
          Expanded(
            flex: abstainCount,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(20.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRollCallVoteList() {
  return Container(
    decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15))
      ),
      padding: EdgeInsets.all(8.0),
    child: ListView.builder(
      itemCount: selectedCountries.length,
      itemBuilder: (context, index) {
        Country country = selectedCountries[index];
        String vote = _votes[country.code] ?? '';
        Color tintColor = _getTintColor(vote);
    
        bool isFirstItem = index == 0;
        bool isLastItem = index == selectedCountries.length - 1;
        String prevVote = isFirstItem ? '' : _votes[selectedCountries[index - 1].code] ?? '';
        String nextVote = isLastItem ? '' : _votes[selectedCountries[index + 1].code] ?? '';
    
        BorderRadius borderRadius = BorderRadius.zero;
        if (vote.isEmpty) {
        } 
        else if (vote.isNotEmpty && nextVote.isNotEmpty){
          if (prevVote.isNotEmpty) {
            borderRadius = BorderRadius.all(Radius.circular(6));
          }
          else {
            borderRadius = BorderRadius.vertical(top: Radius.circular(15.0), bottom: Radius.circular(6.0));
          }
        }
        else if (vote.isNotEmpty && prevVote.isNotEmpty) {
            borderRadius = BorderRadius.vertical(bottom: Radius.circular(15.0), top: Radius.circular(6));
        }
        else{
          borderRadius = BorderRadius.all(Radius.circular(15));
        }
    
        return Column(
          children: [
            Container(
            
              decoration: BoxDecoration(
                color: _enableTinting ? tintColor : null,
                borderRadius: borderRadius,
              ),
              child: ListTile(
                leading: CountryFlag.fromCountryCode(
                  country.name,
                  height: 24.0,
                  width: 32.0,
                  borderRadius: 5.0,
                ),
                title: Text(country.code),
                trailing: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'Yes', label: Text('Yes')),
                    ButtonSegment(value: 'No', label: Text('No')),
                    ButtonSegment(value: 'Abstain', label: Text('Abstain')),
                  ],
                  selected: {vote},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _votes[country.code] = selection.isEmpty ? '' : selection.first;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 2.0), 
          ],
        );
      },
    ),
  );
}
  
  Color _getTintColor(String vote) {
    switch (vote) {
      case 'Yes':
        return Colors.green.withOpacity(0.2);
      case 'No':
        return Colors.red.withOpacity(0.2);
      case 'Abstain':
        return Color.fromARGB(255, 202, 182, 4).withOpacity(0.2);
      default:
        return Colors.transparent;
    }
  }

}





 