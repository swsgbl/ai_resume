import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume.dart';

/// 基本信息编辑标签页
class BasicInfoTab extends StatefulWidget {
  final BasicInfo basicInfo;
  final ValueChanged<BasicInfo> onChanged;

  const BasicInfoTab({
    super.key,
    required this.basicInfo,
    required this.onChanged,
  });

  @override
  State<BasicInfoTab> createState() => _BasicInfoTabState();
}

class _BasicInfoTabState extends State<BasicInfoTab> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _jobIntentionController;
  late TextEditingController _selfIntroductionController;
  late TextEditingController _linkedinController;
  late TextEditingController _githubController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.basicInfo.name ?? '');
    _emailController = TextEditingController(text: widget.basicInfo.email ?? '');
    _phoneController = TextEditingController(text: widget.basicInfo.phone ?? '');
    _locationController = TextEditingController(text: widget.basicInfo.location ?? '');
    _titleController = TextEditingController(text: widget.basicInfo.title ?? '');
    _summaryController = TextEditingController(text: widget.basicInfo.summary ?? '');
    _jobIntentionController = TextEditingController(text: widget.basicInfo.jobIntention ?? '');
    _selfIntroductionController = TextEditingController(text: widget.basicInfo.selfIntroduction ?? '');
    _linkedinController = TextEditingController(text: widget.basicInfo.linkedin ?? '');
    _githubController = TextEditingController(text: widget.basicInfo.github ?? '');
    _websiteController = TextEditingController(text: widget.basicInfo.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _jobIntentionController.dispose();
    _selfIntroductionController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _updateField(String field, String value) {
    final updated = widget.basicInfo.copyWith();
    switch (field) {
      case 'name':
        widget.onChanged(updated.copyWith(name: value));
        break;
      case 'email':
        widget.onChanged(updated.copyWith(email: value));
        break;
      case 'phone':
        widget.onChanged(updated.copyWith(phone: value));
        break;
      case 'location':
        widget.onChanged(updated.copyWith(location: value));
        break;
      case 'title':
        widget.onChanged(updated.copyWith(title: value));
        break;
      case 'summary':
        widget.onChanged(updated.copyWith(summary: value));
        break;
      case 'jobIntention':
        widget.onChanged(updated.copyWith(jobIntention: value));
        break;
      case 'selfIntroduction':
        widget.onChanged(updated.copyWith(selfIntroduction: value));
        break;
      case 'linkedin':
        widget.onChanged(updated.copyWith(linkedin: value));
        break;
      case 'github':
        widget.onChanged(updated.copyWith(github: value));
        break;
      case 'website':
        widget.onChanged(updated.copyWith(website: value));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像上传区域
          _buildAvatarSection(),

          const SizedBox(height: 32),

          // 基本信息
          Text(
            '基本信息',
            style: ThemeConfig.heading3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInputField('姓名', _nameController, 'name', Icons.person_outline)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField('邮箱', _emailController, 'email', Icons.email_outlined, keyboardType: TextInputType.emailAddress)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInputField('手机号', _phoneController, 'phone', Icons.phone_outlined, keyboardType: TextInputType.phone)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField('所在城市', _locationController, 'location', Icons.location_on_outlined)),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputField('求职意向', _jobIntentionController, 'jobIntention', Icons.work_outline),

          const SizedBox(height: 32),

          // 职位和简介
          Text(
            '职业信息',
            style: ThemeConfig.heading3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          _buildInputField('职位/头衔', _titleController, 'title', Icons.badge_outlined),
          const SizedBox(height: 16),

          _buildTextarea('个人简介', _summaryController, 'summary', Icons.description_outlined,
            hint: '简要介绍你的专业背景和职业目标...'),

          const SizedBox(height: 32),

          // 自我介绍
          Text(
            '自我介绍',
            style: ThemeConfig.heading3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          _buildTextarea('自我介绍', _selfIntroductionController, 'selfIntroduction', Icons.chat_bubble_outline,
            hint: '详细描述你的个人特点、优势和职业规划...'),

          const SizedBox(height: 32),

          // 社交链接
          Text(
            '社交链接',
            style: ThemeConfig.heading3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          _buildInputField('LinkedIn', _linkedinController, 'linkedin', Icons.link, hint: 'https://linkedin.com/in/username'),
          const SizedBox(height: 16),

          _buildInputField('GitHub', _githubController, 'github', Icons.code, hint: 'https://github.com/username'),
          const SizedBox(height: 16),

          _buildInputField('个人网站', _websiteController, 'website', Icons.language, hint: 'https://yourwebsite.com'),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 头像上传区域
  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: 实现头像上传
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeConfig.primary.withOpacity(0.3),
                    ThemeConfig.accent.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: widget.basicInfo.avatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: Image.network(
                        widget.basicInfo.avatar!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white.withOpacity(0.5),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击上传头像',
            style: ThemeConfig.bodySmall.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  /// 输入框
  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String field,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) => _updateField(field, value),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? '请输入$label',
        prefixIcon: Icon(icon, color: ThemeConfig.textSecondary),
        labelStyle: const TextStyle(color: ThemeConfig.textSecondary),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
          borderSide: const BorderSide(color: ThemeConfig.primary, width: 2),
        ),
      ),
    );
  }

  /// 多行文本框
  Widget _buildTextarea(
    String label,
    TextEditingController controller,
    String field,
    IconData icon, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) => _updateField(field, value),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: ThemeConfig.textSecondary),
        labelStyle: const TextStyle(color: ThemeConfig.textSecondary),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.inputRadius),
          borderSide: const BorderSide(color: ThemeConfig.primary, width: 2),
        ),
      ),
    );
  }
}
