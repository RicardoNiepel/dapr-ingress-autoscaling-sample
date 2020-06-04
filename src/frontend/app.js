// ------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.
// ------------------------------------------------------------

const express = require('express');
const bodyParser = require('body-parser');
const request = require('request');

const app = express();
// Dapr publishes messages with the application/cloudevents+json content-type
app.use(bodyParser.json({ type: 'application/*+json' }));

const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const daprUrl = `http://localhost:${daprPort}/v1.0`;
const port = 8080;

app.get('/dosomething', (_req, res) => {
    const message = [{
        some: "data"
    }];

    console.log("Publishing message");
    const publishUrl = `${daprUrl}/publish/A`;
    request( { uri: publishUrl, method: 'POST', json: JSON.stringify(message) } );
    res.sendStatus(200);
});

app.listen(port, () => console.log(`Node App listening on port ${port}!`));
