import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume.dart';

/// 工作经历编辑标签页
class WorkExperienceTab extends StatefulWidget {
  final List<WorkExperience> workExperience;
  final ValueChanged<List<WorkExperience>> onChanged;

  const WorkExperienceTab({
    super.key,
    required this.workExperience,
    required this.onChanged,
  });

  @override
  State<WorkExperienceTab> createState() => _WorkExperienceTabState();
}

class _WorkExperienceTabState extends State<WorkExperienceTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.workExperience.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: widget.workExperience.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.workExperience.length) {
          return _buildAddButton();
        }
        return _buildWorkCard(widget.workExperience[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('还没有添加工作经历', style: ThemeConfig.heading3.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text('添加你的工作经历，展示你的职业成长', style: ThemeConfig.bodyMedium.copyWith(color: Colors.white60)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addWork,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('添加工作经历'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkCard(WorkExperience work, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  work.company.isEmpty ? '工作经历 ${index + 1}' : work.company,
                  style: ThemeConfig.heading3.copyWith(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () => _removeWork(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),

          _buildInputField('公司名称', work.company, (v) => _updateWork(index, 'company', v), Icons.business),
          const SizedBox(height: 16),

          _buildInputField('职位', work.position, (v) => _updateWork(index, 'position', v), Icons.badge),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInputField('开始时间', work.startDate ?? '', (v) => _updateWork(index, 'startDate', v), Icons.event)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField('结束时间', work.endDate ?? '', (v) => _updateWork(index, 'endDate', v), Icons.event)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Checkbox(
                value: work.isCurrent ?? false,
                onChanged: (v) => _updateWork(index, 'isCurrent', v.toString()),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return ThemeConfig.primary;
                  return Colors.white.withOpacity(0.1);
                }),
              ),
              const Text('至今', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),

          _buildInputField('工作地点', work.location ?? '', (v) => _updateWork(index, 'location', v), Icons.location_on),
          const SizedBox(height: 16),

          _buildTextarea('工作描述', work.description ?? '', (v) => _updateWork(index, 'description', v)),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _addWork,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加工作经历'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ThemeConfig.primary,
            side: BorderSide(color: ThemeConfig.primary),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String value, ValueChanged<String> onChanged, IconData icon) {
    return TextField(
      controller: TextEditingController(text: value),
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: ThemeConfig.textSecondary),
        labelStyle: const TextStyle(color: ThemeConfig.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeConfig.primary, width: 2)),
      ),
    );
  }

  Widget _buildTextarea(String label, String value, ValueChanged<String> onChanged) {
    return TextField(
      controller: TextEditingController(text: value),
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ThemeConfig.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeConfig.primary, width: 2)),
      ),
    );
  }

  void _addWork() {
    final updated = List<WorkExperience>.from(widget.workExperience);
    updated.add(WorkExperience.empty());
    widget.onChanged(updated);
  }

  void _removeWork(int index) {
    final updated = List<WorkExperience>.from(widget.workExperience);
    updated.removeAt(index);
    widget.onChanged(updated);
  }

  void _updateWork(int index, String field, String value) {
    final updated = List<WorkExperience>.from(widget.workExperience);
    final current = updated[index];
    switch (field) {
      case 'company':
        updated[index] = current.copyWith(company: value);
        break;
      case 'position':
        updated[index] = current.copyWith(position: value);
        break;
      case 'startDate':
        updated[index] = current.copyWith(startDate: value);
        break;
      case 'endDate':
        updated[index] = current.copyWith(endDate: value);
        break;
      case 'isCurrent':
        updated[index] = current.copyWith(isCurrent: value == 'true');
        break;
      case 'location':
        updated[index] = current.copyWith(location: value);
        break;
      case 'description':
        updated[index] = current.copyWith(description: value);
        break;
    }
    widget.onChanged(updated);
  }
}
