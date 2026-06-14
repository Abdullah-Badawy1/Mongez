import 'package:bloc/bloc.dart';
import 'package:mongez/features/orders/data/models/order_model.dart';
import 'package:mongez/features/orders/domain/order_repository.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final OrderRepository orderRepository;

  CheckoutCubit({required this.orderRepository})
      : super(CheckoutInitial());

  void reset() => emit(CheckoutInitial());

  Future<void> createOrder({
    required int serviceCategory,
    required int workerId,
    required String description,
    String? address,
    String? phone,
    String? urgency,
    double? latitude,
    double? longitude,
    List<String> photoPaths = const [],
    String? audioPath,
    int? audioDurationSeconds,
  }) async {
    emit(CheckoutLoading());
    final result = await orderRepository.createOrder(
      serviceCategory: serviceCategory,
      workerId: workerId,
      description: description,
      address: address,
      phone: phone,
      urgency: urgency,
      latitude: latitude,
      longitude: longitude,
      photoPaths: photoPaths,
      audioPath: audioPath,
      audioDurationSeconds: audioDurationSeconds,
    );
    result.fold(
      (failure) => emit(CheckoutFailure(failure.errorMessage)),
      (order) => emit(CheckoutSuccess(order)),
    );
  }
}
