const paypal = require('@paypal/checkout-server-sdk');
require('dotenv').config();

// PayPal configuration
let paypalEnvironment;
if (process.env.PAYPAL_ENVIRONMENT === 'production') {
  paypalEnvironment = new paypal.core.LiveEnvironment(
    process.env.PAYPAL_CLIENT_ID,
    process.env.PAYPAL_CLIENT_SECRET
  );
} else {
  paypalEnvironment = new paypal.core.SandboxEnvironment(
    process.env.PAYPAL_CLIENT_ID,
    process.env.PAYPAL_CLIENT_SECRET
  );
}

const paypalClient = new paypal.core.PayPalHttpClient(paypalEnvironment);

async function testPayPalPayout() {
  console.log('🧪 Testing PayPal Payouts Integration...');
  console.log(`🌍 Environment: ${process.env.PAYPAL_ENVIRONMENT || 'sandbox'}`);
  
  try {
    // Test payout request
    const request = new paypal.payouts.PayoutsPostRequest();
    request.requestBody({
      sender_batch_header: {
        sender_batch_id: `test_batch_${Date.now()}`,
        email_subject: "Test Payout from VidCallApp",
        email_message: "This is a test payout from your video calling earnings."
      },
      items: [
        {
          recipient_type: "EMAIL",
          amount: {
            value: "10.00",
            currency: "USD"
          },
          receiver: "sb-personal@business.example.com", // Sandbox test email
          note: "Test payout from VidCallApp",
          sender_item_id: `test_item_${Date.now()}`
        }
      ]
    });

    console.log('🔄 Creating test payout...');
    const response = await paypalClient.execute(request);
    
    if (response.result.batch_header.payout_batch_id) {
      console.log('✅ Test payout created successfully!');
      console.log('📋 Payout Details:');
      console.log(`   Payout ID: ${response.result.batch_header.payout_batch_id}`);
      console.log(`   Status: ${response.result.batch_header.batch_status}`);
      console.log(`   Amount: $10.00 USD`);
      console.log(`   Recipient: sb-personal@business.example.com`);
      
      // Test getting payout status
      console.log('\n🔄 Testing payout status check...');
      const statusRequest = new paypal.payouts.PayoutsGetRequest(response.result.batch_header.payout_batch_id);
      const statusResponse = await paypalClient.execute(statusRequest);
      
      console.log('✅ Payout status retrieved successfully!');
      console.log(`   Current Status: ${statusResponse.result.batch_header.batch_status}`);
      console.log(`   Time Created: ${statusResponse.result.batch_header.time_created}`);
      
    } else {
      console.error('❌ Test payout failed - no batch ID returned');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    
    if (error.statusCode) {
      console.error(`   Status Code: ${error.statusCode}`);
    }
    
    if (error.result) {
      console.error(`   PayPal Error: ${JSON.stringify(error.result, null, 2)}`);
    }
  }
}

async function testPayPalConnection() {
  console.log('🔗 Testing PayPal connection...');
  
  try {
    // Simple test to verify credentials
    const request = new paypal.payouts.PayoutsGetRequest('test_batch_id');
    
    try {
      await paypalClient.execute(request);
    } catch (error) {
      if (error.statusCode === 404) {
        console.log('✅ PayPal connection successful (404 expected for invalid batch ID)');
        return true;
      } else if (error.statusCode === 401) {
        console.error('❌ PayPal authentication failed - check credentials');
        return false;
      } else {
        console.log('✅ PayPal connection successful');
        return true;
      }
    }
  } catch (error) {
    console.error('❌ PayPal connection failed:', error.message);
    return false;
  }
}

async function runTests() {
  console.log('🚀 Starting PayPal Payouts Integration Tests\n');
  
  // Test connection first
  const connectionOk = await testPayPalConnection();
  
  if (connectionOk) {
    console.log('\n' + '='.repeat(50) + '\n');
    await testPayPalPayout();
  } else {
    console.log('\n❌ Skipping payout test due to connection failure');
  }
  
  console.log('\n' + '='.repeat(50));
  console.log('🏁 Tests completed');
}

// Check if required environment variables are set
if (!process.env.PAYPAL_CLIENT_ID || !process.env.PAYPAL_CLIENT_SECRET) {
  console.error('❌ Missing required environment variables:');
  console.error('   PAYPAL_CLIENT_ID');
  console.error('   PAYPAL_CLIENT_SECRET');
  console.error('\nPlease set these in your .env file');
  process.exit(1);
}

runTests().catch(console.error); 