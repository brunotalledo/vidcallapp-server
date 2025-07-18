# Braintree/PayPal Integration Setup Guide

This guide will help you set up Braintree and PayPal payment processing in your Swift video calling app.

## Prerequisites

1. **Braintree Account**: Sign up at [braintreepayments.com](https://www.braintreepayments.com)
2. **PayPal Business Account**: Sign up at [paypal.com/business](https://www.paypal.com/business)
3. **iOS Developer Account**: For app distribution

## Step 1: Install Braintree SDK

### Using Swift Package Manager (Recommended)

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the Braintree SDK URL: `https://github.com/braintree/braintree_ios`
3. Select the following packages:
   - `Braintree`
   - `BraintreePayPal`
   - `BraintreeCard`

### Using CocoaPods (Alternative)

Add to your `Podfile`:
```ruby
pod 'Braintree'
pod 'BraintreePayPal'
pod 'BraintreeCard'
```

Then run:
```bash
pod install
```

## Step 2: Configure Your Braintree Account

### Get Your Credentials

1. Log into your [Braintree Dashboard](https://www.braintreepayments.com/sandbox)
2. Go to **Settings** → **API**
3. Note down your:
   - **Merchant ID**
   - **Public Key**
   - **Private Key**

### Generate Client Token

You'll need to generate a client token from your server. For testing, you can use the sandbox environment.

## Step 3: Update Configuration

### Update BraintreeConfig.swift

Replace the placeholder values in `VidCallApp/BraintreeConfig.swift`:

```swift
// Replace with your actual Braintree client token
static let clientToken = isProduction ? 
    "YOUR_PRODUCTION_CLIENT_TOKEN" : 
    "YOUR_SANDBOX_CLIENT_TOKEN"
```

### Get Client Token

For testing, you can generate a client token using the Braintree sandbox. In production, this should come from your server.

## Step 4: Configure PayPal

### PayPal App Setup

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
2. Create a new app
3. Get your **Client ID** and **Secret**
4. Configure your app's return URLs

### Update PayPal Configuration

In `BraintreeConfig.swift`, ensure PayPal environment is set correctly:

```swift
static let payPalEnvironment = isProduction ? 
    BTPayPalRequestEnvironment.production : 
    BTPayPalRequestEnvironment.sandbox
```

## Step 5: Test the Integration

### Test Cards (Sandbox)

Use these test card numbers for testing:

- **Visa**: 4111111111111111
- **Mastercard**: 5555555555554444
- **American Express**: 378282246310005

### Test PayPal

Use the PayPal sandbox accounts:
- **Buyer**: sb-buyer@business.example.com
- **Password**: (provided in PayPal sandbox)

## Step 6: Production Setup

### Switch to Production

1. Update `BraintreeConfig.swift`:
   ```swift
   static let isProduction = true
   ```

2. Replace sandbox credentials with production credentials

3. Update your server endpoints

### Server Integration

For production, you'll need a server to:
1. Generate client tokens securely
2. Process transactions
3. Handle webhooks

## Step 7: Security Considerations

### Client Token Security

- Never expose your private key in the app
- Generate client tokens on your server
- Use short-lived tokens (24 hours max)

### PCI Compliance

- Braintree handles PCI compliance for you
- Never store raw card data
- Use Braintree's tokenization

## Step 8: Error Handling

The integration includes comprehensive error handling for:
- Network errors
- Invalid card details
- Payment failures
- User cancellations

## Step 9: Testing Checklist

- [ ] PayPal payments work in sandbox
- [ ] Credit card payments work in sandbox
- [ ] Error messages display correctly
- [ ] User credits update after payment
- [ ] Transaction history is recorded
- [ ] App handles payment cancellations

## Step 10: Deployment

### App Store Requirements

1. Add payment processing to your app's capabilities
2. Include privacy policy mentioning payment processing
3. Test thoroughly in sandbox before production

### Required App Store Information

- Payment processing disclosure
- Privacy policy URL
- Support contact information

## Troubleshooting

### Common Issues

1. **"Client token invalid"**: Check your client token and environment settings
2. **"PayPal not available"**: Verify PayPal app configuration
3. **"Payment failed"**: Check sandbox vs production environment

### Debug Mode

Enable debug logging in `BraintreeConfig.swift`:
```swift
static let enableDebugLogging = true
```

## Support

- [Braintree iOS Documentation](https://developers.braintreepayments.com/guides/client-sdk/setup/ios/v5)
- [PayPal iOS SDK Documentation](https://developer.paypal.com/docs/checkout/ios/)
- [Braintree Support](https://help.braintreepayments.com/)

## Files Modified/Created

- `VidCallApp/BraintreeManager.swift` - Main payment processing logic
- `VidCallApp/BraintreeConfig.swift` - Configuration and settings
- `VidCallApp/AddCreditView.swift` - Updated with payment method selection
- `VidCallApp/CreditCardFormView.swift` - New credit card input form
- `VidCallApp/PaymentView.swift` - Updated to use real balance

## Next Steps

1. Test the integration thoroughly in sandbox
2. Set up your production server
3. Configure webhooks for payment notifications
4. Implement additional payment methods if needed
5. Add analytics and monitoring 