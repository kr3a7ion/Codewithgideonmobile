import 'package:flutter_riverpod/legacy.dart';

enum ClassTab { upcoming, live, completed }

final classTabProvider = StateProvider<ClassTab>((ref) => ClassTab.upcoming);
final classSearchProvider = StateProvider<String>((ref) => '');
