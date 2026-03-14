import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ommo/auth/auth.dart';
import 'package:ommo/custom_widget/custom_widget.dart';
import 'package:ommo/utils/utils.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cdlLicenseController = TextEditingController();
  String? _employmentType;
  String? _licenseState;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileCubit>().loadProfile();
    });
  }

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
    _phoneController.dispose();
    _cdlLicenseController.dispose();
    super.dispose();
  }

  void _fillFromUser(UserModel? user) {
    if (user == null) return;
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phone ?? '';
    _cdlLicenseController.text = user.cdlLicenseNumber ?? '';
    setState(() {
      _employmentType = user.employmentType;
      _licenseState = user.licenseState;
    });
  }

  void _submitUpdate() {
    context.read<ProfileCubit>().clearError();
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<ProfileCubit>().state.user;
    if (user == null) return;
    final updated = user.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      employmentType: _employmentType,
      cdlLicenseNumber: _cdlLicenseController.text.trim(),
      licenseState: _licenseState,
    );
    context.read<ProfileCubit>().updateProfile(updated);
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
        title: Text(
          'My Profile',
          style: AppTextTheme().subHeadingText.copyWith(
                color: AppColorTheme().black,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.user != null) {
            _fillFromUser(state.user);
            if (state.status == ProfileStatus.loaded && _isEditing) {
              setState(() => _isEditing = false);
            }
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.user == null) {
            return Center(
              child: CircularProgressIndicator(color: AppColorTheme().primary),
            );
          }
          if (state.status == ProfileStatus.error && state.user == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.errorMessage ?? 'Failed to load profile',
                      textAlign: TextAlign.center,
                      style: AppTextTheme().bodyText.copyWith(
                            color: AppColorTheme().red,
                          ),
                    ),
                    SizedBox(height: 16),
                    CustomButtonWidget(
                      title: 'Retry',
                      onPressed: () =>
                          context.read<ProfileCubit>().loadProfile(),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = state.user;
          final isUpdating = state.status == ProfileStatus.updating;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16),
                  Center(
                    child: Image.asset(
                      AppIcons.logo,
                      width: 180,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 56,
                        color: AppColorTheme().primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (user != null && !_isEditing) ...[
                    _profileTile('First name', user.firstName),
                    _profileTile('Last name', user.lastName),
                    _profileTile('Email', user.email),
                    _profileTile('Phone', user.phone),
                    _profileTile('Employment type', user.employmentType),
                    _profileTile('CDL license number', user.cdlLicenseNumber),
                    _profileTile('License state', user.licenseState),
                    SizedBox(height: 24),
                    CustomButtonWidget(
                      title: 'Edit profile',
                      onPressed: () => setState(() => _isEditing = true),
                      bdColor: AppColorTheme().primary,
                      bgColor: AppColorTheme().white,
                      textColor: AppColorTheme().primary,
                    ),
                  ] else if (user != null) ...[
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
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter first name' : null,
                    ),
                    SizedBox(height: 16),
                    CustomTextfieldWidget(
                      controller: _lastNameController,
                      hintText: 'Last name',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter last name' : null,
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
                      controller: _phoneController,
                      hintText: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter phone' : null,
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
                      validator: (v) =>
                          (v == null || v.isEmpty)
                              ? 'Select employment type'
                              : null,
                    ),
                    SizedBox(height: 16),
                    CustomTextfieldWidget(
                      controller: _cdlLicenseController,
                      hintText: 'CDL license number',
                      validator: (v) =>
                          (v == null || v.isEmpty)
                              ? 'Enter CDL license number'
                              : null,
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
                      validator: (v) =>
                          (v == null || v.isEmpty)
                              ? 'Select license state'
                              : null,
                    ),
                    SizedBox(height: 24),
                    CustomButtonWidget(
                      title: 'Save',
                      isLoad: isUpdating,
                      onPressed: _submitUpdate,
                    ),
                    SizedBox(height: 12),
                    CustomButtonWidget(
                      title: 'Cancel',
                      onPressed: () => setState(() => _isEditing = false),
                      bgColor: AppColorTheme().whiteShade,
                      textColor: AppColorTheme().black,
                      bdColor: AppColorTheme().lightGrey,
                    ),
                  ],
                  SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileTile(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextTheme().lightText.copyWith(
                  color: AppColorTheme().grey,
                  fontSize: 12,
                ),
          ),
          SizedBox(height: 4),
          Text(
            value ?? '—',
            style: AppTextTheme().bodyText.copyWith(
                  color: AppColorTheme().black,
                ),
          ),
        ],
      ),
    );
  }
}
