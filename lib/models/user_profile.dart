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
  String preBabyLetter;
  String futureSelfLetter;

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
    this.preBabyLetter = '',
    this.futureSelfLetter = '',
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
    String? preBabyLetter,
    String? futureSelfLetter,
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
      preBabyLetter: preBabyLetter ?? this.preBabyLetter,
      futureSelfLetter: futureSelfLetter ?? this.futureSelfLetter,
    );
  }

  /// Create a UserProfile from JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final phasesList = List<String>.from(json['phases'] ?? []);
    final primaryPhase = json['primary_phase'] as String?;
    if (phasesList.isEmpty && primaryPhase != null) {
      phasesList.add(primaryPhase);
    }

    final journeyStage = json['journey_stage'] as String?;
    if (phasesList.isEmpty && journeyStage != null) {
      final stageToPhase = {
        'expecting_mom': 'expecting',
        'expecting': 'expecting',
        'newborn_mom': 'newborn',
        'newborn': 'newborn',
        'baby_mom': 'baby',
        'baby': 'baby',
        'toddler_mom': 'toddler',
        'toddler': 'toddler',
        'preschool_mom': 'preschool',
        'preschool': 'preschool',
        'school_age_mom': 'school_age',
        'school_age': 'school_age',
      };
      final mappedPhase = stageToPhase[journeyStage];
      if (mappedPhase != null) {
        phasesList.add(mappedPhase);
      }
    }

    // Map hardships from api snake_case to human-readable
    final rawHardships = List<String>.from(json['hardships'] ?? []);
    final mappedHardships = rawHardships.map((h) {
      return apiToHardship[h] ?? h;
    }).toList();

    // Map journey tags from api snake_case to human-readable
    final rawJourney = List<String>.from(json['journey_tags'] ?? json['journey'] ?? []);
    final mappedJourney = rawJourney.map((j) {
      return apiToJourney[j] ?? j;
    }).toList();

    return UserProfile(
      id: json['id'] as int?,
      email: json['email'] as String?,
      token: json['token'] as String?,
      journeyStage: journeyStage,
      name: json['name'] as String? ?? json['display_name'] as String? ?? '',
      phases: phasesList,
      pregnancyMonth:
          json['pregnancy_week'] as String? ??
          json['pregnancyMonth'] as String?,
      childCount:
          json['child_count'] as int? ?? json['childCount'] as int? ?? 0,
      journey: mappedJourney,
      bio: json['bio'] as String? ?? '',
      hardships: mappedHardships,
      hardshipsText:
          json['hardships_text'] as String? ??
          json['hardshipsText'] as String? ??
          '',
      photo:
          json['photo'] != null ? base64Decode(json['photo'] as String) : null,
      preBabyLetter: json['pre_baby_letter'] as String? ?? '',
      futureSelfLetter: json['future_self_letter'] as String? ?? '',
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
      'pre_baby_letter': preBabyLetter,
      'future_self_letter': futureSelfLetter,
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
  // User-written answers (saved back to server via POST /api/v1/daily_pages)
  final String reflectionAnswer;
  final String reflectionFollowupAnswer;
  final String nightReflectionAnswer;

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
    this.reflectionAnswer = '',
    this.reflectionFollowupAnswer = '',
    this.nightReflectionAnswer = '',
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
      reflectionAnswer: content['reflection_answer'] as String? ?? '',
      reflectionFollowupAnswer: content['reflection_followup_answer'] as String? ?? '',
      nightReflectionAnswer: content['night_reflection_answer'] as String? ?? '',
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
      'reflection_answer': reflectionAnswer,
      'reflection_followup_answer': reflectionFollowupAnswer,
      'night_reflection_answer': nightReflectionAnswer,
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

const Map<String, String> hardshipToApi = {
  'Overwhelm': 'overwhelm',
  'Loneliness': 'loneliness',
  'Sleep exhaustion': 'sleep_deprivation',
  'Burnout': 'burnout',
  'Mom guilt': 'mom_guilt',
  'Identity loss': 'identity_loss',
  'Mental load': 'mental_load',
  'Need calm': 'need_calm',
  'Finding time for myself': 'finding_time_for_myself',
};

const Map<String, String> apiToHardship = {
  'overwhelm': 'Overwhelm',
  'loneliness': 'Loneliness',
  'sleep_deprivation': 'Sleep exhaustion',
  'burnout': 'Burnout',
  'mom_guilt': 'Mom guilt',
  'identity_loss': 'Identity loss',
  'mental_load': 'Mental load',
  'need_calm': 'Need calm',
  'finding_time_for_myself': 'Finding time for myself',
};

const Map<String, String> journeyToApi = {
  'First-time mother': 'first_time_mother',
  'Second-time mother': 'second_time_mother',
  'Third time (or more)': 'third_time_or_more',
  'Single mother': 'single_mother',
  'Single father': 'single_father',
  'Co-parenting': 'co_parenting',
  'Working mother': 'working_mother',
  'Stay-at-home mother': 'stay_at_home_mother',
  'IVF / fertility journey': 'ivf_fertility_journey',
  'Loss and healing': 'loss_and_healing',
  'Adoptive parent': 'adoptive_parent',
  'Neurodivergent child': 'neurodivergent_child',
  'Postpartum recovery': 'postpartum_recovery',
  'Blended family': 'blended_family',
};

const Map<String, String> apiToJourney = {
  'first_time_mother': 'First-time mother',
  'second_time_mother': 'Second-time mother',
  'third_time_or_more': 'Third time (or more)',
  'single_mother': 'Single mother',
  'single_father': 'Single father',
  'co_parenting': 'Co-parenting',
  'working_mother': 'Working mother',
  'stay_at_home_mother': 'Stay-at-home mother',
  'ivf_fertility_journey': 'IVF / fertility journey',
  'loss_and_healing': 'Loss and healing',
  'adoptive_parent': 'Adoptive parent',
  'neurodivergent_child': 'Neurodivergent child',
  'postpartum_recovery': 'Postpartum recovery',
  'blended_family': 'Blended family',
};
