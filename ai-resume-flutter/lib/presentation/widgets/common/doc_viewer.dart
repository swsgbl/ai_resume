import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/theme_config.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 文档查看器页面
///
/// 用于显示隐私政策、用户协议等文档
class DocViewerPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const DocViewerPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<DocViewerPage> createState() => _DocViewerPageState();
}

class _DocViewerPageState extends State<DocViewerPage> {
  bool _isLoading = true;
  String _content = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  /// 加载文档内容
  Future<void> _loadDocument() async {
    try {
      final content = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '文档加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.darkBg,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ThemeConfig.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: ThemeConfig.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: ThemeConfig.bodyMedium.copyWith(
                color: ThemeConfig.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: MarkdownBody(
        data: _content,
      ),
    );
  }
}
