const express = require('express');
const app = express();

app.get('/', (req, res) => {
    console.log('Request received!');
    res.send('Hello World!');
});

const PORT = 4000;
app.listen(PORT, '0.0.0.0', () => {
    console.log('Server is running on:');
    console.log(`http://localhost:${PORT}`);
    console.log(`http://127.0.0.1:${PORT}`);
}).on('error', (err) => {
    console.error('Server error:', err);
    console.error('Error code:', err.code);
});
