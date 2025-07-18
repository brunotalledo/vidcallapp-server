# PayPal Payouts Integration Setup Guide

This guide will help you set up PayPal Payouts integration for your video calling app, enabling call providers to withdraw their 75% share of earnings.

## Overview

The PayPal Payouts integration allows call providers to:
- Request withdrawals of their earnings balance
- Receive funds directly to their PayPal account
- Track payout history and status
- Get real-time updates on payout processing

## Prerequisites

1. **PayPal Business Account**: Sign up at [paypal.com/business](https://www.paypal.com/business)
2. **PayPal Developer Account**: Sign up at [developer.paypal.com](https://developer.paypal.com)
3. **Existing Braintree Integration**: Ensure your Braintree setup is working

## Step 1: PayPal Developer Setup

### Create PayPal App

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
2. Navigate to **Apps & Credentials**
3. Click **Create App**
4. Choose **Business** app type
5. Name your app (e.g., "VidCallApp Payouts")
6. Note down your **Client ID** and **Secret**

### Configure PayPal Payouts

1. In your PayPal Developer Dashboard, go to **Products** → **Payouts**
2. Enable **PayPal Payouts** for your account
3. Configure payout settings:
   - Set default currency (USD)
   - Configure payout limits
   - Set up webhook notifications (optional)

## Step 2: Server Configuration

### Environment Variables

Create a `.env` file in your server directory with the following variables:

```env
# PayPal Configuration
PAYPAL_ENVIRONMENT=sandbox
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# Braintree Configuration (existing)
BRAINTREE_ENVIRONMENT=sandbox
BRAINTREE_MERCHANT_ID=your_braintree_merchant_id
BRAINTREE_PUBLIC_KEY=your_braintree_public_key
BRAINTREE_PRIVATE_KEY=your_braintree_private_key

# Server Configuration
PORT=3000
NODE_ENV=development
```

### Install Dependencies

```bash
cd server-example
npm install
```

### Start the Server

```bash
npm start
```

## Step 3: iOS App Integration

### Files Added/Modified

1. **PayPalPayoutsManager.swift** - Main payout management class
2. **WithdrawView.swift** - Updated withdraw interface
3. **PayoutHistoryView.swift** - Payout history display

### Key Features

- **Payout Requests**: Providers can request withdrawals
- **Email Validation**: PayPal email format validation
- **Balance Management**: Automatic balance updates after payouts
- **Status Tracking**: Real-time payout status updates
- **History**: Complete payout history with status

## Step 4: Testing

### Sandbox Testing

1. **PayPal Sandbox Accounts**:
   - Create sandbox business and personal accounts
   - Use sandbox emails for testing payouts

2. **Test Payout Flow**:
   - Add credits to provider account
   - Request payout with sandbox PayPal email
   - Verify payout appears in PayPal sandbox

3. **Test Scenarios**:
   - Valid payout requests
   - Invalid email addresses
   - Insufficient balance
   - Network errors

### Test Data

```swift
// Test PayPal email
let testPayPalEmail = "sb-personal@business.example.com"

// Test amounts
let testAmounts = [10.00, 25.50, 100.00]
```

## Step 5: Production Setup

### Switch to Production

1. **Update Environment Variables**:
   ```env
   PAYPAL_ENVIRONMENT=production
   BRAINTREE_ENVIRONMENT=production
   ```

2. **Update PayPal Credentials**:
   - Use production Client ID and Secret
   - Configure production webhooks

3. **Update iOS App**:
   - Set production server URL
   - Test with real PayPal accounts

### Production Considerations

- **Payout Limits**: PayPal has daily/monthly payout limits
- **Fees**: PayPal charges fees for payouts (typically $0.25 per payout)
- **Compliance**: Ensure compliance with financial regulations
- **Monitoring**: Set up monitoring for failed payouts

## Step 6: API Endpoints

### PayPal Payouts Endpoints

#### Create Payout
```
POST /api/paypal/payouts
{
  "userId": "user_id",
  "amount": 50.00,
  "paypalEmail": "user@example.com",
  "currency": "USD"
}
```

#### Check Payout Status
```
GET /api/paypal/payouts/{payoutId}/status
```

#### Get Payout Details
```
GET /api/paypal/payouts/{payoutId}
```

### Response Format

```json
{
  "success": true,
  "payoutId": "batch_payout_id",
  "batchStatus": "PENDING",
  "amount": 50.00,
  "paypalEmail": "user@example.com"
}
```

## Step 7: Error Handling

### Common Errors

1. **Invalid PayPal Email**:
   - Error: "Invalid PayPal email"
   - Solution: Validate email format

2. **Insufficient Balance**:
   - Error: "Insufficient balance"
   - Solution: Check user balance before payout

3. **PayPal API Errors**:
   - Error: "PayPal authentication failed"
   - Solution: Check credentials and environment

4. **Network Errors**:
   - Error: "Network error"
   - Solution: Check server connectivity

### Error Response Format

```json
{
  "success": false,
  "error": "Error description"
}
```

## Step 8: Security Considerations

### Best Practices

1. **Environment Variables**: Never commit credentials to version control
2. **Input Validation**: Validate all input data
3. **Rate Limiting**: Implement rate limiting for payout requests
4. **Logging**: Log all payout activities for audit
5. **HTTPS**: Use HTTPS for all API communications

### Security Checklist

- [ ] Environment variables properly configured
- [ ] Input validation implemented
- [ ] Rate limiting enabled
- [ ] HTTPS enforced
- [ ] Audit logging configured
- [ ] Error handling implemented

## Step 9: Monitoring and Analytics

### Key Metrics to Track

1. **Payout Volume**: Total amount paid out
2. **Success Rate**: Percentage of successful payouts
3. **Processing Time**: Time from request to completion
4. **Error Rates**: Failed payout attempts
5. **User Activity**: Most active payout users

### Monitoring Setup

```javascript
// Example monitoring code
app.post('/api/paypal/payouts', async (req, res) => {
  const startTime = Date.now();
  
  try {
    // Process payout
    const result = await processPayout(req.body);
    
    // Log success
    console.log(`Payout successful: ${result.payoutId}, Time: ${Date.now() - startTime}ms`);
    
    res.json(result);
  } catch (error) {
    // Log error
    console.error(`Payout failed: ${error.message}, Time: ${Date.now() - startTime}ms`);
    
    res.status(500).json({ error: error.message });
  }
});
```

## Step 10: Troubleshooting

### Common Issues

1. **"PayPal authentication failed"**:
   - Check Client ID and Secret
   - Verify environment (sandbox vs production)
   - Ensure PayPal account is active

2. **"Invalid payout request"**:
   - Validate amount format
   - Check PayPal email format
   - Verify required fields

3. **"Payout not found"**:
   - Check payout ID format
   - Verify payout exists in PayPal
   - Check environment mismatch

### Debug Mode

Enable debug logging in your server:

```javascript
// Add to your server configuration
const DEBUG = process.env.NODE_ENV === 'development';

if (DEBUG) {
  console.log('PayPal request:', JSON.stringify(requestBody, null, 2));
}
```

## Support Resources

- [PayPal Payouts Documentation](https://developer.paypal.com/docs/payouts/)
- [PayPal Developer Support](https://developer.paypal.com/support/)
- [Braintree Documentation](https://developers.braintreepayments.com/)

## Next Steps

1. Test the integration thoroughly in sandbox
2. Set up production environment
3. Configure monitoring and alerts
4. Implement additional payout methods if needed
5. Add payout analytics and reporting

## Files Summary

### New Files Created
- `VidCallApp/PayPalPayoutsManager.swift` - PayPal Payouts management
- `VidCallApp/PayoutHistoryView.swift` - Payout history display
- `server-example/braintree-paypal-server.js` - Combined server
- `PAYPAL_PAYOUTS_SETUP.md` - This setup guide

### Modified Files
- `VidCallApp/WithdrawView.swift` - Updated with PayPal integration
- `server-example/package.json` - Added PayPal dependencies

### Integration Points
- Braintree payment processing (existing)
- PayPal Payouts for withdrawals (new)
- Firebase Firestore for data storage
- Real-time status updates
- Comprehensive error handling 