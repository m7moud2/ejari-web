const DEFAULT_RATE_LIMIT_MS = 1000;
let lastNominatimRequestAt = 0;

const hasFetch = typeof fetch === 'function';

function assertFetch() {
  if (!hasFetch) {
    throw new Error('Global fetch is not available in this Node runtime.');
  }
}

function normalizeAddress(address = '') {
  return String(address).trim().replace(/\s+/g, ' ');
}

async function rateLimitedRequest(url, options = {}) {
  const now = Date.now();
  const wait = Math.max(0, DEFAULT_RATE_LIMIT_MS - (now - lastNominatimRequestAt));
  if (wait > 0) {
    await new Promise((resolve) => setTimeout(resolve, wait));
  }
  lastNominatimRequestAt = Date.now();
  assertFetch();
  const response = await fetch(url, options);
  if (!response.ok) {
    throw new Error(`Request failed (${response.status}) for ${url}`);
  }
  return response;
}

async function geocodeAddress(address) {
  const query = normalizeAddress(address);
  if (!query) return null;

  const url = new URL('https://nominatim.openstreetmap.org/search');
  url.searchParams.set('format', 'jsonv2');
  url.searchParams.set('limit', '1');
  url.searchParams.set('q', query);

  const response = await rateLimitedRequest(url, {
    headers: {
      'User-Agent': 'Ejari/1.0 (https://m7moud2.github.io/ejari-web)'
    }
  });

  const results = await response.json();
  const match = results?.[0];
  if (!match) return null;
  return {
    lat: Number(match.lat),
    lng: Number(match.lon),
    displayName: match.display_name,
    boundingBox: match.boundingbox,
  };
}

async function searchLocation(query) {
  const q = normalizeAddress(query);
  if (!q) return [];

  const url = new URL('https://nominatim.openstreetmap.org/search');
  url.searchParams.set('format', 'jsonv2');
  url.searchParams.set('limit', '5');
  url.searchParams.set('q', q);

  const response = await rateLimitedRequest(url, {
    headers: {
      'User-Agent': 'Ejari/1.0 (https://m7moud2.github.io/ejari-web)'
    }
  });

  const results = await response.json();
  return Array.isArray(results)
    ? results.map((item) => ({
        lat: Number(item.lat),
        lng: Number(item.lon),
        displayName: item.display_name,
        placeId: item.place_id,
      }))
    : [];
}

function createMapBootConfig({ egyptCenter = { lat: 26.8206, lng: 30.8025 }, zoom = 6 } = {}) {
  return { center: egyptCenter, zoom };
}

function filterApartmentsByBounds(apartments = [], bounds) {
  if (!bounds || typeof bounds.contains !== 'function') return apartments;
  return apartments.filter((apt) => {
    const lat = Number(apt?.location?.coordinates?.coordinates?.[1] ?? apt?.lat);
    const lng = Number(apt?.location?.coordinates?.coordinates?.[0] ?? apt?.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
    return bounds.contains({ lat, lng });
  });
}

function buildCloudinaryUrl(publicId, options = {}) {
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  if (!cloudName) {
    throw new Error('CLOUDINARY_CLOUD_NAME is required');
  }
  const transforms = [];
  if (options.width) transforms.push(`w_${options.width}`);
  if (options.height) transforms.push(`h_${options.height}`);
  transforms.push('f_auto', 'q_auto');
  const transformPart = transforms.join(',');
  return `https://res.cloudinary.com/${cloudName}/image/upload/${transformPart}/${publicId}`;
}

async function sendGridRequest(payload) {
  const apiKey = process.env.SENDGRID_API_KEY;
  const fromEmail = process.env.SENDGRID_FROM_EMAIL;
  if (!apiKey || !fromEmail) {
    return { skipped: true, reason: 'SendGrid env vars are missing' };
  }
  assertFetch();
  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({ from: { email: fromEmail, name: 'إيجاري' }, ...payload }),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`SendGrid error (${response.status}): ${text}`);
  }
  return { ok: true };
}

function htmlMessage(title, body) {
  return `
    <div style="font-family:Arial,sans-serif;direction:rtl;text-align:right;line-height:1.8;color:#173f3a">
      <h2>${title}</h2>
      <p>${body}</p>
      <p style="color:#8b6b42">إيجاري | سكنك أسهل</p>
    </div>
  `;
}

async function sendWelcomeEmail(to, name) {
  return sendGridRequest({
    personalizations: [{ to: [{ email: to, name }] }],
    subject: 'مرحبًا بك في إيجاري',
    content: [{ type: 'text/html', value: htmlMessage('مرحبًا بك في إيجاري', `أهلًا ${name || ''}، سعداء بانضمامك لمنصة إيجاري.`) }],
  });
}

async function sendInquiryNotification(to, apartmentTitle, senderName) {
  return sendGridRequest({
    personalizations: [{ to: [{ email: to }] }],
    subject: 'استفسار جديد على عقارك',
    content: [{ type: 'text/html', value: htmlMessage('استفسار جديد', `وصلتك رسالة من ${senderName || 'مستخدم'} بخصوص <strong>${apartmentTitle || 'عقار'}</strong>.`) }],
  });
}

async function sendBookingConfirmation(to, apartmentDetails = {}) {
  return sendGridRequest({
    personalizations: [{ to: [{ email: to }] }],
    subject: 'تم تأكيد الحجز',
    content: [{ type: 'text/html', value: htmlMessage('تم تأكيد الحجز', `تم تأكيد حجز <strong>${apartmentDetails.title || 'العقار'}</strong>. تابع التفاصيل من لوحة التحكم.`) }],
  });
}

module.exports = {
  geocodeAddress,
  searchLocation,
  createMapBootConfig,
  filterApartmentsByBounds,
  buildCloudinaryUrl,
  sendWelcomeEmail,
  sendInquiryNotification,
  sendBookingConfirmation,
};
