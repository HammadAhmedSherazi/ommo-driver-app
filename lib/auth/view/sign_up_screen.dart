import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/auth/auth.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/utils/utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cdlLicenseController = TextEditingController();
  String? _employmentType;
  String? _licenseState;

  static const List<String> employmentTypes = [
    'Company Driver',
    'Owner Operator',
    'Lease Operator',
    'Other',
  ];

  static const List<String> licenseStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cdlLicenseController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthCubit>().clearError();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          employmentType: _employmentType!,
          cdlLicenseNumber: _cdlLicenseController.text.trim(),
          licenseState: _licenseState!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorTheme().white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColorTheme().black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                  AppIcons.logo,
                   width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_shipping,
                      size: 56,
                      color: AppColorTheme().primary,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Create account',
                  style: AppTextTheme().headingText.copyWith(
                        color: AppColorTheme().black,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: AppTextTheme().bodyText.copyWith(
                        color: AppColorTheme().grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                BlocListener<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state.status == AuthStatus.authenticated) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
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
                                  vertical: 12, horizontal: 16),
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
                            controller: _firstNameController,
                            hintText: 'First name',
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter first name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          CustomTextfieldWidget(
                            controller: _lastNameController,
                            hintText: 'Last name',
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter last name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
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
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter password';
                              }
                              if (v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          CustomTextfieldWidget(
                            controller: _phoneController,
                            hintText: 'Phone',
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter phone';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _employmentType,
                            decoration: InputDecoration(
                              hintText: 'Employment type',
                              filled: true,
                              fillColor: AppColorTheme().whiteShade,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: employmentTypes
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _employmentType = v),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Select employment type';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          CustomTextfieldWidget(
                            controller: _cdlLicenseController,
                            hintText: 'CDL license number',
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter CDL license number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _licenseState,
                            decoration: InputDecoration(
                              hintText: 'License state',
                              filled: true,
                              fillColor: AppColorTheme().whiteShade,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: licenseStates
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _licenseState = v),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Select license state';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 32),
                          CustomButtonWidget(
                            title: 'Sign up',
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
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      color: AppColorTheme().primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => LoginScreen(),
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
