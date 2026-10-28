# POS Retail Pro — Flutter Starter Project

This is an original Flutter implementation for the retail POS assignment.

## Included
- Splash / welcome screen
- Demo login screen
- Dashboard with live totals from saved transactions
- Product search and checkout cart
- Cash, card, mobile money, and bank transfer method selection
- Inventory list, add product, and stock adjustment
- Customer list and add customer
- Sales reports grouped by payment method
- Business-name customization and offline-mode indicator
- Local persistence with `shared_preferences`

## Important: create platform folders first
This ZIP contains the Dart source and project configuration. Flutter generates platform scaffolding for the computer where you build it.

1. Install Flutter SDK and Google Chrome (for web testing) on a computer.
2. Extract this ZIP and open a terminal inside the `pos_retail_pro` folder.
3. Run:
   ```bash
   flutter create --platforms=web,android,ios .
   flutter pub get
   flutter run -d chrome
   ```
   On Windows, PowerShell or the VS Code terminal is fine. If you only need Chrome testing, `--platforms=web` is sufficient.
4. To build Android later, use `flutter build apk`.

## Demo login
Enter any non-empty email/phone and password. This is intentionally a demo-only sign-in flow.

## Prototype limitations
- Login is not connected to a secure authentication provider.
- Selecting a payment method records it in the local sales report; it does not charge a card or mobile-money account.
- Data is saved locally in the browser/device and is not synchronized between devices.
- SharedPreferences is convenient for a class prototype, but production POS data should use a robust local database, secure credential storage, encryption where appropriate, role-based permissions, backups, audit logs, and tested synchronization.
- iOS builds require macOS and Xcode.

## Dependencies
- Flutter SDK
- `shared_preferences`
