import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/auth/auth.dart';
import 'package:ommo/utils/utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          _navigateToHome();
        } else if (state.status == AuthStatus.unauthenticated) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
        backgroundColor: AppColorTheme().white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppIcons.logo,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.local_shipping,
                    size: 120,
                    color: AppColorTheme().primary,
                  ),
                ),
                SizedBox(height: 48),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColorTheme().primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
