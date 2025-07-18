const express = require('express');
const braintree = require('braintree');
const paypal = require('@paypal/checkout-server-sdk');
const cors = require('cors');
require('dotenv').config();
const axios = require('axios');
const qs = require('querystring');

const app = express();
app.use(cors());
app.use(express.json());

// Braintree configuration
const gateway = new braintree.BraintreeGateway({
  environment: process.env.BRAINTREE_ENVIRONMENT === 'production' 
    ? braintree.Environment.Production 
    : braintree.Environment.Sandbox,
  merchantId: process.env.BRAINTREE_MERCHANT_ID,
  publicKey: process.env.BRAINTREE_PUBLIC_KEY,
  privateKey: process.env.BRAINTREE_PRIVATE_KEY,
});

// PayPal configuration
let environment;
if (process.env.PAYPAL_ENVIRONMENT === 'production') {
  environment = new paypal.core.LiveEnvironment(
    process.env.PAYPAL_CLIENT_ID,
    process.env.PAYPAL_CLIENT_SECRET
  );
} else {
  environment = new paypal.core.SandboxEnvironment(
    process.env.PAYPAL_CLIENT_ID,
    process.env.PAYPAL_CLIENT_SECRET
  );
}
const paypalClient = new paypal.core.PayPalHttpClient(environment);

// ===== BRAINTREE ENDPOINTS =====

// Generate client token with customer support
app.get('/api/braintree/client-token', async (req, res) => {
  try {
    const { customerId } = req.query;
    
    if (!customerId) {
      return res.status(400).json({ error: 'Customer ID is required' });
    }

    // Create or find customer
    let customer;
    try {
      customer = await gateway.customer.find(customerId);
      console.log('Found existing customer:', customerId);
    } catch (error) {
      if (error.type === 'notFoundError') {
        // Create new customer
        const result = await gateway.customer.create({
          id: customerId,
        });
        customer = result.customer;
        console.log('Created new customer:', customerId);
      } else {
        throw error;
      }
    }

    // Generate client token with customer ID
    const response = await gateway.clientToken.generate({
      customerId: customerId,
    });
    
    res.json({ 
      clientToken: response.clientToken,
      customerId: customerId 
    });
  } catch (error) {
    console.error('Error generating client token:', error);
    res.status(500).json({ error: 'Failed to generate client token' });
  }
});

