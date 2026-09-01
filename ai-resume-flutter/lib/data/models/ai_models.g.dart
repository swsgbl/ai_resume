// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIGenerateRequest _$AIGenerateRequestFromJson(Map<String, dynamic> json) =>
    AIGenerateRequest(
      targetPosition: json['targetPosition'] as String,
      workYears: (json['workYears'] as num?)?.toInt(),
      industry: json['industry'] as String?,
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      expectedSalary: json['expectedSalary'] as String?,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$AIGenerateRequestToJson(AIGenerateRequest instance) =>
    <String, dynamic>{
      'targetPosition': instance.targetPosition,
      'workYears': instance.workYears,
      'industry': instance.industry,
      'skills': instance.skills,
      'expectedSalary': instance.expectedSalary,
      'location': instance.location,
    };

AIGenerateResponse _$AIGenerateResponseFromJson(Map<String, dynamic> json) =>
    AIGenerateResponse(
      content: ResumeContent.fromJson(json['content'] as Map<String, dynamic>),
      templateId: (json['templateId'] as num?)?.toInt(),
      duration: (json['duration'] as num).toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$AIGenerateResponseToJson(AIGenerateResponse instance) =>
    <String, dynamic>{
      'content': instance.content,
      'templateId': instance.templateId,
      'duration': instance.duration,
      'status': instance.status,
    };

AIOptimizeRequest _$AIOptimizeRequestFromJson(Map<String, dynamic> json) =>
    AIOptimizeRequest(
      content: json['content'] as String,
      type: $enumDecode(_$AIOptimizeTypeEnumMap, json['type']),
      targetPosition: json['targetPosition'] as String?,
    );

Map<String, dynamic> _$AIOptimizeRequestToJson(AIOptimizeRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'type': _$AIOptimizeTypeEnumMap[instance.type]!,
      'targetPosition': instance.targetPosition,
    };

const _$AIOptimizeTypeEnumMap = {
  AIOptimizeType.summary: 'summary',
  AIOptimizeType.workDescription: 'work_description',
  AIOptimizeType.projectDescription: 'project_description',
  AIOptimizeType.skills: 'skills',
  AIOptimizeType.selfIntroduction: 'self_introduction',
};

AIOptimizeResponse _$AIOptimizeResponseFromJson(Map<String, dynamic> json) =>
    AIOptimizeResponse(
      optimizedContent: json['optimizedContent'] as String,
      originalContent: json['originalContent'] as String,
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      score: (json['score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AIOptimizeResponseToJson(AIOptimizeResponse instance) =>
    <String, dynamic>{
      'optimizedContent': instance.optimizedContent,
      'originalContent': instance.originalContent,
      'suggestions': instance.suggestions,
      'score': instance.score,
    };

ResumeTemplate _$ResumeTemplateFromJson(Map<String, dynamic> json) =>
    ResumeTemplate(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      preview: json['preview'] as String,
      colorScheme: (json['colorScheme'] as num?)?.toInt(),
      isPro: json['isPro'] as bool? ?? false,
    );

Map<String, dynamic> _$ResumeTemplateToJson(ResumeTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'preview': instance.preview,
      'colorScheme': instance.colorScheme,
      'isPro': instance.isPro,
    };
