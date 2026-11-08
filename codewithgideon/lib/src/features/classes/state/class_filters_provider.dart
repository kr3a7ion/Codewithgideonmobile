import 'package:flutter_riverpod/legacy.dart';

enum ClassTab { classes, recordings, resources }

final classTabProvider = StateProvider<ClassTab>(
  (ref) => ClassTab.classes,
);
