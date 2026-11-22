jest.mock('../src/config/firebase', () => ({
  auth: () => ({
    async verifyIdToken(token) {
      if (!['driver-a', 'driver-b', 'driver-empty'].includes(token)) {
        throw new Error('Invalid token');
      }
      return { uid: token };
    },
  }),
}));

jest.mock('../src/repositories/trips/trips.repository', () => {
  const { createTripsRepository } = jest.requireActual('../src/repositories/trips/trips.repository');
  return {
    tripsRepository: createTripsRepository([
      {
        id: 'trip-a',
        ownerId: 'driver-a',
        status: 'published',
        details: {
          origin: 'Gare',
          destination: 'Campus',
          departureAt: '2027-03-05T09:00:00.000Z',
          vehicleId: 'vehicle-a',
          seats: 2,
          contributionDh: 15,
        },
      },
      {
        id: 'trip-b',
        ownerId: 'driver-b',
        status: 'in_progress',
        details: {
          origin: 'Centre',
          destination: 'Université',
          departureAt: '2027-03-05T10:00:00.000Z',
          vehicleId: 'vehicle-b',
          seats: 1,
        },
      },
    ]),
  };
});

const app = require('../src/app');
const vehicles = require('../src/repositories/vehicles/vehicles.repository');

let server;
let baseUrl;

beforeAll(async () => {
  await new Promise((resolve, reject) => {
    server = app.listen(0, '127.0.0.1', resolve);
    server.once('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}/api/v1/trips`;
});

afterAll(async () => {
  if (server?.listening) {
    await new Promise((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())));
  }
});

async function request(method, path, token, body) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  if (body) headers['Content-Type'] = 'application/json';
  const response = await fetch(baseUrl + path, {
    method,
    headers,
    body: body && JSON.stringify(body),
  });
  return {
    status: response.status,
    cacheControl: response.headers.get('cache-control'),
    data: await response.json(),
  };
}

function get(path = '', token = 'driver-a') {
  return request('GET', path, token);
}

test.each(['', '/trip-a'])('requires valid authentication on GET /trips%s', async (path) => {
  expect((await get(path, null)).status).toBe(401);
  expect((await get(path, 'invalid')).status).toBe(401);
});

test('lists only trips owned by the identity from the Firebase token', async () => {
  const first = await get('?ownerId=driver-b');
  expect(first.status).toBe(200);
  expect(first.cacheControl).toBe('no-store');
  expect(first.data.map((trip) => trip.id)).toEqual(['trip-a']);
  expect(first.data[0]).not.toHaveProperty('ownerId');

  const second = await get('', 'driver-b');
  expect(second.data.map((trip) => trip.id)).toEqual(['trip-b']);
  expect(second.data[0].details.contributionDh).toBeNull();

  const empty = await get('', 'driver-empty');
  expect(empty.status).toBe(200);
  expect(empty.data).toHaveLength(0);
});

test('returns the trip status and details to its owner', async () => {
  const result = await get('/trip-a');
  expect(result).toMatchObject({
    status: 200,
    cacheControl: 'no-store',
    data: {
      id: 'trip-a',
      status: 'published',
      details: {
        origin: 'Gare',
        destination: 'Campus',
        departureAt: '2027-03-05T09:00:00.000Z',
        vehicleId: 'vehicle-a',
        seats: 2,
        contributionDh: 15,
      },
    },
  });
  expect(result.data).not.toHaveProperty('ownerId');
});

test('returns the same 404 for a private trip and an unknown trip', async () => {
  const foreign = await get('/trip-a?ownerId=driver-a', 'driver-b');
  const missing = await get('/missing', 'driver-b');
  expect(foreign).toEqual(missing);
  expect(foreign.status).toBe(404);
});

function publish(body, token = 'driver-a') {
  return request('POST', '', token, body);
}

function publicationInput(vehicleId) {
  return {
    origin: '  Gare  ',
    destination: '  Campus  ',
    departureAt: new Date(Date.now() + 86400000).toISOString(),
    vehicleId,
    seats: 2,
    contributionDh: 40,
  };
}

function createVehicle(ownerId) {
  return vehicles.create(ownerId, { passengerCapacity: 2 });
}

test('publishes an authenticated trip and exposes it in both owner GET routes', async () => {
  const input = publicationInput(createVehicle('driver-a').id);
  const result = await publish(input);
  expect(result.status).toBe(201);
  expect(result.data).toMatchObject({
    id: expect.any(String),
    status: 'published',
    details: { ...input, origin: 'Gare', destination: 'Campus' },
  });
  expect(result.data).not.toHaveProperty('ownerId');
  const path = '/' + result.data.id;
  expect((await get(path)).data).toEqual(result.data);
  expect((await get()).data).toContainEqual(result.data);
  expect((await get(path, 'driver-b')).status).toBe(404);
});

test('normalizes a departure with an offset and a zero contribution', async () => {
  const input = publicationInput(createVehicle('driver-a').id);
  const withOffset = input.departureAt.replace('Z', '-02:00');
  const result = await publish({ ...input, departureAt: withOffset, contributionDh: 0 });
  expect(result.status).toBe(201);
  expect(result.data.details).toMatchObject({
    departureAt: new Date(withOffset).toISOString(),
    contributionDh: null,
  });
});

test('requires authentication to publish', async () => {
  const input = publicationInput(createVehicle('driver-a').id);
  expect((await publish(input, null)).status).toBe(401);
  expect((await publish(input, 'invalid')).status).toBe(401);
});

test('returns the same 404 for a foreign vehicle and a missing vehicle', async () => {
  const foreign = await publish(publicationInput(createVehicle('driver-b').id));
  const missing = await publish(publicationInput('missing'));
  expect(foreign.status).toBe(404);
  expect(foreign.data).toEqual(missing.data);
  expect(missing.status).toBe(404);
});

test.each([
  ['blank origin', { origin: '   ' }],
  ['missing destination', { destination: undefined }],
  ['same locations', { destination: 'gArE' }],
  ['date without time', { departureAt: '2099-03-05' }],
  ['time without time zone', { departureAt: '2099-03-05T09:00:00' }],
  ['impossible date', { departureAt: '2099-02-30T09:00:00Z' }],
  ['departure in the past', { departureAt: '2000-03-05T09:00:00Z' }],
  ['zero seats', { seats: 0 }],
  ['fractional seats', { seats: 1.5 }],
  ['capacity exceeded', { seats: 3 }],
  ['negative contribution', { contributionDh: -1 }],
  ['contribution above 40 DH', { contributionDh: 41 }],
  ['fractional contribution', { contributionDh: 12.5 }],
  ['owner override', { ownerId: 'driver-b' }],
  ['status override', { status: 'completed' }],
])('rejects %s without storing a trip', async (_label, changes) => {
  const input = publicationInput(createVehicle('driver-a').id);
  const before = (await get()).data;
  const result = await publish({ ...input, ...changes });
  expect(result.status).toBe(400);
  expect((await get()).data).toEqual(before);
});
