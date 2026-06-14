part of 'profile_cubit.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileSuccess extends ProfileState {
  final ProfileModel profile;
  ProfileSuccess(this.profile);
}

class ProfileFailure extends ProfileState {
  final String errorMessage;
  ProfileFailure(this.errorMessage);
}
