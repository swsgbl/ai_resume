import 'package:flutter/material.dart';
import '../../../core/config/theme_config.dart';
import '../../../data/models/resume.dart';

/// 项目经历编辑标签页
class ProjectTab extends StatefulWidget {
  final List<Project> projects;
  final ValueChanged<List<Project>> onChanged;

  const ProjectTab({
    super.key,
    required this.projects,
    required this.onChanged,
  });

  @override
  State<ProjectTab> createState() => _ProjectTabState();
}

class _ProjectTabState extends State<ProjectTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: widget.projects.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.projects.length) {
          return _buildAddButton();
        }
        return _buildProjectCard(widget.projects[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text('还没有添加项目经历', style: ThemeConfig.heading3.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text('添加你的项目经验，展示你的技术能力', style: ThemeConfig.bodyMedium.copyWith(color: Colors.white60)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addProject,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('添加项目经历'),
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

  Widget _buildProjectCard(Project project, int index) {
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
                  project.name.isEmpty ? '项目 ${index + 1}' : project.name,
                  style: ThemeConfig.heading3.copyWith(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () => _removeProject(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),

          _buildInputField('项目名称', project.name, (v) => _updateProject(index, 'name', v), Icons.science),
          const SizedBox(height: 16),

          _buildInputField('担任角色', project.role ?? '', (v) => _updateProject(index, 'role', v), Icons.person),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildInputField('开始时间', project.startDate ?? '', (v) => _updateProject(index, 'startDate', v), Icons.event)),
              const SizedBox(width: 16),
              Expanded(child: _buildInputField('结束时间', project.endDate ?? '', (v) => _updateProject(index, 'endDate', v), Icons.event)),
            ],
          ),
          const SizedBox(height: 16),

          _buildTextarea('项目描述', project.description ?? '', (v) => _updateProject(index, 'description', v)),
          const SizedBox(height: 16),

          _buildInputField('项目链接', project.link ?? '', (v) => _updateProject(index, 'link', v), Icons.link),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _addProject,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('添加项目经历'),
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

  void _addProject() {
    final updated = List<Project>.from(widget.projects);
    updated.add(Project.empty());
    widget.onChanged(updated);
  }

  void _removeProject(int index) {
    final updated = List<Project>.from(widget.projects);
    updated.removeAt(index);
    widget.onChanged(updated);
  }

  void _updateProject(int index, String field, String value) {
    final updated = List<Project>.from(widget.projects);
    final current = updated[index];
    switch (field) {
      case 'name':
        updated[index] = current.copyWith(name: value);
        break;
      case 'role':
        updated[index] = current.copyWith(role: value);
        break;
      case 'startDate':
        updated[index] = current.copyWith(startDate: value);
        break;
      case 'endDate':
        updated[index] = current.copyWith(endDate: value);
        break;
      case 'description':
        updated[index] = current.copyWith(description: value);
        break;
      case 'link':
        updated[index] = current.copyWith(link: value);
        break;
    }
    widget.onChanged(updated);
  }
}
