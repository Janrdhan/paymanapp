import 'package:flutter/material.dart';
import 'package:paymanapp/screens/Core/app_colors.dart';
import 'package:paymanapp/screens/Core/offer_model.dart';

Widget offerPill(OfferModel o) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: o.bg,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        Icon(o.icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(o.text),
      ],
    ),
  );
}
