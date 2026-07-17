(function () {
  const DEFAULT_CENTER = { lat: 26.8206, lng: 30.8025 }; // Egypt
  const NOMINATIM_DELAY = 1000;
  let lastNominationCall = 0;

  function wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function normalizeQuery(value) {
    return String(value || '').trim().replace(/\s+/g, ' ');
  }

  async function nominatimFetch(path, params) {
    const now = Date.now();
    const delta = now - lastNominationCall;
    if (delta < NOMINATIM_DELAY) await wait(NOMINATIM_DELAY - delta);
    lastNominationCall = Date.now();

    const url = new URL(`https://nominatim.openstreetmap.org/${path}`);
    Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, value));

    const res = await fetch(url.toString(), {
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'EjariWeb/1.0'
      }
    });
    if (!res.ok) throw new Error(`Nominatim failed: ${res.status}`);
    return res.json();
  }

  async function geocodeAddress(address) {
    const q = normalizeQuery(address);
    if (!q) return null;
    const results = await nominatimFetch('search', {
      format: 'jsonv2',
      limit: '1',
      q,
    });
    const item = results && results[0];
    if (!item) return null;
    return {
      lat: Number(item.lat),
      lng: Number(item.lon),
      displayName: item.display_name,
      boundingBox: item.boundingbox,
    };
  }

  async function searchLocation(query) {
    const q = normalizeQuery(query);
    if (!q) return [];
    const results = await nominatimFetch('search', {
      format: 'jsonv2',
      limit: '5',
      q,
    });
    return Array.isArray(results)
      ? results.map((item) => ({
          lat: Number(item.lat),
          lng: Number(item.lon),
          displayName: item.display_name,
        }))
      : [];
  }

  function initMap(mapContainerId, options = {}) {
    if (!window.google || !window.google.maps) {
      console.warn('Google Maps API is not loaded.');
      return null;
    }
    const mapContainer = document.getElementById(mapContainerId);
    if (!mapContainer) return null;

    const map = new window.google.maps.Map(mapContainer, {
      center: options.center || DEFAULT_CENTER,
      zoom: options.zoom || 6,
      mapTypeControl: false,
      streetViewControl: true,
      fullscreenControl: true,
    });
    window.EjariMap = map;
    return map;
  }

  function buildMarkerContent(apartment) {
    return `
      <div style="min-width:160px;direction:rtl;text-align:right;font-family:Cairo,Arial,sans-serif">
        <strong>${apartment.title || 'وحدة سكنية'}</strong>
        <div style="margin-top:6px;color:#1f6b63">${Number(apartment.price_egp_monthly || apartment.price || 0).toLocaleString('ar-EG')} ج.م / شهر</div>
      </div>
    `;
  }

  function addMarkers(apartments = [], map = window.EjariMap) {
    if (!map || !window.google || !window.google.maps) return [];
    const infoWindow = new window.google.maps.InfoWindow();
    return apartments
      .filter((apartment) => apartment?.location?.coordinates || (apartment.lat && apartment.lng))
      .map((apartment) => {
        const lng = apartment?.location?.coordinates?.coordinates?.[0] ?? apartment.lng;
        const lat = apartment?.location?.coordinates?.coordinates?.[1] ?? apartment.lat;
        const marker = new window.google.maps.Marker({
          position: { lat: Number(lat), lng: Number(lng) },
          map,
          title: apartment.title,
        });
        marker.addListener('click', () => {
          infoWindow.setContent(buildMarkerContent(apartment));
          infoWindow.open({ anchor: marker, map });
        });
        return marker;
      });
  }

  function filterByMapBounds(apartments = [], map = window.EjariMap) {
    const bounds = map?.getBounds?.();
    if (!bounds || typeof bounds.contains !== 'function') return apartments;
    return apartments.filter((apartment) => {
      const lng = apartment?.location?.coordinates?.coordinates?.[0] ?? apartment.lng;
      const lat = apartment?.location?.coordinates?.coordinates?.[1] ?? apartment.lat;
      const point = new window.google.maps.LatLng(Number(lat), Number(lng));
      return bounds.contains(point);
    });
  }

  function mountLeafletMap(mapContainerId, apartments = [], options = {}) {
    if (!window.L) {
      console.warn('Leaflet is not loaded.');
      return null;
    }
    const mapContainer = document.getElementById(mapContainerId);
    if (!mapContainer) return null;

    const map = window.L.map(mapContainerId).setView(
      [options.center?.lat || DEFAULT_CENTER.lat, options.center?.lng || DEFAULT_CENTER.lng],
      options.zoom || 6
    );

    window.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);

    apartments.forEach((apartment) => {
      const lng = apartment?.location?.coordinates?.coordinates?.[0] ?? apartment.lng;
      const lat = apartment?.location?.coordinates?.coordinates?.[1] ?? apartment.lat;
      if (!Number.isFinite(Number(lat)) || !Number.isFinite(Number(lng))) return;
      const marker = window.L.marker([Number(lat), Number(lng)]).addTo(map);
      marker.bindPopup(`<strong>${apartment.title || 'وحدة سكنية'}</strong><br>${Number(apartment.price_egp_monthly || apartment.price || 0).toLocaleString('ar-EG')} ج.م / شهر`);
    });

    return map;
  }

  window.EjariAPI = {
    geocodeAddress,
    searchLocation,
    initMap,
    addMarkers,
    filterByMapBounds,
    mountLeafletMap,
  };
})();
