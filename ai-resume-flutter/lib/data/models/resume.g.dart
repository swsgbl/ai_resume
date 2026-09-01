// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Resume _$ResumeFromJson(Map<String, dynamic> json) => Resume(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  content: ResumeContent.fromJson(json['content'] as Map<String, dynamic>),
  status: (json['status'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ResumeToJson(Resume instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

ResumeContent _$ResumeContentFromJson(Map<String, dynamic> json) =>
    ResumeContent(
      basicInfo: json['basicInfo'] == null
          ? null
          : BasicInfo.fromJson(json['basicInfo'] as Map<String, dynamic>),
      education: (json['education'] as List<dynamic>?)
          ?.map((e) => Education.fromJson(e as Map<String, dynamic>))
          .toList(),
      workExperience: (json['workExperience'] as List<dynamic>?)
          ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
          .toList(),
      projects: (json['projects'] as List<dynamic>?)
          ?.map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>?)
          ?.map((e) => Skill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ResumeContentToJson(ResumeContent instance) =>
    <String, dynamic>{
      'basicInfo': instance.basicInfo,
      'education': instance.education,
      'workExperience': instance.workExperience,
      'projects': instance.projects,
      'skills': instance.skills,
    };

BasicInfo _$BasicInfoFromJson(Map<String, dynamic> json) => BasicInfo(
  name: json['name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  location: json['location'] as String?,
  title: json['title'] as String?,
  summary: json['summary'] as String?,
  jobIntention: json['jobIntention'] as String?,
  selfIntroduction: json['selfIntroduction'] as String?,
  avatar: json['avatar'] as String?,
  linkedin: json['linkedin'] as String?,
  github: json['github'] as String?,
  website: json['website'] as String?,
);

Map<String, dynamic> _$BasicInfoToJson(BasicInfo instance) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'location': instance.location,
  'title': instance.title,
  'summary': instance.summary,
  'jobIntention': instance.jobIntention,
  'selfIntroduction': instance.selfIntroduction,
  'avatar': instance.avatar,
  'linkedin': instance.linkedin,
  'github': instance.github,
  'website': instance.website,
};

Education _$EducationFromJson(Map<String, dynamic> json) => Education(
  school: json['school'] as String,
  degree: json['degree'] as String,
  major: json['major'] as String?,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  gpa: json['gpa'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$EducationToJson(Education instance) => <String, dynamic>{
  'school': instance.school,
  'degree': instance.degree,
  'major': instance.major,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'gpa': instance.gpa,
  'description': instance.description,
};

WorkExperience _$WorkExperienceFromJson(Map<String, dynamic> json) =>
    WorkExperience(
      company: json['company'] as String,
      position: json['position'] as String,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isCurrent: json['isCurrent'] as bool?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      achievements: (json['achievements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$WorkExperienceToJson(WorkExperience instance) =>
    <String, dynamic>{
      'company': instance.company,
      'position': instance.position,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'isCurrent': instance.isCurrent,
      'location': instance.location,
      'description': instance.description,
      'achievements': instance.achievements,
    };

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  name: json['name'] as String,
  role: json['role'] as String?,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  description: json['description'] as String?,
  techStack: (json['techStack'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  highlights: (json['highlights'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  link: json['link'] as String?,
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'name': instance.name,
  'role': instance.role,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'description': instance.description,
  'techStack': instance.techStack,
  'highlights': instance.highlights,
  'link': instance.link,
};

Skill _$SkillFromJson(Map<String, dynamic> json) => Skill(
  name: json['name'] as String,
  category: json['category'] as String?,
  level: (json['level'] as num?)?.toInt(),
  keywords: (json['keywords'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SkillToJson(Skill instance) => <String, dynamic>{
  'name': instance.name,
  'category': instance.category,
  'level': instance.level,
  'keywords': instance.keywords,
};

ResumeRequest _$ResumeRequestFromJson(Map<String, dynamic> json) =>
    ResumeRequest(
      title: json['title'] as String,
      content: ResumeContent.fromJson(json['content'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResumeRequestToJson(ResumeRequest instance) =>
    <String, dynamic>{'title': instance.title, 'content': instance.content};

AIGenerateRequest _$AIGenerateRequestFromJson(Map<String, dynamic> json) =>
    AIGenerateRequest(targetPosition: json['targetPosition'] as String);

Map<String, dynamic> _$AIGenerateRequestToJson(AIGenerateRequest instance) =>
    <String, dynamic>{'targetPosition': instance.targetPosition};
