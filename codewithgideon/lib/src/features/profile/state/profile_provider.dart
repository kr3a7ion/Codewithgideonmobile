import 'package:flutter_riverpod/legacy.dart';

import '../../../core/data/demo_data.dart';

class ProfileController extends StateNotifier<UserProfile> {
  ProfileController() : super(DemoData.userProfile);

  void update({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String bio,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      bio: bio,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileController, UserProfile>((
  ref,
) {
  return ProfileController();
});
