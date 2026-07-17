// routes/aiRoutes.js

const express = require('express');
const router = express.Router();
const { getChatResponse } = require('../controllers/aiController');

// مسار المحادثة مع الذكاء الاصطناعي
router.post('/chat', getChatResponse);

module.exports = router;
