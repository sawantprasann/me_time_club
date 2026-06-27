import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../icons/app_icons.dart';

/// Data model for the user's profile.
class UserProfile {
  int? id;
  String? email;
  String? token;
  String? journeyStage;
  String name;
  List<String> phases;
  String? pregnancyMonth;
  int childCount;
  List<String> journey;
  String bio;
  List<String> hardships;
  String hardshipsText;
  Uint8List? photo;

  UserProfile({
    this.id,
    this.email,
    this.token,
    this.journeyStage,
    required this.name,
    this.phases = const [],
    this.pregnancyMonth,
    this.childCount = 0,
    this.journey = const [],
    this.bio = '',
    this.hardships = const [],
    this.hardshipsText = '',
    this.photo,
  });

  UserProfile copyWith({
    int? id,
    String? email,
    String? token,
    String? journeyStage,
    String? name,
    List<String>? phases,
    String? pregnancyMonth,
    int? childCount,
    List<String>? journey,
    String? bio,
    List<String>? hardships,
    String? hardshipsText,
    Uint8List? photo,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      token: token ?? this.token,
      journeyStage: journeyStage ?? this.journeyStage,
      name: name ?? this.name,
      phases: phases ?? this.phases,
      pregnancyMonth: pregnancyMonth ?? this.pregnancyMonth,
      childCount: childCount ?? this.childCount,
      journey: journey ?? this.journey,
      bio: bio ?? this.bio,
      hardships: hardships ?? this.hardships,
      hardshipsText: hardshipsText ?? this.hardshipsText,
      photo: photo ?? this.photo,
    );
  }

  /// Create a UserProfile from JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final phasesList = List<String>.from(json['phases'] ?? []);
    final journeyStage = json['journey_stage'] as String?;

    if (phasesList.isEmpty && journeyStage != null) {
      final stageToPhase = {
        'expecting_mom': 'expecting',
        'newborn_mom': 'newborn',
        'baby_mom': 'baby',
        'toddler_mom': 'toddler',
        'preschool_mom': 'preschool',
        'school_age_mom': 'school_age',
      };
      final mappedPhase = stageToPhase[journeyStage];
      if (mappedPhase != null) {
        phasesList.add(mappedPhase);
      }
    }

    return UserProfile(
      id: json['id'] as int?,
      email: json['email'] as String?,
      token: json['token'] as String?,
      journeyStage: journeyStage,
      name: json['name'] as String? ?? '',
      phases: phasesList,
      pregnancyMonth: json['pregnancyMonth'] as String?,
      childCount: json['childCount'] as int? ?? 0,
      journey: List<String>.from(json['journey'] ?? []),
      bio: json['bio'] as String? ?? '',
      hardships: List<String>.from(json['hardships'] ?? []),
      hardshipsText: json['hardshipsText'] as String? ?? '',
      photo:
          json['photo'] != null ? base64Decode(json['photo'] as String) : null,
    );
  }

  /// Convert UserProfile to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
      'journey_stage': journeyStage,
      'name': name,
      'phases': phases,
      'pregnancyMonth': pregnancyMonth,
      'childCount': childCount,
      'journey': journey,
      'bio': bio,
      'hardships': hardships,
      'hardshipsText': hardshipsText,
      'photo': photo != null ? base64Encode(photo!) : null,
    };
  }

  /// Human-readable label for phases
  String get phaseLabel => phases.isEmpty ? '' : phases.join(' · ');
}

/// Chamomile daily page content — all 9 fields.
class DailyPageContent {
  final String? id;
  final String openingThought;
  final String reflection;
  final String reflectionFollowup;
  final String emotionalFeeling;
  final String emotionalNeed;
  final String emotionalResponse;
  final String insight;
  final String microSkill;
  final String gentleRead;
  final String funMoment;
  final String nightReflection;

  const DailyPageContent({
    this.id,
    required this.openingThought,
    required this.reflection,
    required this.reflectionFollowup,
    required this.emotionalFeeling,
    required this.emotionalNeed,
    required this.emotionalResponse,
    required this.insight,
    required this.microSkill,
    required this.gentleRead,
    required this.funMoment,
    required this.nightReflection,
  });

  /// Create DailyPageContent from JSON map
  factory DailyPageContent.fromJson(Map<String, dynamic> json, {String? id}) {
    // Determine the root of the daily page data (handle potential 'data' wrapping)
    Map<String, dynamic> root = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      root = json['data'] as Map<String, dynamic>;
    }

    // Determine where the main content lies (handle potential 'content' wrapping)
    Map<String, dynamic> content = root;
    if (root.containsKey('content') &&
        root['content'] is Map<String, dynamic>) {
      content = root['content'] as Map<String, dynamic>;
    }

