import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/details/screens/details_view.dart';
import 'package:mongez/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/home/widgets/service_card.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class FavoiriteScreen extends StatelessWidget {
  FavoiriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: lang.favorites),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FavoritesSuccess && state.favorites.isEmpty) {
            return Center(child: Text(lang.noFavorites));
          }
          if (state is FavoritesFailure) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is FavoritesSuccess) {
            final favorites = state.favorites;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                final worker = fav.workerInfo;
                if (worker == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsView(
                            worker: worker,
                            isCustomer: true,
                          ),
                        ),
                      );
                    },
                    child: ServiceCard(
                      worker: worker,
                      isCustomer: true,
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
