
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';


class Conference {
  final int id;
  final String name;
  final DateTime date;

  Conference({
    required this.id,
    required this.name,
    required this.date,
  });

  factory Conference.fromJson(Map<String, dynamic> json) {
    return Conference(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
    );
  }
}

class CountryList {
  final int id;
  final String name;
  final String userId;
  final bool forAll;

  CountryList({
    required this.id,
    required this.name,
    required this.userId,
    required this.forAll,
  });

  factory CountryList.fromJson(Map<String, dynamic> json) {
    return CountryList(
      id: json['id'] as int,
      name: json['name'] as String,
      userId: json['user_id'] as String,
      forAll: json['for_all'] as bool,
    );
  }
}

Future<List<CountryList>> fetchCountryLists() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  final response = await Supabase.instance.client
      .from('countrylists')
      .select('*')
      .or('user_id.eq.$userId,for_all.eq.true');

  return response.map((data) => CountryList.fromJson(data)).toList();
}

class Country {
  final String name;
  final String code;
  

  Country({required this.name, required this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['name'] as String,
      name: json['code'] as String,
    );
  }

   Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => name.hashCode ^ code.hashCode;

}

List<Country> parseCountries(String jsonString) {
  List<dynamic> jsonData = json.decode(jsonString);
  return jsonData.map((data) => Country.fromJson(data)).toList();
}

class Committee {
  final int id;
  final String name;
  final int conferenceId;

  Committee({
    required this.id,
    required this.name,
    required this.conferenceId,
  });

  factory Committee.fromJson(Map<String, dynamic> json) {
    return Committee(
      id: json['id'],
      name: json['name'],
      conferenceId: json['conference_id'],
    );
  }
}

class Speaker{
  final String name;
  final Country country;

  Speaker({
    required this.name,
    required this.country,
  });
}

Future<List<Country>> fetchCountriesForCountryList(int countryListId) async {

  final response = await Supabase.instance.client
      .from('countrylist_countries')
      .select()
      .eq('countrylist_id', countryListId);

    return response.map((data) => Country(code: data['country_code'], name: data['country_name'])).toList();
    
}

class Motion {
  final int id;
  final int committeeId;
  final String type;
  final String description;
  final String status;
  final int caucusTime;
  final int speakingTime;
  final Country author;

  Motion({
    required this.id,
    required this.committeeId,
    required this.type,
    required this.description,
    required this.status,
    required this.caucusTime,
    required this.speakingTime,
    required this.author,
  });

  factory Motion.fromMap(Map<String, dynamic> map) {
    return Motion(
      id: map['id'],
      committeeId: map['committee_id'],
      type: map['type'],
      description: map['description'],
      status: map['status'],
      caucusTime: map['caucus_time'],
      speakingTime: map['speaking_time'],
      author: Country.fromJson(map['created_by'])
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'committee_id': committeeId,
      'type': type,
      'description': description,
      'status': status,
      'caucus_time': caucusTime,
      'speaking_time': speakingTime,
      'created_by': author.toJson()
    };
  }
}