    // Determine emotional alignment fields (handle nested 'emotional_alignment' or flat fields)
    String feeling = '';
    String need = '';
    String responseVal = '';
    if (content.containsKey('emotional_alignment') &&
        content['emotional_alignment'] is Map<String, dynamic>) {
      final emotional = content['emotional_alignment'] as Map<String, dynamic>;
      feeling = emotional['feeling'] as String? ?? '';
      need = emotional['need'] as String? ?? '';
      responseVal = emotional['response'] as String? ?? '';
    } else {
      feeling = content['feeling'] as String? ?? '';
      need = content['need'] as String? ?? '';
      responseVal = content['response'] as String? ?? '';
    }

    final parsedId =
        id ??
        content['id']?.toString() ??
        root['id']?.toString() ??
        json['id']?.toString();

    return DailyPageContent(
      id: parsedId,
      openingThought: content['opening_thought'] as String? ?? '',
      reflection: content['reflection'] as String? ?? '',
      reflectionFollowup:
          content['reflection_followup'] as String? ??
          'Do you know what is behind this feeling?',
      emotionalFeeling: feeling,
      emotionalNeed: need,
      emotionalResponse: responseVal,
      insight: content['insight'] as String? ?? '',
      microSkill: content['micro_skill'] as String? ?? '',
      gentleRead: content['gentle_read'] as String? ?? '',
      funMoment: content['fun_moment'] as String? ?? '',
      nightReflection: content['night_reflection'] as String? ?? '',
    );
  }

  /// Convert DailyPageContent to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opening_thought': openingThought,
      'reflection': reflection,
      'reflection_followup': reflectionFollowup,
      'emotional_alignment': {
        'feeling': emotionalFeeling,
        'need': emotionalNeed,
        'response': emotionalResponse,
      },
      'insight': insight,
      'micro_skill': microSkill,
      'gentle_read': gentleRead,
      'fun_moment': funMoment,
      'night_reflection': nightReflection,
    };
  }
}

/// Phase label mapping
const Map<String, String> phaseLabels = {
  'expecting': 'Expecting',
  'newborn': 'Newborn (0-6m)',
  'baby': 'Baby (6-18m)',
  'toddler': 'Toddler (18m-3y)',
  'preschool': 'Preschool (3-5y)',
  'school_age': 'School Age (5+)',
};

/// Mood option data
class MoodOption {
  final String id;
  final String label;
  final Color color;
  final Widget Function({required Color c, double s}) icon;

  const MoodOption({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });
}

final List<MoodOption> moodOptions = [
  MoodOption(
    id: 'overwhelmed',
    label: 'Overwhelmed',
    color: const Color(0xFFB8706A),
    icon: ({required Color c, double s = 20}) => AppIcons.wave(c: c, s: s),
  ),
  MoodOption(
    id: 'sleep_deprived',
    label: 'Sleep-Deprived',
    color: const Color(0xFF8A7D76),
    icon: ({required Color c, double s = 20}) => AppIcons.moon(c: c, s: s),
  ),
  MoodOption(
    id: 'tender',
    label: 'Tender',
    color: const Color(0xFF7A9E8E),
    icon: ({required Color c, double s = 20}) => AppIcons.leaf(c: c, s: s),
  ),
  MoodOption(
    id: 'motivated',
    label: 'Motivated',
    color: const Color(0xFFC4945A),
    icon: ({required Color c, double s = 20}) => AppIcons.sun(c: c, s: s),
  ),
  MoodOption(
    id: 'anxious',
    label: 'Anxious',
    color: const Color(0xFF9E9E7A),
    icon: ({required Color c, double s = 20}) => AppIcons.wind(c: c, s: s),
  ),
  MoodOption(
    id: 'lonely',
    label: 'Lonely',
    color: const Color(0xFFA0887A),
    icon: ({required Color c, double s = 20}) => AppIcons.candle(c: c, s: s),
  ),
  MoodOption(
    id: 'grateful',
    label: 'Grateful',
    color: const Color(0xFFB8906A),
    icon: ({required Color c, double s = 20}) => AppIcons.bloom(c: c, s: s),
  ),
  MoodOption(
    id: 'stable',
    label: 'Stable',
    color: const Color(0xFF7A9E8E),
    icon: ({required Color c, double s = 20}) => AppIcons.wheat(c: c, s: s),
  ),
  MoodOption(
    id: 'just_here',
    label: 'Just Here',
    color: const Color(0xFF8A8078),
    icon: ({required Color c, double s = 20}) => AppIcons.cloud(c: c, s: s),
  ),
];
