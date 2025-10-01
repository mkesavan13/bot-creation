const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

const accessToken = 'NDk4Mzk2YTQtN2UwNS00ZmY5LWE5NzgtOWQ0Zjg1ZWNiMzdiZDg4OWFhZGQtNTk2_P0A1_f5095cf8-2142-47f8-b7b4-993c4a5cb95f';
const webhookServerUrl = 'https://xlblz-12-157-146-250.a.free.pinggy.link';
const botEmail = 'aiassistantlab-admin@webex.bot';

// Create a Webhook
async function createWebhook() {
    try {
        const response = await axios.post('https://webexapis.com/v1/webhooks', {
            name: 'AIAssistantLabBot Webhook',
            targetUrl: webhookServerUrl,
            resource: 'messages',
            event: 'created'
        }, {
            headers: {
                Authorization: `Bearer ${accessToken}`
            }
        });
        console.log('Webhook created:', response.data);
    } catch (error) {
        if (error.response && error.response.status === 409) {
            console.log('Webhook is already created');
        } else {
            console.error('Error creating webhook:', error);
        }
    }
}

// Handle incoming messages
app.post('/', async (req, res) => {
    const messageId = req.body.data.id;
    const personEmail = req.body.data.personEmail;

    // Ignore messages from the bot itself
    if (personEmail === botEmail) {
        return res.status(200).send();
    }

    try {
        const messageResponse = await axios.get(`https://webexapis.com/v1/messages/${messageId}`, {
            headers: {
                Authorization: `Bearer ${accessToken}`
            }
        });

        let messageText = messageResponse.data.text;
        messageText = messageText.replace('AIAssistantLabBot', '').trim();

        let responseText;
        if (messageText.startsWith('Echo ')) {
            responseText = `You said: ${messageText.substring(5)}`;
        } else {
            try {
                const result = eval(messageText);
                responseText = `Result: ${result}`;
            } catch (e) {
                responseText = 'Error: The bot expects an echo or a mathematical expression';
            }
        }

        await axios.post('https://webexapis.com/v1/messages', {
            roomId: messageResponse.data.roomId,
            text: responseText
        }, {
            headers: {
                Authorization: `Bearer ${accessToken}`
            }
        });

        res.status(200).send();
    } catch (error) {
        console.error('Error handling message:', error);
        res.status(500).send();
    }
});

// Start the server
app.listen(3000, () => {
    console.log('Server is running on port 3000');
    createWebhook();
});