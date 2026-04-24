import 'package:flutter/material.dart';
import 'package:mongez/features/home_feature/components/molecules/custom_category.dart';
import 'package:mongez/features/home_feature/model/category_model/datum.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key, required this.categories});

  final List<Categories> categories;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: width * 0.22, // 👈 زودناها سنة بسيطة علشان الشكل
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (_, index) {
            return index == 0
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(start: 18),
                    child: CustomCategory(category: categories[index]),
                  )
                : CustomCategory(category: categories[index]);
          },
        ),
      ),
    );
  }
}
