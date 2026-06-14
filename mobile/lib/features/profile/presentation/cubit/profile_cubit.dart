import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:mongez/features/profile/data/models/profile_model.dart';
import 'package:mongez/features/profile/domain/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository profileRepository;

  ProfileCubit({required this.profileRepository})
      : super(ProfileInitial());

  Future<void> getProfile() async {
    emit(ProfileLoading());
    final result = await profileRepository.getProfile();
    result.fold(
      (failure) => emit(ProfileFailure(failure.errorMessage)),
      (profile) => emit(ProfileSuccess(profile)),
    );
  }

  void reset() => emit(ProfileInitial());

  Future<void> updateProfile({
    String? username,
    String? phone,
    String? address,
    Uint8List? profileImageBytes,
  }) async {
    emit(ProfileLoading());
    final result = await profileRepository.updateProfile(
      username: username,
      phone: phone,
      address: address,
      profileImageBytes: profileImageBytes,
    );
    result.fold(
      (failure) => emit(ProfileFailure(failure.errorMessage)),
      (profile) => emit(ProfileSuccess(profile)),
    );
  }
}
