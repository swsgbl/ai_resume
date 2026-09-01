import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume.dart';

/// 教育经历编辑标签页
class EducationTab extends StatefulWidget {
  final List<Education> education;
  final ValueChanged<List<Education>> onChanged;

  const EducationTab({
    super.key,
    required this.education,
    required this.onChanged,
  });

  @override
  State<EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<EducationTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.education.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: widget.education.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.education.length) {
          return _buildAddButton();
        }
        return _buildEducationCard(widget.education[index], index);
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有添加教育经历',
            style: ThemeConfig.heading3.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '添加你的教育背景，让简历更完整',
            style: ThemeConfig.bodyMedium.copyWith(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addEducation,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('添加教育经历'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 教育经历卡片
  Widget _buildEducationCard(Education education, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和删除按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  education.school.isEmpty ? '教育经历 ${index + 1}' : education.school,
                  style: ThemeConfig.heading3.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeEducation(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),

          // 表单字段
          _buildInputField(
            '学校名称',
            education.school,
            (value) => _updateEducation(index, 'school', value),
            Icons.school,
          ),
          const SizedBox(height: 16),

          _buildInputField(
            '学历',
            education.degree,
            (value) => _updateEducation(index, 'degree', value),
            Icons.workspace_premium,
          ),
          const SizedBox(height: 16),

          _buildInputField(
            '专业',
            education.major ?? '',
            (value) => _updateEducation(index, 'major', value),
            Icons.menu_book,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  '入学时间',
                  education.startDate ?? '',
                  (value) => _updateEducation(index, 'startDate', value),
                  Icons.event,
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  '毕业时间',
                  education.endDate ?? '',
                  (value) => _updateEducation(index, 'endDate', value),
                  Icons.event,
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputField(
            'GPA',
            education.gpa ?? '',
            (value) => _updateEducation(index, 'gpa', value),
            Icons.grade,
          ),
          const SizedBox(height: 16),

          _buildTextarea(
            '描述',
            education.description ?? '',
            (value) => _updateEducation(index, 'description', value),
          ),
        ],
      ),
    );
  }

  /// 添加按钮
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _addEducation,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加教育经历'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ThemeConfig.primary,
            side: BorderSide(color: ThemeConfig.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// 输入框
  Widget _buildInputField(
    String label,
    String value,
    ValueChanged<String> onChanged,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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
    String value,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: TextEditingController(text: value),
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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

  /// 添加教育经历
  void _addEducation() {
    final updated = List<Education>.from(widget.education);
    updated.add(Education.empty());
    widget.onChanged(updated);
  }

  /// 删除教育经历
  void _removeEducation(int index) {
    final updated = List<Education>.from(widget.education);
    updated.removeAt(index);
    widget.onChanged(updated);
  }

  /// 更新教育经历
  void _updateEducation(int index, String field, String value) {
    final updated = List<Education>.from(widget.education);
    final current = updated[index];
    switch (field) {
      case 'school':
        updated[index] = current.copyWith(school: value);
        break;
      case 'degree':
        updated[index] = current.copyWith(degree: value);
        break;
      case 'major':
        updated[index] = current.copyWith(major: value);
        break;
      case 'startDate':
        updated[index] = current.copyWith(startDate: value);
        break;
      case 'endDate':
        updated[index] = current.copyWith(endDate: value);
        break;
      case 'gpa':
        updated[index] = current.copyWith(gpa: value);
        break;
      case 'description':
        updated[index] = current.copyWith(description: value);
        break;
    }
    widget.onChanged(updated);
  }
}
