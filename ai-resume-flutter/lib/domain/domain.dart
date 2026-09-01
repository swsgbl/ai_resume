/// Domain层导出文件
///
/// 提供统一的导出接口
library;

// Entities
export 'entities/user.dart';
export 'entities/resume.dart';
export 'entities/template.dart';
export 'entities/auth_result.dart';

// Repositories
export 'repositories/auth_repository.dart';
export 'repositories/resume_repository.dart';
export 'repositories/template_repository.dart';

// UseCases
export 'usecases/usecase.dart';
export 'usecases/auth/login.dart';
export 'usecases/auth/register.dart';
export 'usecases/auth/get_current_user.dart';
export 'usecases/resume/get_resumes.dart';
export 'usecases/template/get_templates.dart';
