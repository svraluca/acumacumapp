require('dotenv').config();
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Test route
app.get('/', (req, res) => {
  res.send('Stripe server is running!');
});

// Create payment intent endpoint
app.post('/create-payment-intent', async (req, res) => {
  try {
    console.log('Received request:', req.body); // Debug log
    const { amount, currency } = req.body;
    
    console.log(`Creating payment intent for amount: ${amount} ${currency}`); // Debug log
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
    });

    console.log('Payment intent created:', paymentIntent.id); // Debug log
    
    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
