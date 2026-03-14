import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/auth/auth.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthCubit>().clearError();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTheme().white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 48),
                Center(
                  child: Image.asset(
                    AppIcons.logo,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_shipping,
                      size: 80,
                      color: AppColorTheme().primary,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Welcome back',
                  style: AppTextTheme().headingText.copyWith(
                    color: AppColorTheme().black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTextTheme().bodyText.copyWith(
                    color: AppColorTheme().grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                BlocListener<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state.status == AuthStatus.authenticated) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
                  },
                  child: BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (a, b) =>
                        a.errorMessage != b.errorMessage ||
                        a.status != b.status,
                    builder: (context, state) {
                      final isLoading = state.status == AuthStatus.loading;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.errorMessage != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorTheme().whiteRed,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.errorMessage!,
                                style: AppTextTheme().bodyText.copyWith(
                                  color: AppColorTheme().red,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                          CustomTextfieldWidget(
                            controller: _emailController,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter email';
                              if (!RegExp(emailPattern).hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          CustomTextfieldWidget(
                            controller: _passwordController,
                            hintText: 'Password',
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter password';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          CustomButtonWidget(
                            title: 'Sign in',
                            isLoad: isLoading,
                            onPressed: _submit,
                          ),
                          SizedBox(height: 24),
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextTheme().bodyText.copyWith(
                                  color: AppColorTheme().grey,
                                ),
                                children: [
                                  TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Sign up',
                                    style: TextStyle(
                                      color: AppColorTheme().primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => SignUpScreen(),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
