const express = require('express');
const axios = require('axios');
const router = express.Router();

router.get('/searchByGeoId', async (req, res) => {
  const {
    geoId,
    checkIn,
    checkOut,
    rooms = 1,
    adults = 2,
    children = 0,
    currencyCode = 'INR'
  } = req.query;

  if (!geoId || !checkIn || !checkOut) {
    return res.status(400).json({ error: 'Missing required parameters: geoId, checkIn, checkOut' });
  }

  // ✅ Validate date format
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!dateRegex.test(checkIn) || !dateRegex.test(checkOut)) {
    return res.status(400).json({
      error: 'Invalid date format. Use YYYY-MM-DD for both checkIn and checkOut'
    });
  }

  try {
    console.log('Sending hotel search with params:', {
      geoId,
      checkIn,
      checkOut,
      adults,
      rooms,
      currencyCode
    });

    const response = await axios.get('https://tripadvisor-com1.p.rapidapi.com/hotels/search', {
      params: {
        geoId,
        checkIn,
        checkOut,
        adults,
        rooms,
        currency: currencyCode
      },
      headers: {
        'x-rapidapi-key': process.env.RAPIDAPI_KEY,
        'x-rapidapi-host': 'tripadvisor-com1.p.rapidapi.com'
      }
    });

    res.json({
      geoId,
      hotels: response.data
    });
  } catch (err) {
    console.error('Hotel fetch error:', err.response?.data || err.message);
    res.status(500).json({ error: err.response?.data || err.message });
  }
});

module.exports = router;
