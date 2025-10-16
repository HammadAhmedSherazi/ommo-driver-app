import 'package:flutter/material.dart';
import 'package:ommo/data/response/get_data.dart';
import 'package:ommo/utils/theme/theme.dart';

class FutureDataBuilder<T> extends StatelessWidget {
  final FutureData<T>? future;
  final Widget Function(T? data) onSuccess;
  final Widget? loader;
  const FutureDataBuilder({
    super.key,
    required this.future,
    required this.onSuccess,
    this.loader,
  });

  @override
  Widget build(BuildContext context) => switch (future?.status) {
    Status.loading =>
      loader ??
          Center(
            child: CircularProgressIndicator(color: AppColorTheme().primary),
          ),
    Status.success => onSuccess(future?.data),
    Status.error => Center(
      child: Text(future?.message ?? "Oop's something went wrong"),
    ),
    Status.initial => const SizedBox(),
    _ => const SizedBox(),
  };
}
