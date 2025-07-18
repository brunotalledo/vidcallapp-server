# Braintree Payment Server

This is a Node.js server that handles Braintree payment processing for the iOS video calling app.

## Local Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create a `.env` file with your Braintree credentials:
   ```
   BRAINTREE_ENVIRONMENT=sandbox
   BRAINTREE_MERCHANT_ID=your_merchant_id
   BRAINTREE_PUBLIC_KEY=your_public_key
   BRAINTREE_PRIVATE_KEY=your_private_key
   ```

3. Start the server:
   ```bash
   npm start
   ```

## Deploy to Railway

1. Install Railway CLI:
   ```bash
   npm install -g @railway/cli
   ```

2. Login to Railway:
   ```bash
   railway login
   ```

3. Initialize Railway project:
   ```bash
   railway init
   ```

4. Set environment variables in Railway dashboard:
   - `BRAINTREE_ENVIRONMENT=sandbox`
   - `BRAINTREE_MERCHANT_ID=your_merchant_id`
   - `BRAINTREE_PUBLIC_KEY=your_public_key`
   - `BRAINTREE_PRIVATE_KEY=your_private_key`

5. Deploy:
   ```bash
   railway up
   ```

6. Get your public URL:
   ```bash
   railway domain
   ```

## API Endpoints

- `GET /api/braintree/client-token` - Generate client token for Braintree Drop-in
- `POST /api/braintree/transactions` - Process payment transaction
- `GET /api/braintree/transactions/:userId` - Get transaction history
- `POST /api/braintree/webhooks` - Handle Braintree webhooks

## Update iOS App

After deployment, update the `serverURL` in `VidCallApp/BraintreeManager.swift` with your Railway URL. 