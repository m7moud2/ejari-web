const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Property = require('./models/Property');
const User = require('./models/User');

dotenv.config({ path: path.join(__dirname, '.env') });

const DATA_PATHS = [
  path.join(__dirname, 'data', 'egary_apartments_mock_data.json'),
  path.join(process.cwd(), 'egary_apartments_mock_data.json'),
];

function readJsonIfExists(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function generateFallbackApartments(count = 100) {
  const cities = ['القاهرة', 'الجيزة', 'الإسكندرية', 'القليوبية'];
  const areas = ['مدينة نصر', 'المعادي', 'الشيخ زايد', 'التجمع الخامس', 'سموحة', 'لوران', 'شبرا', 'بنها'];
  const titles = ['شقة مميزة', 'شقة مفروشة', 'استوديو أنيق', 'وحدة عائلية', 'شقة لقطة'];

  return Array.from({ length: count }, (_, index) => {
    const city = cities[index % cities.length];
    const area = areas[index % areas.length];
    return {
      title: `${titles[index % titles.length]} - ${area}`,
      description: `وحدة سكنية ${index + 1} جاهزة للإيجار في ${area}، ${city}.`,
      type: 'apartment',
      status: 'available',
      price: 2500 + (index % 20) * 500,
      location: {
        address: `${area}، ${city}`,
        city,
        coordinates: {
          type: 'Point',
          coordinates: [31.2 + (index % 10) * 0.01, 30.0 + (index % 10) * 0.01],
        },
      },
      features: {
        bedrooms: 2 + (index % 3),
        bathrooms: 1 + (index % 2),
        area: 90 + (index % 5) * 15,
        furnished: index % 2 === 0,
        airCondition: index % 3 === 0,
        parking: index % 4 === 0,
        elevator: index % 5 !== 0,
      },
      amenities: ['إنترنت', 'أمن', 'موقع مميز'],
      images: ['assets/images/home1.jpg'],
    };
  });
}

async function ensureAdmin() {
  let admin = await User.findOne({ email: 'admin@ejari.app' });
  if (!admin) {
    admin = await User.create({
      name: 'مدير إيجاري',
      email: 'admin@ejari.app',
      password: 'admin123',
      phone: '01000000000',
      address: 'القاهرة، مصر',
      role: 'admin',
      isVerified: true,
    });
  }
  return admin;
}

async function seed() {
  const rawData = DATA_PATHS.map(readJsonIfExists).find(Boolean);
  const apartments = Array.isArray(rawData) && rawData.length ? rawData : generateFallbackApartments();
  const admin = await ensureAdmin();

  await Property.deleteMany({});
  const docs = apartments.map((item) => ({
    title: item.title,
    description: item.description,
    type: item.type || 'apartment',
    status: item.status || 'available',
    price: item.price_egp_monthly || item.price || 0,
    location: {
      address: item.address || item.location?.address || 'مصر',
      city: item.city || item.location?.city || 'القاهرة',
      coordinates: item.location?.coordinates || item.coordinates,
    },
    features: {
      bedrooms: item.rooms || item.features?.bedrooms || 2,
      bathrooms: item.bathrooms || item.features?.bathrooms || 1,
      area: item.area_sqm || item.features?.area || 100,
      furnished: Boolean(item.furnished ?? item.features?.furnished),
      airCondition: Boolean(item.features?.airCondition),
      parking: Boolean(item.features?.parking),
      elevator: Boolean(item.features?.elevator),
    },
    amenities: item.features || item.amenities || [],
    images: Array.isArray(item.images) && item.images.length ? item.images : ['assets/images/home1.jpg'],
    owner: admin._id,
  }));

  await Property.insertMany(docs);
  console.log(`Seeded ${docs.length} properties.`);
}

async function main() {
  try {
    if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI is missing');
    await mongoose.connect(process.env.MONGODB_URI);
    await seed();
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
}

if (require.main === module) {
  main();
}

module.exports = seed;
