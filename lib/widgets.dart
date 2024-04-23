import 'package:flutter/material.dart';

class BottomBorderInputField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  const BottomBorderInputField(
      {super.key, required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: title,
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 9),
          ),
        ),
      ),
    );
  }
}

class CustomePrimaryButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final Function()? press;
  final bool isWithOnlyBorder;
  const CustomePrimaryButton({
    super.key,
    required this.title,
    required this.press,
    required this.isWithOnlyBorder,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        width: double.infinity,
        height: 55.0,
        decoration: BoxDecoration(
          color: isWithOnlyBorder ? null : Colors.blue,
          border: Border.all(width: 2, color: Colors.blue),
          borderRadius: const BorderRadius.all(
            (Radius.circular(5)),
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white,
            ),
          )
              : Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWithOnlyBorder
                  ? const Color.fromARGB(255, 78, 78, 78)
                  : const Color.fromARGB(255, 247, 247, 247),
            ),
          ),
        ),
      ),
    );
  }
}