// Process payment
app.post('/api/braintree/transactions', async (req, res) => {
  try {
    const { paymentMethodNonce, amount, userId } = req.body;
    
    if (!paymentMethodNonce || !amount || !userId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await gateway.transaction.sale({
      amount: amount.toString(),
      paymentMethodNonce: paymentMethodNonce,
      customerId: userId,
      options: {
        submitForSettlement: true,
      },
    });

    if (result.success) {
      res.json({
        success: true,
        transactionId: result.transaction.id,
        amount: result.transaction.amount,
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.message,
      });
    }
  } catch (error) {
    console.error('Error processing transaction:', error);
    res.status(500).json({ error: 'Failed to process transaction' });
  }
});

// Get transaction history
app.get('/api/braintree/transactions/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const response = await gateway.transaction.search((search) => {
      search.customerId().is(userId);
    });

    const transactions = [];
    response.each((err, transaction) => {
      if (err) {
        console.error('Error fetching transaction:', err);
        return;
      }
      
      transactions.push({
        id: transaction.id,
        amount: transaction.amount,
        status: transaction.status,
        paymentMethodType: transaction.paymentInstrumentType,
        createdAt: transaction.createdAt,
      });
    });

    res.json({ transactions });
  } catch (error) {
    console.error('Error fetching transactions:', error);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

// Webhook handler for payment notifications
app.post('/api/braintree/webhooks', async (req, res) => {
  try {
    const webhookNotification = gateway.webhookNotification.parse(
      req.body.bt_signature,
      req.body.bt_payload
    );

    console.log('Webhook received:', webhookNotification.kind);

    switch (webhookNotification.kind) {
      case 'transaction_settled':
        // Handle settled transaction
        console.log('Transaction settled:', webhookNotification.transaction.id);
        break;
      case 'transaction_settlement_declined':
        // Handle declined settlement
        console.log('Settlement declined:', webhookNotification.transaction.id);
        break;
      default:
        console.log('Unhandled webhook kind:', webhookNotification.kind);
    }

    res.sendStatus(200);
  } catch (error) {
    console.error('Webhook error:', error);
    res.sendStatus(500);
  }
});

// Save payment method to vault
app.post('/api/braintree/payment-methods', async (req, res) => {
  try {
    const { paymentMethodNonce, customerId, deviceData } = req.body;
    
    if (!paymentMethodNonce || !customerId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await gateway.paymentMethod.create({
      customerId: customerId,
      paymentMethodNonce: paymentMethodNonce,
      deviceData: deviceData,
    });

    if (result.success) {
      res.json({
        success: true,
        paymentMethod: {
          token: result.paymentMethod.token,
          type: result.paymentMethod.paymentInstrumentName,
          last4: result.paymentMethod.last4,
          cardType: result.paymentMethod.cardType,
          expirationMonth: result.paymentMethod.expirationMonth,
          expirationYear: result.paymentMethod.expirationYear,
        },
      });
    } else {
      res.status(400).json({
        success: false,
        error: result.message,
      });
    }
  } catch (error) {
    console.error('Error saving payment method:', error);
    res.status(500).json({ error: 'Failed to save payment method' });
  }
});

// Get saved payment methods for a customer
app.get('/api/braintree/payment-methods/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    console.log('🔍 Fetching payment methods for customer:', customerId);
    
    const customer = await gateway.customer.find(customerId);
    console.log('✅ Found customer:', customer.id);
    console.log('📦 Customer payment methods:', customer.paymentMethods.length);
    
    const paymentMethods = customer.paymentMethods.map(pm => ({
      token: pm.token,
      type: pm.paymentInstrumentName,
      last4: pm.last4,
      cardType: pm.cardType,
      expirationMonth: pm.expirationMonth,
      expirationYear: pm.expirationYear,
      isDefault: pm.default,
    }));

    console.log('📤 Sending payment methods:', paymentMethods);
    res.json({ paymentMethods });
  } catch (error) {
    console.error('❌ Error fetching payment methods:', error);
    res.status(500).json({ error: 'Failed to fetch payment methods' });
  }
});

// Delete a payment method
app.delete('/api/braintree/payment-methods/:token', async (req, res) => {
  try {
    const { token } = req.params;
    
    await gateway.paymentMethod.delete(token);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting payment method:', error);
    res.status(500).json({ error: 'Failed to delete payment method' });
  }
});

// ===== PAYPAL PAYOUTS ENDPOINTS =====

