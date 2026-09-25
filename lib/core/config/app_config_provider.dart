import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.resolve());
