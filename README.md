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
- Local persistence with `shared_preferences.

Demo login
Enter any non-empty email/phone and password. This is intentionally a demo-only sign-in flow.

Prototype limitations
- Login is not connected to a secure authentication provider.
- Selecting a payment method records it in the local sales report; it does not charge a card or mobile-money account.
- Data is saved locally in the browser/device and is not synchronized between devices.
- SharedPreferences is convenient for a class prototype, but production POS data should use a robust local database, secure credential storage, encryption where appropriate, role-based permissions and backups 

## Dependencies
- Flutter SDK
- `shared_preferences`
