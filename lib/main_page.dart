import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import "constant.dart";
import "dart:async";
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_flags/country_flags.dart';
import 'package:toastification/toastification.dart';

class MainPage extends StatefulWidget {
  final Conference conference;
  final Committee committee;

  const MainPage({super.key, required this.conference, required this.committee});

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


  final List<Speaker> _speakersList = [];
  final List<Speaker> _currentMod = [];

  List<Motion> _motions = [];
  Timer? _timer;
  bool _isTimerRunning = false;
  CountryList? _selectedCountryList;
  List<Country> selectedCountries = [];
  final List<Motion> _votingMotions = [];
  String _resolutionName = '';
  bool _isRollCallVote = false;
  final Map<String, String> _votes = {};

  
  
  final TextEditingController _speakerTimeController = TextEditingController();
  final TextEditingController _caucusTimeController = TextEditingController();
  final TextEditingController _caucusSpeakerTimeController = TextEditingController();
  final TextEditingController _diasNotesController = TextEditingController();
  final TextEditingController _caucusTopicController = TextEditingController();
  final TextEditingController _resolutionTitleController = TextEditingController();
  final TextEditingController _clauseController = TextEditingController();
  

  final FocusNode _diasNotesFocusNode = FocusNode();
  
  String _voteMotionType = 'Vote on by Acclimation';
  String modType = 'Mod';
  String runningModType = 'Mod';

