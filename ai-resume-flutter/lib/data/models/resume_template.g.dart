// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResumeTemplate _$ResumeTemplateFromJson(Map<String, dynamic> json) =>
    ResumeTemplate(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      preview: json['preview'] as String,
      colorScheme: (json['colorScheme'] as num?)?.toInt(),
      isPro: json['isPro'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
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
      'tags': instance.tags,
      'usageCount': instance.usageCount,
    };

ApplyTemplateRequest _$ApplyTemplateRequestFromJson(
  Map<String, dynamic> json,
) => ApplyTemplateRequest(
  templateId: (json['templateId'] as num).toInt(),
  resumeId: (json['resumeId'] as num).toInt(),
);

Map<String, dynamic> _$ApplyTemplateRequestToJson(
  ApplyTemplateRequest instance,
) => <String, dynamic>{
  'templateId': instance.templateId,
  'resumeId': instance.resumeId,
};
