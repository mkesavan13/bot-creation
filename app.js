const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
app.use(bodyParser.json());

const WEBEX_ACCESS_TOKEN = 'ZTNmMmIxODYtMGUzZi00MmQ2LWE3YTUtZTdhZDQ0ZDRmYjhlMDRlYzkwMTAtMjll_PF84_1eb65fdf-9643-417f-9974-ad72cae0e10f';
const WEBHOOK_NAME = 'Echo Bot Webhook';
const WEBHOOK_TARGET_URL = 'https://slimy-lemons-know.loca.lt/webhook'; // This will be updated with localtunnel URL
const WEBHOOK_RESOURCE = 'messages';
const WEBHOOK_EVENT = 'created';
const BOT_EMAIL = 'wx1.speaker.bot@webex.bot';
const BOT_NAME = 'Kesava Wx1 Bot';

// Function to create a Webex webhook
async function createWebhook() {
  try {
    const response = await axios.post('https://webexapis.com/v1/webhooks', {
      name: WEBHOOK_NAME,
      targetUrl: WEBHOOK_TARGET_URL,
      resource: WEBHOOK_RESOURCE,
      event: WEBHOOK_EVENT
    }, {
      headers: {
        Authorization: `Bearer ${WEBEX_ACCESS_TOKEN}`
      }
    });
    console.log('Webhook created:', response.data);
  } catch (error) {
    console.error('Error creating webhook:', error.response?.data || error.message);
  }
}

// Function to send a message in response to an Echo command
async function sendMessage(roomId, message) {
  try {
    const response = await axios.post('https://webexapis.com/v1/messages', {
      roomId: roomId,
      text: message
    }, {
      headers: {
        Authorization: `Bearer ${WEBEX_ACCESS_TOKEN}`
      }
    });
    console.log('Message sent:', response.data);
  } catch (error) {
    console.error('Error sending message:', error.response?.data || error.message);
  }
}

app.post('/webhook', (req, res) => {
    const data = req.body.data;
    const messageId = data.id;
    const roomId = data.roomId;
  
    // Fetch the message details
    axios.get(`https://webexapis.com/v1/messages/${messageId}`, {
      headers: {
        Authorization: `Bearer ${WEBEX_ACCESS_TOKEN}`
      }
    })
    .then(response => {
      let messageText = response.data.text;
      const senderEmail = response.data.personEmail;
  
      // Ensure the bot does not respond to its own messages
      if (senderEmail !== BOT_EMAIL) {
        // Remove bot's name from the message if present
        if (messageText.includes(BOT_NAME)) {
          messageText = messageText.replace(BOT_NAME, '').trim();
        }
  
        if (messageText.startsWith('Echo ')) {
          const echoMessage = messageText.substring(5);
          sendMessage(roomId, `You said: ${echoMessage}`);
        } else {
          try {
            const result = eval(messageText);
            sendMessage(roomId, `Result: ${result}`);
          } catch (error) {
            sendMessage(roomId, 'Error: Invalid mathematical expression');
          }
        }
      }
    })
    .catch(error => {
      console.error('Error fetching message:', error);
    });
  
    res.status(200).send('Event received');
});

// Start the server on port 3000
app.listen(3000, () => {
  console.log('Server is running on port 3000');
  createWebhook(); // Uncomment when you have the tunnel URL
});