// Create PayPal Payout
app.post('/api/paypal/payouts', async (req, res) => {
  try {
    const { userId, amount, paypalEmail, currency = 'USD' } = req.body;

    if (!userId || !amount || !paypalEmail) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const payoutAmount = parseFloat(amount);
    if (isNaN(payoutAmount) || payoutAmount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const emailRegex = /^[^\s@]+@[^\\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(paypalEmail)) {
      return res.status(400).json({ error: 'Invalid PayPal email' });
    }

    // 1. Get OAuth2 token from PayPal
    const tokenResponse = await axios({
      method: 'post',
      url: `https://api-m.sandbox.paypal.com/v1/oauth2/token`,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      auth: {
        username: process.env.PAYPAL_CLIENT_ID,
        password: process.env.PAYPAL_CLIENT_SECRET,
      },
      data: qs.stringify({ grant_type: 'client_credentials' }),
    });

    const accessToken = tokenResponse.data.access_token;

    // 2. Make the payout request
    const payoutResponse = await axios({
      method: 'post',
      url: `https://api-m.sandbox.paypal.com/v1/payments/payouts`,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      data: {
        sender_batch_header: {
          sender_batch_id: `batch_${Date.now()}_${userId}`,
          email_subject: "You have a payout from VidCallApp",
          email_message: "You have received a payout from your video calling earnings."
        },
        items: [
          {
            recipient_type: "EMAIL",
            amount: {
              value: payoutAmount.toFixed(2),
              currency: currency
            },
            receiver: paypalEmail,
            note: "Payout from VidCallApp earnings",
            sender_item_id: `item_${Date.now()}_${userId}`
          }
        ]
      }
    });

    if (
      payoutResponse.data &&
      payoutResponse.data.batch_header &&
      payoutResponse.data.batch_header.payout_batch_id
    ) {
      return res.json({
        success: true,
        payoutId: payoutResponse.data.batch_header.payout_batch_id,
        batchStatus: payoutResponse.data.batch_header.batch_status,
        amount: payoutAmount,
        paypalEmail: paypalEmail
      });
    } else {
      return res.status(500).json({ error: 'Failed to create payout' });
    }
  } catch (error) {
    console.error('❌ Error creating PayPal payout:', error.response ? error.response.data : error.message);
    let errorMsg = 'Failed to create payout';
    if (error.response && error.response.data) {
      errorMsg = JSON.stringify(error.response.data);
    } else if (error.message) {
      errorMsg = error.message;
    }
    return res.status(500).json({ error: errorMsg });
  }
});

// Get payout status
app.get('/api/paypal/payouts/:payoutId/status', async (req, res) => {
  try {
    const { payoutId } = req.params;
    
    if (!payoutId) {
      return res.status(400).json({ error: 'Payout ID is required' });
    }

    const request = new paypal.payouts.PayoutsGetRequest(payoutId);
    const response = await paypalClient.execute(request);
    
    if (response.result.batch_header) {
      res.json({
        success: true,
        status: response.result.batch_header.batch_status,
        payoutId: response.result.batch_header.payout_batch_id,
        timeCompleted: response.result.batch_header.time_completed
      });
    } else {
      res.status(404).json({ error: 'Payout not found' });
    }
  } catch (error) {
    console.error('Error checking payout status:', error);
    
    if (error.statusCode === 404) {
      res.status(404).json({ error: 'Payout not found' });
    } else {
      res.status(500).json({ error: 'Failed to check payout status' });
    }
  }
});

// Get payout details
app.get('/api/paypal/payouts/:payoutId', async (req, res) => {
  try {
    const { payoutId } = req.params;
    
    if (!payoutId) {
      return res.status(400).json({ error: 'Payout ID is required' });
    }

    const request = new paypal.payouts.PayoutsGetRequest(payoutId);
    const response = await paypalClient.execute(request);
    
    if (response.result) {
      res.json({
        success: true,
        payout: {
          id: response.result.batch_header.payout_batch_id,
          status: response.result.batch_header.batch_status,
          timeCreated: response.result.batch_header.time_created,
          timeCompleted: response.result.batch_header.time_completed,
          items: response.result.items || []
        }
      });
    } else {
      res.status(404).json({ error: 'Payout not found' });
    }
  } catch (error) {
    console.error('Error getting payout details:', error);
    
    if (error.statusCode === 404) {
      res.status(404).json({ error: 'Payout not found' });
    } else {
      res.status(500).json({ error: 'Failed to get payout details' });
    }
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    services: {
      braintree: 'connected',
      paypal: 'connected'
    }
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Braintree & PayPal server running on port ${PORT}`);
  console.log(`🌍 Environment: ${process.env.BRAINTREE_ENVIRONMENT || 'sandbox'}`);
  console.log(`💳 Braintree: ${process.env.BRAINTREE_ENVIRONMENT === 'production' ? 'Production' : 'Sandbox'}`);
  console.log(`💰 PayPal: ${process.env.PAYPAL_ENVIRONMENT === 'production' ? 'Production' : 'Sandbox'}`);
}); 