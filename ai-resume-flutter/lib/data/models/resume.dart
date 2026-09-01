import 'package:json_annotation/json_annotation.dart';

part 'resume.g.dart';

/// 简历数据模型
@JsonSerializable()
class Resume {
  final int id;
  final String title;
  final ResumeContent content;
  final int status; // 0: 草稿, 1: 已发布, 2: 已归档
  final DateTime createdAt;
  final DateTime updatedAt;

  Resume({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) =>
      _$ResumeFromJson(json);

  Map<String, dynamic> toJson() => _$ResumeToJson(this);

  Resume copyWith({
    int? id,
    String? title,
    ResumeContent? content,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Resume(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 简历内容
@JsonSerializable()
class ResumeContent {
  final BasicInfo? basicInfo;
  final List<Education>? education;
  final List<WorkExperience>? workExperience;
  final List<Project>? projects;
  final List<Skill>? skills;

  ResumeContent({
    this.basicInfo,
    this.education,
    this.workExperience,
    this.projects,
    this.skills,
  });

  factory ResumeContent.fromJson(Map<String, dynamic> json) =>
      _$ResumeContentFromJson(json);

  Map<String, dynamic> toJson() => _$ResumeContentToJson(this);

  ResumeContent copyWith({
    BasicInfo? basicInfo,
    List<Education>? education,
    List<WorkExperience>? workExperience,
    List<Project>? projects,
    List<Skill>? skills,
  }) {
    return ResumeContent(
      basicInfo: this.basicInfo ?? basicInfo,
      education: this.education ?? education,
      workExperience: this.workExperience ?? workExperience,
      projects: this.projects ?? projects,
      skills: this.skills ?? skills,
    );
  }

  /// 创建空内容
  factory ResumeContent.empty() {
    return ResumeContent(
      basicInfo: BasicInfo.empty(),
      education: [],
      workExperience: [],
      projects: [],
      skills: [],
    );
  }
}

/// 基本信息
@JsonSerializable()
class BasicInfo {
  final String? name;
  final String? email;
  final String? phone;
  final String? location;
  final String? title;
  final String? summary;
  final String? jobIntention;
  final String? selfIntroduction;
  final String? avatar;
  final String? linkedin;
  final String? github;
  final String? website;

  BasicInfo({
    this.name,
    this.email,
    this.phone,
    this.location,
    this.title,
    this.summary,
    this.jobIntention,
    this.selfIntroduction,
    this.avatar,
    this.linkedin,
    this.github,
    this.website,
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) =>
      _$BasicInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BasicInfoToJson(this);

  BasicInfo copyWith({
    String? name,
    String? email,
    String? phone,
    String? location,
    String? title,
    String? summary,
    String? jobIntention,
    String? selfIntroduction,
    String? avatar,
    String? linkedin,
    String? github,
    String? website,
  }) {
    return BasicInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      jobIntention: jobIntention ?? this.jobIntention,
      selfIntroduction: selfIntroduction ?? this.selfIntroduction,
      avatar: avatar ?? this.avatar,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      website: website ?? this.website,
    );
  }

  /// 创建空基本信息
  factory BasicInfo.empty() {
    return BasicInfo();
  }

  /// 是否为空
  bool get isEmpty {
    return name == null &&
        email == null &&
        phone == null &&
        location == null &&
        title == null &&
        summary == null &&
        jobIntention == null &&
        selfIntroduction == null;
  }
}

/// 教育经历
@JsonSerializable()
class Education {
  final String school;
  final String degree;
  final String? major;
  final String? startDate;
  final String? endDate;
  final String? gpa;
  final String? description;

  Education({
    required this.school,
    required this.degree,
    this.major,
    this.startDate,
    this.endDate,
    this.gpa,
    this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) =>
      _$EducationFromJson(json);

  Map<String, dynamic> toJson() => _$EducationToJson(this);

  Education copyWith({
    String? school,
    String? degree,
    String? major,
    String? startDate,
    String? endDate,
    String? gpa,
    String? description,
  }) {
    return Education(
      school: school ?? this.school,
      degree: degree ?? this.degree,
      major: major ?? this.major,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gpa: gpa ?? this.gpa,
      description: description ?? this.description,
    );
  }

  /// 创建空教育经历
  factory Education.empty() {
    return Education(
      school: '',
      degree: '',
    );
  }
}

/// 工作经历
@JsonSerializable()
class WorkExperience {
  final String company;
  final String position;
  final String? startDate;
  final String? endDate;
  final bool? isCurrent;
  final String? location;
  final String? description;
  final List<String>? achievements;

  WorkExperience({
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.isCurrent,
    this.location,
    this.description,
    this.achievements,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) =>
      _$WorkExperienceFromJson(json);

  Map<String, dynamic> toJson() => _$WorkExperienceToJson(this);

  WorkExperience copyWith({
    String? company,
    String? position,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    String? location,
    String? description,
    List<String>? achievements,
  }) {
    return WorkExperience(
      company: company ?? this.company,
      position: position ?? this.position,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      location: location ?? this.location,
      description: description ?? this.description,
      achievements: achievements ?? this.achievements,
    );
  }

  /// 创建空工作经历
  factory WorkExperience.empty() {
    return WorkExperience(
      company: '',
      position: '',
    );
  }
}

/// 项目经历
@JsonSerializable()
class Project {
  final String name;
  final String? role;
  final String? startDate;
  final String? endDate;
  final String? description;
  final List<String>? techStack;
  final List<String>? highlights;
  final String? link;

  Project({
    required this.name,
    this.role,
    this.startDate,
    this.endDate,
    this.description,
    this.techStack,
    this.highlights,
    this.link,
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? name,
    String? role,
    String? startDate,
    String? endDate,
    String? description,
    List<String>? techStack,
    List<String>? highlights,
    String? link,
  }) {
    return Project(
      name: name ?? this.name,
      role: role ?? this.role,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      techStack: techStack ?? this.techStack,
      highlights: highlights ?? this.highlights,
      link: link ?? this.link,
    );
  }

  /// 创建空项目
  factory Project.empty() {
    return Project(name: '');
  }
}

/// 技能
@JsonSerializable()
class Skill {
  final String name;
  final String? category;
  final int? level;
  final List<String>? keywords;

  Skill({
    required this.name,
    this.category,
    this.level,
    this.keywords,
  });

  factory Skill.fromJson(Map<String, dynamic> json) =>
      _$SkillFromJson(json);

  Map<String, dynamic> toJson() => _$SkillToJson(this);

  Skill copyWith({
    String? name,
    String? category,
    int? level,
    List<String>? keywords,
  }) {
    return Skill(
      name: name ?? this.name,
      category: category ?? this.category,
      level: level ?? this.level,
      keywords: keywords ?? this.keywords,
    );
  }

  /// 创建空技能
  factory Skill.empty() {
    return Skill(name: '');
  }
}

/// 创建/更新简历请求
@JsonSerializable()
class ResumeRequest {
  final String title;
  final ResumeContent content;

  ResumeRequest({
    required this.title,
    required this.content,
  });

  factory ResumeRequest.fromJson(Map<String, dynamic> json) =>
      _$ResumeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ResumeRequestToJson(this);
}

/// AI生成简历请求
@JsonSerializable()
class AIGenerateRequest {
  final String targetPosition;

  AIGenerateRequest({
    required this.targetPosition,
  });

  factory AIGenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$AIGenerateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AIGenerateRequestToJson(this);
}
