require('dotenv').config();
const express = require('express');
const cors = require('cors');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Add this to verify the key is loaded correctly
console.log('Stripe key loaded:', process.env.STRIPE_SECRET_KEY ? 'Yes' : 'No');

// Test route
app.get('/create-payment-intent', (req, res) => {
  res.json({ status: 'Server is running' });
});

// Payment intent route
app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency } = req.body;
    console.log('Received amount in bani:', amount);
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency || 'ron',
    });

    console.log(`Created payment intent for ${amount} bani (${amount/100} RON)`);
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error('Payment error:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