  String selectedMotionCountry = 'United Kingdom';
  String _notes = "";
  String _currentMode = 'Speakers List';
  Country? dropdownValue;
  Speaker? currentSpeaker;
  Speaker? currentModSpeaker;
  Resolution? _selectedResolution;
  bool fullSpeakersList = false;
  Motion? runningMotion;
  final bool _enableTinting = true;

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
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.list),
        selectedIcon: Icon(Icons.list),
        label: 'Speakers',
      ),
      NavigationDestination(
        icon: Icon(Icons.how_to_vote),
        selectedIcon: Icon(Icons.how_to_vote),
        label: 'Voting',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
      NavigationDestination(
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
          const SizedBox(height: 16.0),
          _buildTimer(),
          const SizedBox(height: 8.0),
          _buildButtons(),
          Visibility(
            visible: (runningMotion?.type == "Mod" ||
            runningMotion?.type == "Unmod" ||
            runningMotion?.type == "Seated Mod" ||
            runningMotion?.type == "Round Robin" ||
            runningMotion?.type == "Consulation of the Whole")
            &&
            _currentMode != "Speakers List"
          , child: const SizedBox(height: 8.0),),
          Visibility(
            visible: (runningMotion?.type == "Mod" ||
            runningMotion?.type == "Unmod" ||
            runningMotion?.type == "Seated Mod" ||
            runningMotion?.type == "Round Robin" ||
            runningMotion?.type == "Consulation of the Whole") &&
            _currentMode != "Speakers List"
          , child: _buildModInfo()),
          const SizedBox(height: 8.0),
          Expanded(child: _buildSpeakersList()),
          const SizedBox(height: 8.0),
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
        const SizedBox(height: 8.0),
        _buildMotionList(),
        _buildAddMotion(),
        Row(
          children: [
            const SizedBox(height: 8.0),
            _buildStatistics(),
            const SizedBox(height: 8.0),
            Expanded(child: _buildDiasNotes()),
            const SizedBox(width: 8.0),
          ],
        ),
      ],
    );}
    else{
      return Column(
      children: [
        
        const SizedBox(height: 8.0),
        _buildFullSpeakersList(),
        Row(
          children: [
            const SizedBox(height: 8.0),
            _buildStatistics(),
            const SizedBox(height: 8.0),
            Expanded(child: _buildDiasNotes()),
            const SizedBox(width: 8.0),
          ],
        ),
      ],
    );
    }
    case 1:
      return Column(
      children: [
        const SizedBox(height: 8.0),
        if (_isRollCallVote) _buildVoteCountBar(),
        Expanded(
          child: _buildMotionList(),
        ),
         _buildAddVoteMotion(),
        
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
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
      padding: const EdgeInsets.all(16.0),
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
                        const SizedBox(width: 16,),
          Text(timerSpeaker?.country.code ?? "No Speaker Selected", textScaler: const TextScaler.linear(2),),
          
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
          '$formattedTime / $formattedTotalTime',
          style: const TextStyle(fontSize: 100.0),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _showYieldSpeakerDialog();
                },
                icon: const Icon(Icons.volunteer_activism),
              ),
              const SizedBox(width: 16.0),
              SegmentedButton<int>(
                   segments: [
                      ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.settings),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: _isTimerRunning ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                      ),
                      ButtonSegment(
                        value: 2,
                        icon: const Icon(Icons.replay),
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
                const SizedBox(width: 16.0),
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
                icon: const Icon(Icons.next_plan, size: 30,),
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
      TextEditingController speakerTimeController = TextEditingController(text: _speakerTime.toString());
      return AlertDialog(
        title: const Text('Set Speaking Time'),
        content: TextField(
          controller: speakerTimeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Time (in seconds)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              int? time = int.tryParse(speakerTimeController.text);
              if (time != null) {
                _setSpeakerTime(time);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Set'),
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
          icon: const Icon(Icons.layers_clear_outlined),
        ),
        IconButton(
          onPressed: () {
            _showAddSpeakerDialog();
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
        IconButton(
          onPressed: () {
            fullSpeakersList = !fullSpeakersList;
            setState(() {});
          },
          icon: const Icon(Icons.change_circle_outlined),
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
      padding: const EdgeInsets.all(16.0),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Visibility(
            visible: runningMotion?.description != null,
          child:
            Text(
              "Topic: ${runningMotion?.description ?? 'None'}",
              style: const TextStyle(fontSize: 20.0),
          ),),
          const Expanded(child: SizedBox(),),
            Text(
              'Total Time: $formattedCaucusTime / $formattedTotalCaucusTime',
              style: const TextStyle(fontSize: 20.0),
          ),
          
        
        ],
            ),
      );
  }

  void _showAddSpeakerDialog() async{
     TextEditingController searchController = TextEditingController();
    List<Country> countries = await fetchCountriesForCountryList(_selectedCountryList!.id);
    List<Country> filteredCountries = countries;

  if (_selectedCountryList == null) {
    // No country list selected, show navigation button
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Country List Selected'),
          content: const Text('Please select a country list in the settings.'),
          actions: [
            TextButton(
              onPressed: () {
                _buildSettingsPage();
              },
              child: const Text('Go to Settings'),
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
            title: const Text('Add Speaker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Countries',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filteredCountries = countries
                          .where((country) => country.name.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 300.0, // Fixed height for the scrollable area
                  child: SingleChildScrollView(
                    child: Column(
                      children: filteredCountries.map((country) {
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
          title: Text(smallSpeakersList[index].country.code, textScaler: const TextScaler.linear(2),),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index == 0) Text('On Deck', style: TextStyle(fontWeight: FontWeight.bold), textScaler: const TextScaler.linear(2),), const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.clear, size: 33,),
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
      padding: const EdgeInsets.all(8.0),
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
                    Text("Type:  ${_motions[index].type}"),
                    Text("Length:  ${_motions[index].caucusTime}"),
                    Text("Speaking Time:  ${_motions[index].speakingTime}"),
                    Text("Proposed By:  ${_motions[index].author.code}"),
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
                    label: const Icon(Icons.check),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: const Icon(Icons.remove),
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
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
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
              const SizedBox(width: 16.0),
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
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).colorScheme.primaryFixedDim,
                  ),
                  child: TextField(
                    controller: _caucusTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
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
              const SizedBox(width: 16.0),
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
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Theme.of(context).colorScheme.primaryFixedDim,
                    ),
                    child: TextField(
                      controller: _caucusSpeakerTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
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
                child: const SizedBox(width: 16.0),
                ),

              Visibility(
                child: Expanded(
                child:  Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
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
             const SizedBox(width: 16.0),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Theme.of(context).primaryColor,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add),
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
            decoration: const InputDecoration(
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
	  title: const Text("Motion Adding Failed"),
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
        padding: const EdgeInsets.all(16.0),
        constraints: const BoxConstraints(maxWidth: 150, minHeight: 5),
         decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.radio_button_checked, size: 70, color: Theme.of(context).colorScheme.onPrimaryContainer,),const SizedBox(width: 16,), const Text("60", textScaler: TextScaler.linear(1.5),)],),
            Row(children: [Icon(Icons.radio_button_checked, size: 70, color: Theme.of(context).colorScheme.onPrimaryContainer,),const SizedBox(width: 16,), const Text("60", textScaler: TextScaler.linear(1.5),)],),
            Row(children: [Icon(Icons.timelapse, size: 70, color: Theme.of(context).colorScheme.onPrimaryContainer,),const SizedBox(width: 16,), const Text("60", textScaler: TextScaler.linear(1.5),)],),
          ],
        ),
      ),
    );
  }

  Widget _buildDiasNotes() {
  return Container(
  constraints: const BoxConstraints(minHeight: 241),
     decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
    padding: const EdgeInsets.all(16.0),
       child:  TextField(
          controller: _diasNotesController,
          focusNode: _diasNotesFocusNode,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter notes...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 22.0),
        ),
  );
}

  Widget _buildSettingsPage() {
  return FutureBuilder<List<CountryList>>(
    future: fetchCountryLists(),
    builder: (BuildContext context, AsyncSnapshot<List<CountryList>> snapshot) {
      if (snapshot.hasData) {
        List<CountryList> countryLists = snapshot.data!;
        return ListView.builder(
          itemCount: countryLists.length,
          itemBuilder: (BuildContext context, int index) {
            CountryList countryList = countryLists[index];
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
        return const Center(child: CircularProgressIndicator());
      }
    },
  );
}

  Widget _buildFullSpeakersList() {
    if (_speakersList.length > 12 && _currentMode == 'Speakers List'){
    List<Speaker> expandedSpeakersList = _speakersList.sublist(12);
    return Expanded(
      child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        child: ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: expandedSpeakersList.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CountryFlag.fromCountryCode(
                          expandedSpeakersList[index].country.name,
                          height: 24,
                          width: 32,
                          borderRadius: 5,
                        ),
          title: Text(expandedSpeakersList[index].country.code, textScaler: const TextScaler.linear(1),),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear, size: 33,),
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
      List<Speaker> expandedSpeakersList = _currentMod.sublist(12);
    return Expanded(
      child: Container(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        child: ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: expandedSpeakersList.length,
      itemBuilder: (context, index) {
        return ListTile(
         
          leading: CountryFlag.fromCountryCode(
                          expandedSpeakersList[index].country.name,
                          height: 24,
                          width: 32,
                          borderRadius: 5,
                        ),
          title: Text(expandedSpeakersList[index].country.code, textScaler: const TextScaler.linear(1),),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.clear, size: 33,),
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
      padding: const EdgeInsets.all(8.0),
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
     TextEditingController searchController = TextEditingController();
    List<Country> countries = await fetchCountriesForCountryList(_selectedCountryList!.id);
    List<Country> filteredCountries = countries;

  if (_selectedCountryList == null) {
    // No country list selected, show navigation button
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Country List Selected'),
          content: const Text('Please select a country list in the settings.'),
          actions: [
            TextButton(
              onPressed: () {
                _buildSettingsPage();
              },
              child: const Text('Go to Settings'),
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
            title: const Text('Add Speaker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Countries',
                    suffixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filteredCountries = countries
                          .where((country) => country.name.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 300.0, // Fixed height for the scrollable area
                  child: SingleChildScrollView(
                    child: Column(
                      children: filteredCountries.map((country) {
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

 void _preformMotionFunction(Motion selectedMotion){
  if (selectedMotion.type == "Mod"){
    runningModType = "Mod";
    _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setSpeakerTime(selectedMotion.speakingTime);
    _setCaucusTime(selectedMotion.caucusTime);
    _showSpeakerOrderDialog(selectedMotion);
  }
  else if (selectedMotion.type == "Unmod"){
    runningModType = "Unmod";
    _currentMode = 'Speakers List';
    _setSpeakerTime(selectedMotion.speakingTime);
    _setCaucusTime(selectedMotion.caucusTime);
  }
  else if (selectedMotion.type == "Seated Mod"){
    runningModType = "Seated Mod";
     _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setSpeakerTime(selectedMotion.speakingTime);
    _showSpeakerOrderDialog(selectedMotion);
    _setCaucusTime(selectedMotion.caucusTime);
  }
  else if (selectedMotion.type == "Open Speakers List"){
    runningModType = "Open Speakers List";
    _currentMode = 'Speakers List';
    if(isAuthorFirstOnSpeakersList){
    _showSpeakerOrderDialog(selectedMotion);
    }
  }
  else if (selectedMotion.type == "Round Robin"){
    runningModType = "Round Robin";
     _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setCaucusTime(selectedMotion.caucusTime);
    _setSpeakerTime(selectedMotion.speakingTime);
    _showSpeakerOrderDialog(selectedMotion);
  }
  else if (selectedMotion.type == "Introduce Working Papers"){

  }
  else if (selectedMotion.type == "Table Debate"){
    
  }
  else if (selectedMotion.type == "Enter voting procedure"){
    
  }
  else if (selectedMotion.type == "Supend Debate"){
    
  }
  else if (selectedMotion.type == "Consultation of the whole"){
    runningModType = "Consultation of the whole";
     _currentMod.clear();
    _currentMode = 'Moderated Cacus';
    _setCaucusTime(selectedMotion.caucusTime);
    _setSpeakerTime(selectedMotion.speakingTime);
    currentModSpeaker = Speaker(
                        name: selectedMotion.author.code,
                        country: selectedMotion.author,
                      );
  }
  else if (selectedMotion.type == "Adjourn Meeting"){
    
  }
  else {

  }
  runningMotion = selectedMotion;
  setState(() {
  });
 }

void _showSpeakerOrderDialog(Motion motion) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      bool speakFirst = false;
      bool speakLast = false;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Speaker Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Speak First'),
                  value: speakFirst,
                  onChanged: (value) {
                    setState(() {
                      speakFirst = value!;
                      speakLast = false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Speak Last'),
                  value: speakLast,
                  onChanged: (value) {
                    setState(() {
                      speakLast = value!;
                      speakFirst = false;
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (speakFirst) {
                    setState(() {
                      currentModSpeaker = Speaker(
                        name: motion.author.code,
                        country: motion.author,
                      );
                    });
                  } else if (speakLast) {
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
                child: const Text('OK'),
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
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Resolution Name',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _resolutionName = value;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                 Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isRollCallVote = true;
                        });
                      },
                      child: const Text('Roll Call'),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isRollCallVote = false;
                        });
                      },
                      child: const Text('Acclimation'),
                    ),
                  ],
                ),
              ],
            ),
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
    padding: const EdgeInsets.all(8),
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
              color: yesCount > 0 ? Colors.green : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                bottomLeft: Radius.circular(20.0),
                topRight: noCount == 0 && abstainCount == 0 ? Radius.circular(20.0) : Radius.zero,
                bottomRight: noCount == 0 && abstainCount == 0 ? Radius.circular(20.0) : Radius.zero,
              ),
            ),
          ),
        ),
        Expanded(
          flex: noCount,
          child: Container(
            decoration: BoxDecoration(
              color: noCount > 0 ? Colors.red : Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: yesCount == 0 ? Radius.circular(20.0) : Radius.zero,
                bottomLeft: yesCount == 0 ? Radius.circular(20.0) : Radius.zero,
                topRight: abstainCount == 0 ? Radius.circular(20.0) : Radius.zero,
                bottomRight: abstainCount == 0 ? Radius.circular(20.0) : Radius.zero,
              ),
            ),
          ),
        ),
        Expanded(
          flex: abstainCount,
          child: Container(
            decoration: BoxDecoration(
              color: abstainCount > 0 ? Colors.grey : Colors.transparent,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
                topLeft: noCount == 0 && yesCount == 0 ? Radius.circular(20.0) : Radius.zero,
                bottomLeft: noCount == 0 && yesCount == 0 ? Radius.circular(20.0) : Radius.zero,
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
      padding: const EdgeInsets.all(8.0),
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
                    ButtonSegment(value: 'Yes', label: const Text('Yes')),
                    ButtonSegment(value: 'No', label: const Text('No')),
                    ButtonSegment(value: 'Abstain', label: const Text('Abstain')),
                  ],
                  selectedIcon: const SizedBox(),
                  selected: {vote},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _votes[country.code] = selection.isEmpty ? '' : selection.first;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 2.0), 
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
        return const Color.fromARGB(255, 202, 182, 4).withOpacity(0.2);
      default:
        return Colors.transparent;
    }
  }

Widget _buildAddVoteMotion() {
  return Container(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Theme.of(context).colorScheme.primaryFixedDim,
                    ),
                  child: DropdownMenu<String>(
                    initialSelection: _voteMotionType,
                    requestFocusOnTap: true,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              
                              border: InputBorder.none,
                            ),
                    onSelected: (String? newValue) {
                      setState(() {
                        _voteMotionType = newValue!;
                      });
                    },
                    dropdownMenuEntries: <String>[
                      'Vote on by Acclimation',
                      'Vote on by Roll Call',
                      'Vote on by Placard',
                      'Division of the Question',
                      '2 for 2 against',
                      '1 for 1 against',
                      'Clause by clause voting',
                      'Voice Vote',
                    ].map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(
                        value: value,
                        label: value,
                      );
                    }).toList(),
                  ),
                ),
              ),
              Visibility(
                visible: _voteMotionType == 'Division of the Question',
                child: const SizedBox(width: 8,)
              ),
            Expanded(
              child: Visibility(
                visible: _voteMotionType == 'Division of the Question',
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).colorScheme.primaryFixedDim,
                    
                  ),
                  child: TextField(
                    controller: _clauseController,
                    decoration: const InputDecoration(
                      labelText: 'Clause',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Theme.of(context).primaryColor,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 35,),
                  color: Colors.white,
                  onPressed: () {
                    _saveVoteMotion();
                    print('Motion saved');
                  },
                ),
              ),
            ],
          ),
          TextField(
            controller: _resolutionTitleController,
            decoration: const InputDecoration(
              labelText: 'Resolution Title',
            ),
          ),
        ],
      ),
    ),
  );
}

 Future<void> _saveVoteMotion() async {
  String resolutionTitle = _resolutionTitleController.text;
  if (resolutionTitle.isNotEmpty) {
    try {
      Resolution resolution = Resolution(
        title: resolutionTitle,
        signatories: [],
      );
      String? clause = _voteMotionType == 'Division of the Question' ? _clauseController.text : null;
      await Supabase.instance.client.from('voting_motions').insert({
        'committee_id': widget.committee.id,
        'resolution': resolution.toJson(),
        'motion_type': _voteMotionType,
        'clause': clause,
      });
      setState(() {
        _selectedResolution = resolution;
        _resolutionTitleController.clear();
        _clauseController.clear();
      });
      // Perform the necessary actions based on the selected vote motion type
      _performVoteMotionFunction(VotingMotion(
        id: 0, // Placeholder value, will be assigned by the database
        committeeId: widget.committee.id,
        resolution: resolution,
        motionType: _voteMotionType,
        clause: clause,
      ));
    } catch (e) {
      // Handle any errors that occur during the database operation
      print('Error saving vote motion: $e');
    }
  }
}

  Future<void> _deleteVoteMotion(Motion deletedMotion) async{
    await Supabase.instance.client
        .from('motions').delete().eq('type', deletedMotion.type).eq('description', deletedMotion.description).eq('committee_id', widget.committee.id).eq("caucus_time", deletedMotion.caucusTime);
  }

  void _performVoteMotionFunction(VotingMotion votingMotion) {
  switch (votingMotion.motionType) {
    case 'Vote on by Acclimation':
      // Handle vote by acclimation
      break;
    case 'Vote on by Roll Call':
      // Handle vote by roll call
      break;
    case 'Vote on by Placard':
      // Handle vote by placard
      break;
    case 'Division of the Question':
      // Handle division of the question
      String? clause = votingMotion.clause;
      // Perform actions based on the clause
      break;
    case '2 for 2 against':
      // Handle 2 for 2 against
      break;
    case '1 for 1 against':
      // Handle 1 for 1 against
      break;
    case 'Clause by clause voting':
      // Handle clause by clause voting
      break;
    case 'Voice Vote':
      // Handle voice vote
      break;
    default:
      break;
  }
}
}





 