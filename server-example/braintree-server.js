const express = require('express');
const braintree = require('braintree');
const cors = require('cors');
require('dotenv').config();

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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Braintree server running on port ${PORT}`);
}); 