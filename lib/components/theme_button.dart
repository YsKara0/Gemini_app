import 'package:flutter/material.dart';


class MyThemeButton extends StatelessWidget {
  final Color? color;
  final void Function()? onTap;
  const MyThemeButton({super.key, required this.color, required this.onTap});
  


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.color_lens_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }


}