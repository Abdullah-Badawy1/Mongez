import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/bloc/favorites/favorites_cubit.dart';
import 'package:mongez/core/bloc/favorites/favorites_state.dart';
import 'package:mongez/core/models/favorite_model.dart';
import 'package:mongez/features/details/presentation/views/details_view.dart';
import 'package:mongez/features/home_feature/components/molecules/service_istem_ui.dart';
import 'package:mongez/features/home_feature/model/service_item/service_item.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/widgets/custom_app_bar.dart';

class FavoiriteScreen extends StatelessWidget {
  const FavoiriteScreen({super.key});

  ServiceItem _toServiceItem(FavoriteModel fav, S lang) => ServiceItem(
        title: fav.worker.profession,
        image: 'assets/images/E.png',
        cover: 'assets/images/EE.jpeg',
        workerImage: 'assets/images/person.png',
        description:
            '${fav.worker.profession} — ${fav.worker.experienceYears} years experience',
        comments: [lang.greatService, lang.veryProfessional],
        address: fav.worker.user.address.isNotEmpty
            ? fav.worker.user.address
            : lang.addressMainStreetCairo,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavoritesCubit()..loadFavorites(),
      child: Builder(builder: (context) {
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

              if (state is FavoritesError) {
                return Center(
                  child: Text(
                    state.message,
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }

              final favorites =
                  state is FavoritesLoaded ? state.favorites : <FavoriteModel>[];

              if (favorites.isEmpty) {
                return Center(child: Text(lang.favorites));
              }

              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final fav = favorites[index];
                        final service = _toServiceItem(fav, lang);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsView(
                                    item: service,
                                    isCustomer: true,
                                  ),
                                ),
                              );
                            },
                            child: ServiceCard(
                              service: service,
                              isCustomer: true,
                            ),
                          ),
                        );
                      },
                      childCount: favorites.length,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}
