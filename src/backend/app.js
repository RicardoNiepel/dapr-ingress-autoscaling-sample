// ------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ------------------------------------------------------------

const express = require('express');
const bodyParser = require('body-parser');

const app = express();
// Dapr publishes messages with the application/cloudevents+json content-type
app.use(bodyParser.json({ type: 'application/*+json' }));

const port = 3000;

app.get('/dapr/subscribe', (_req, res) => {
    res.json([
        "A"
    ]);
});

app.post('/A', (req, res) => {
    console.log("A: ", req.body);

    // do something powerful
    var waitTill = new Date(new Date().getTime() + 2 * 1000);
    while(waitTill > new Date()){}

    res.sendStatus(200);
});

app.listen(port, () => console.log(`Node App listening on port ${port}!`));
