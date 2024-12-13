const express = require('express');
const app = express();

app.get('/', (req, res) => {
    console.log('Received request');
    res.send('Hello World');
});

const PORT = 4000;
const HOST = '127.0.0.1';

app.listen(PORT, HOST, () => {
    console.log(`Server running at http://${HOST}:${PORT}`);
}).on('error', (err) => {
    console.error('Server error:', err);
});
