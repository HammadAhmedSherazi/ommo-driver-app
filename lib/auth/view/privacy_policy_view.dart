import 'package:flutter/material.dart';
import 'package:ommo/utils/theme/theme.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTheme();
    final text = AppTextTheme();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Ommo Tech\nDriver App — Privacy Policy',
          textAlign: TextAlign.center,
          style: text.subHeadingText?.copyWith(color: colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effective Date: April 1, 2025',
              style: text.lightText.copyWith(color: colors.grey),
            ),
            const SizedBox(height: 16),
            _PolicyParagraph(
              'This Privacy Policy describes how Ommo Tech ("we," "our," or "us") collects, uses, and protects the personal information of drivers ("you" or "user") who use the Driver mobile application (the "App"). By registering for and using the App, you agree to the terms of this Privacy Policy.',
            ),
            const SizedBox(height: 8),
            _PolicySection(
              title: '1. Information We Collect',
              children: [
                _PolicySubheading('1.1 Information You Provide'),
                _PolicyBullets(const [
                  'Full legal name',
                  'Phone number',
                  'Email address',
                  "Driver's license number and expiration date",
                  'Vehicle information (make, model, year, license plate)',
                  'Profile photo',
                ]),
                const SizedBox(height: 12),
                _PolicySubheading('1.2 Information Collected Automatically'),
                _PolicyBullets(const [
                  'GPS location data while the App is in use',
                  'Device information (device type, operating system, unique device identifiers)',
                  'App usage data and activity logs',
                  'IP address',
                ]),
                const SizedBox(height: 12),
                _PolicySubheading('1.3 SMS and Communications'),
                _PolicyParagraph(
                  'We collect your phone number to send one-time verification codes (OTPs) via SMS for account registration and login authentication. You provide consent to receive these messages by entering your phone number in the Driver App during registration. These messages are transactional and required for account security. Standard message and data rates may apply.',
                ),
              ],
            ),
            _PolicySection(
              title: '2. How We Use Your Information',
              children: [
                _PolicyParagraph(
                  'We use the information we collect for the following purposes:',
                ),
                const SizedBox(height: 8),
                _PolicyBullets(const [
                  'To verify your identity and authenticate your account via SMS verification codes',
                  'To create and manage your driver account',
                  'To process payments and calculate earnings',
                  'To match you with delivery or transportation jobs',
                  'To track active trips and provide navigation support',
                  'To communicate important account and service updates',
                  'To comply with legal obligations and regulatory requirements',
                  'To improve the App and our services',
                  'To investigate and prevent fraud or safety incidents',
                ]),
              ],
            ),
            _PolicySection(
              title: '3. SMS Messaging',
              children: [
                _PolicyParagraph(
                  'Ommo Tech uses SMS messaging solely for account verification and authentication purposes through the Driver App. Specifically:',
                ),
                const SizedBox(height: 8),
                _PolicyBullets(const [
                  'We send one-time passcodes (OTPs) when you register a new account',
                  'We send one-time passcodes when you log in to your existing account',
                  'We do not send marketing or promotional SMS messages',
                  'Message frequency depends on your login and account activity',
                ]),
                const SizedBox(height: 12),
                _PolicyParagraph(
                  'To opt out of SMS verification messages, you may reply STOP to any message. For help, reply HELP or contact our support team. Please note that opting out of SMS will disable phone-based authentication and may prevent access to your account.',
                ),
              ],
            ),
            _PolicySection(
              title: '4. How We Share Your Information',
              children: [
                _PolicyParagraph(
                  'We do not sell your personal information. We may share your information with:',
                ),
                const SizedBox(height: 8),
                _PolicyBullets(const [
                  'Service providers who assist in operating our platform (e.g., cloud hosting, payment processors, SMS delivery providers)',
                  'Business partners such as companies or individuals posting delivery or driving jobs',
                  'Law enforcement or government agencies when required by law or to protect safety',
                  'Successor entities in the event of a merger, acquisition, or sale of assets',
                ]),
                const SizedBox(height: 12),
                _PolicyParagraph(
                  'All third-party service providers are required to protect your information and use it only for the purposes for which it was shared.',
                ),
              ],
            ),
            _PolicySection(
              title: '5. Location Data',
              children: [
                _PolicyParagraph(
                  'The Driver App collects your GPS location while you are actively using it to facilitate job matching, trip tracking, and navigation. Location data is not collected when the App is closed. You may disable location access through your device settings, but this will limit the functionality of the App.',
                ),
              ],
            ),
            _PolicySection(
              title: '6. Data Retention',
              children: [
                _PolicyParagraph(
                  'We retain your personal information for as long as your account is active or as necessary to provide services. After account deletion, we may retain certain data for up to 7 years to comply with legal, tax, and regulatory obligations. You may request deletion of your account and personal data by contacting us at the address below.',
                ),
              ],
            ),
            _PolicySection(
              title: '7. Data Security',
              children: [
                _PolicyParagraph(
                  'We implement industry-standard security measures to protect your personal information, including encryption in transit and at rest, access controls, and regular security reviews. However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
                ),
              ],
            ),
            _PolicySection(
              title: '8. Your Rights',
              children: [
                _PolicyParagraph(
                  'Depending on your state of residence, you may have the following rights regarding your personal information:',
                ),
                const SizedBox(height: 8),
                _PolicyBullets(const [
                  'The right to access the personal information we hold about you',
                  'The right to correct inaccurate information',
                  'The right to request deletion of your personal information',
                  'The right to opt out of certain data sharing practices',
                ]),
                const SizedBox(height: 12),
                _PolicyParagraph(
                  'To exercise any of these rights, please contact us using the information in Section 11. We will respond to your request within 30 days.',
                ),
              ],
            ),
            _PolicySection(
              title: "9. Children's Privacy",
              children: [
                _PolicyParagraph(
                  'The Driver App is intended for use by adults only. We do not knowingly collect personal information from individuals under the age of 18. If we become aware that we have inadvertently collected information from a minor, we will delete it promptly.',
                ),
              ],
            ),
            _PolicySection(
              title: '10. Changes to This Privacy Policy',
              children: [
                _PolicyParagraph(
                  'We may update this Privacy Policy from time to time. We will notify you of material changes by posting the new policy in the Driver App and updating the effective date above. Your continued use of the App after any changes constitutes your acceptance of the updated policy.',
                ),
              ],
            ),
            _PolicySection(
              title: '11. Contact Us',
              children: [
                _PolicyParagraph(
                  'If you have any questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us at:',
                ),
                const SizedBox(height: 12),
                _PolicyParagraph('Ommo Tech'),
                const SizedBox(height: 8),
                _PolicyParagraph('Website: http://ommo.ai'),
                _PolicyParagraph('Email: info@ommo.ai'),
                _PolicyParagraph('Phone: 310-490-4329'),
                _PolicyParagraph(
                  'Address: 651 N Broad St, Suite 201, Middletown, DE 19709',
                ),
                const SizedBox(height: 12),
                _PolicyParagraph(
                  'For SMS-related opt-out requests, you may also reply STOP to any verification message you receive from us.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = AppTextTheme();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.subHeadingText2),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _PolicySubheading extends StatelessWidget {
  const _PolicySubheading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = AppTextTheme();
    final colors = AppColorTheme();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: text.bodyText.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.black,
        ),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.textBody);

  final String textBody;

  @override
  Widget build(BuildContext context) {
    final text = AppTextTheme();
    final colors = AppColorTheme();

    return Text(
      textBody,
      style: text.bodyText.copyWith(color: colors.black, height: 1.45),
    );
  }
}

class _PolicyBullets extends StatelessWidget {
  const _PolicyBullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final text = AppTextTheme();
    final colors = AppColorTheme();
    final style = text.bodyText.copyWith(color: colors.black, height: 1.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: style),
              Expanded(child: Text(item, style: style)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
