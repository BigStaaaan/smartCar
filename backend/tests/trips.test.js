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

async function get(path = '', token = 'driver-a') {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  const response = await fetch(baseUrl + path, { headers });
  return {
    status: response.status,
    cacheControl: response.headers.get('cache-control'),
    data: await response.json(),
  };
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
