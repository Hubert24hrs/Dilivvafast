import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dilivvafast/core/constants/app_constants.dart';
import 'package:dilivvafast/core/presentation/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Keep in step with docs/privacy.html, which is the URL given to Google
  // Play. The Data safety form must describe the same collection.
  static const String policyMarkdown =
      '''
# Privacy Policy

**Effective date:** 25 October 2026

Dilivvafast ("we", "us") runs the Dilivvafast courier app. This policy explains what we collect, why, who we share it with, and how to delete it.

## 1. Information we collect

- **Account:** name, email address, phone number and profile photo.
- **Location:** precise location while you use the app — for customers to set pickup and drop-off points, and for couriers while they are online, so customers can follow an active delivery. We do not collect location when the app is closed.
- **Courier onboarding:** driver's licence, government ID, vehicle photo and bank details for payouts. These are visible only to you and our review team.
- **Deliveries and payments:** addresses, package details, fares, wallet transactions and ratings. Card payments are handled by Paystack; we never see or store card numbers.
- **Messages:** chats with your courier or customer, chats with our support team, and questions you ask our in-app assistant, Maya.
- **Device and diagnostics:** device model, OS version, push-notification token, app usage events and crash reports (Firebase Analytics and Crashlytics).

We do not show ads and do not use your device's advertising ID.

## 2. How we use it

To run your account, match deliveries with couriers, show live tracking, process payments and payouts, send notifications you have not switched off, provide support, prevent fraud, and fix and improve the app.

## 3. Who we share it with

- **The other side of a delivery:** your courier sees your name, phone number and addresses; customers see their courier's first name, rating, vehicle and live location during the delivery.
- **Service providers:** Google Firebase (hosting, sign-in, database, notifications, analytics), Paystack (payments), Mapbox (maps and address search) and Anthropic (messages you send to Maya, used only to generate her replies — please don't share passwords or card details with her).
- **Legal requirements:** when required by law or to protect someone's safety.

We do not sell your personal data.

## 4. Retention and deletion

You can delete your account at any time in **Settings → Delete Account**. This permanently deletes your profile, saved addresses, notifications, support chats, uploaded courier documents and bank details, and signs you out everywhere. Any wallet balance is forfeited.

Delivery and payment records are kept for up to 7 years for accounting, tax and dispute handling. They are no longer linked to your name.

If you can't use the app, email ${AppConstants.privacyEmail} from your account's email address and we will delete it for you. Details: ${AppConstants.accountDeletionUrl}

## 5. Security

Data is stored on Google Firebase, encrypted in transit and at rest. Access rules limit each user to their own data, and payment and payout logic runs only on our servers.

## 6. Your rights

You can ask to access, correct or delete your personal data, or object to how we use it, by emailing ${AppConstants.privacyEmail}.

## 7. Children

Dilivvafast is not for anyone under 16, and couriers must be 18 or older.

## 8. Changes

We will tell you in the app before significant changes take effect.

## 9. Contact

${AppConstants.privacyEmail} · Dilivvafast Technologies, Lagos, Nigeria
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.surfaceBase,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: context.palette.surfaceRaised,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri url = Uri.parse(AppConstants.privacyPolicyUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Markdown(
        data: policyMarkdown,
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            color: context.palette.brand,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          p: TextStyle(color: context.palette.textSecondary, height: 1.5),
          listBullet: TextStyle(color: context.palette.brand),
        ),
      ),
    );
  }
}
