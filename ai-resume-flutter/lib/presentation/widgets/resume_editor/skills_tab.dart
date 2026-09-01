import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume.dart';

/// 技能特长编辑标签页
class SkillsTab extends StatefulWidget {
  final List<Skill> skills;
  final ValueChanged<List<Skill>> onChanged;

  const SkillsTab({
    super.key,
    required this.skills,
    required this.onChanged,
  });

  @override
  State<SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<SkillsTab> {
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _skillController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skills.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 添加技能区域
          _buildAddSkillSection(),
          const SizedBox(height: 32),

          // 技能列表
          Text(
            '已添加的技能',
            style: ThemeConfig.heading3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.skills.asMap().entries.map((entry) {
              final index = entry.key;
              final skill = entry.value;
              return _buildSkillChip(skill, index);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('还没有添加技能', style: ThemeConfig.heading3.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text('添加你的专业技能，突出你的核心竞争力', style: ThemeConfig.bodyMedium.copyWith(color: Colors.white60)),
          const SizedBox(height: 32),

          // 添加技能表单
          Container(
            padding: const EdgeInsets.all(24),
            decoration: ThemeConfig.glassDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('添加技能', style: ThemeConfig.heading3.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                _buildInputField('技能名称', _skillController, Icons.psychology),
                const SizedBox(height: 16),
                _buildInputField('分类（可选）', _categoryController, Icons.category),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addSkill,
                  child: const Text('添加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSkillSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('添加新技能', style: ThemeConfig.heading3.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField('技能名称', _skillController, Icons.psychology),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField('分类', _categoryController, Icons.category),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addSkill,
                child: const Text('添加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(Skill skill, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.primary.withOpacity(0.3),
            ThemeConfig.accent.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ThemeConfig.primary.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (skill.category != null) ...[
            Text(
              '${skill.category}: ',
              style: ThemeConfig.bodySmall.copyWith(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
          Text(
            skill.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _removeSkill(index),
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ThemeConfig.textSecondary, size: 20),
        labelStyle: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeConfig.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _addSkill() {
    final name = _skillController.text.trim();
    if (name.isEmpty) return;

    final category = _categoryController.text.trim();
    final updated = List<Skill>.from(widget.skills);
    updated.add(Skill(
      name: name,
      category: category.isEmpty ? null : category,
    ));
    widget.onChanged(updated);

    _skillController.clear();
    _categoryController.clear();
  }

  void _removeSkill(int index) {
    final updated = List<Skill>.from(widget.skills);
    updated.removeAt(index);
    widget.onChanged(updated);
  }
}
