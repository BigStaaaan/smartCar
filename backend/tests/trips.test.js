jest.mock('../src/config/firebase', () => ({
  auth: () => ({
    async verifyIdToken(token) {
      if (!['driver-a', 'driver-b', 'driver-empty', 'driver-closed', 'driver-complete'].includes(token)) {
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
      ...['trip-to-complete', 'trip-private-active'].map((id) => ({
        id,
        ownerId: 'driver-complete',
        status: 'in_progress',
        details: {
          origin: 'Gare',
          destination: 'Campus',
          departureAt: '2099-03-05T09:00:00.000Z',
          vehicleId: 'vehicle-complete',
          seats: 2,
          contributionDh: 15,
        },
      })),
      ...[
        ['trip-completed', 'completed'],
        ['trip-cancelled', 'cancelled'],
        ['trip-due', 'published'],
        ['trip-exact-departure', 'published'],
      ].map(([id, status]) => ({
        id,
        ownerId: 'driver-closed',
        status,
        details: {
          origin: 'Gare',
          destination: 'Campus',
          departureAt: '2000-03-05T09:00:00.000Z',
          vehicleId: 'vehicle-empty',
          seats: 1,
        },
      })),
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

function editTrip(id, body, token = 'driver-a') {
  return request('PATCH', '/' + id, token, body);
}

async function publishedTrip(vehicleId = createVehicle('driver-a').id) {
  const result = await publish(publicationInput(vehicleId));
  expect(result.status).toBe(201);
  return result.data;
}

test('patches all editable fields and retains the id and published status', async () => {
  const original = await publishedTrip();
  const replacement = createVehicle('driver-a');
  const changes = {
    origin: '  Université  ',
    destination: 'Centre',
    departureAt: new Date(Date.now() + 172800000).toISOString(),
    vehicleId: replacement.id,
    seats: 1,
    contributionDh: 20,
  };
  const result = await editTrip(original.id, changes);
  expect(result.status).toBe(200);
  expect(result.data).toEqual({
    id: original.id,
    status: 'published',
    details: { ...changes, origin: 'Université' },
  });
  expect((await get('/' + original.id)).data).toEqual(result.data);
  expect((await get()).data).toContainEqual(result.data);
});

test('patches only the supplied fields, including clearing the contribution', async () => {
  const original = await publishedTrip();
  const result = await editTrip(original.id, { seats: 1, contributionDh: null });
  expect(result.status).toBe(200);
  expect(result.data).toEqual({
    ...original,
    details: { ...original.details, seats: 1, contributionDh: null },
  });
});

test('rejects unauthenticated edits and hides private trips', async () => {
  const original = await publishedTrip();
  const changes = { origin: 'Centre' };
  expect((await editTrip(original.id, changes, null)).status).toBe(401);
  expect((await editTrip(original.id, changes, 'invalid')).status).toBe(401);
  const foreign = await editTrip(original.id, changes, 'driver-b');
  const missing = await editTrip('missing', changes, 'driver-b');
  expect(foreign).toEqual(missing);
  expect(foreign.status).toBe(404);
  expect((await get('/' + original.id)).data).toEqual(original);
});

test('rejects a foreign vehicle or insufficient capacity without changing the trip', async () => {
  const original = await publishedTrip();
  const foreign = createVehicle('driver-b');
  const small = vehicles.create('driver-a', { passengerCapacity: 1 });

  expect((await editTrip(original.id, { vehicleId: foreign.id })).status).toBe(404);
  expect((await editTrip(original.id, { vehicleId: 'missing' })).status).toBe(404);
  expect((await editTrip(original.id, { vehicleId: small.id })).status).toBe(400);
  expect((await editTrip(original.id, { seats: 3 })).status).toBe(400);
  expect((await get('/' + original.id)).data).toEqual(original);

  const result = await editTrip(original.id, { vehicleId: small.id, seats: 1 });
  expect(result.status).toBe(200);
  expect(result.data.details).toMatchObject({ vehicleId: small.id, seats: 1 });
});

test.each([
  ['empty body', {}],
  ['blank origin', { origin: ' ' }],
  ['same locations after merging', { destination: ' gArE ' }],
  ['invalid departure format', { departureAt: '2099-03-05' }],
  ['departure in the past', { departureAt: '2000-03-05T09:00:00Z' }],
  ['zero seats', { seats: 0 }],
  ['fractional seats', { seats: 1.5 }],
  ['negative contribution', { contributionDh: -1 }],
  ['contribution over 40 DH', { contributionDh: 41 }],
  ['fractional contribution', { contributionDh: 1.5 }],
  ['owner override', { ownerId: 'driver-b' }],
  ['id override', { id: 'new-id' }],
  ['status override', { status: 'published' }],
])('rejects %s without changing the original trip', async (_label, changes) => {
  const original = await publishedTrip();
  expect((await editTrip(original.id, changes)).status).toBe(400);
  expect((await get('/' + original.id)).data).toEqual(original);
});

test.each([
  ['trip-b', 'driver-b', 'in_progress'],
  ['trip-completed', 'driver-closed', 'completed'],
  ['trip-cancelled', 'driver-closed', 'cancelled'],
  ['trip-due', 'driver-closed', 'published'],
])('rejects editing an ineligible trip %s', async (id, owner, status) => {
  const original = await get('/' + id, owner);
  expect(original.data.status).toBe(status);
  const result = await editTrip(id, { origin: 'Centre modifié' }, owner);
  expect(result.status).toBe(409);
  expect((await get('/' + id, owner)).data).toEqual(original.data);
});

function tripAction(action, id, token = 'driver-a', body) {
  return request('PATCH', '/' + id + '/' + action, token, body);
}

function cancelTrip(id, token, body) {
  return tripAction('cancel', id, token, body);
}

test('cancels an upcoming trip, keeps its details and exposes its status through GET', async () => {
  const original = await publishedTrip();
  const result = await cancelTrip(original.id);
  expect(result.status).toBe(200);
  expect(result.data).toEqual({ ...original, status: 'cancelled' });
  expect((await get('/' + original.id)).data).toEqual(result.data);
  expect((await get()).data).toContainEqual(result.data);
  expect((await cancelTrip(original.id)).status).toBe(409);
  expect((await get('/' + original.id)).data).toEqual(result.data);
});

test('requires authentication and returns the same 404 for foreign and missing trips', async () => {
  const original = await publishedTrip();
  expect((await cancelTrip(original.id, null)).status).toBe(401);
  expect((await cancelTrip(original.id, 'invalid')).status).toBe(401);
  const foreign = await cancelTrip(original.id, 'driver-b');
  const missing = await cancelTrip('missing', 'driver-b');
  expect(foreign.status).toBe(404);
  expect(foreign).toEqual(missing);
  expect((await get('/' + original.id)).data).toEqual(original);
});

test.each([
  ['trip-b', 'driver-b'],
  ['trip-completed', 'driver-closed'],
  ['trip-cancelled', 'driver-closed'],
  ['trip-due', 'driver-closed'],
])('refuses cancellation based on the trip status or date for %s', async (id, owner) => {
  const original = await get('/' + id, owner);
  expect(original.status).toBe(200);
  expect((await cancelTrip(id, owner, {})).status).toBe(409);
  expect((await get('/' + id, owner)).data).toEqual(original.data);
});

test('rejects attempts to change the trip through the cancellation body', async () => {
  const original = await publishedTrip();
  for (const body of [{ status: 'cancelled' }, { ownerId: 'driver-b' }, { origin: 'Centre' }]) {
    expect((await cancelTrip(original.id, 'driver-a', body)).status).toBe(400);
  }
  expect((await get('/' + original.id)).data).toEqual(original);
});

function startTrip(id, token, body) {
  return tripAction('start', id, token, body);
}

test.each([
  ['trip-exact-departure', 0],
  ['trip-due', 60000],
])('starts a published trip at or after departure (%s)', async (id, delay) => {
  const owner = 'driver-closed';
  const original = await get('/' + id, owner);
  expect(original.status).toBe(200);
  const departure = Date.parse(original.data.details.departureAt);
  const clock = jest.spyOn(Date, 'now').mockReturnValue(departure + delay);
  try {
    const result = await startTrip(id, owner);
    expect(result.status).toBe(200);
    expect(result.data).toEqual({ ...original.data, status: 'in_progress' });
    expect((await get('/' + id, owner)).data).toEqual(result.data);
    expect((await get('', owner)).data).toContainEqual(result.data);
    expect((await startTrip(id, owner)).status).toBe(409);
  } finally {
    clock.mockRestore();
  }
});

test('rejects an early start without changing the trip', async () => {
  const original = await publishedTrip();
  expect((await startTrip(original.id)).status).toBe(409);
  expect((await get('/' + original.id)).data).toEqual(original);
});

test('requires authentication and hides another driver’s trip', async () => {
  const original = await publishedTrip();
  expect((await startTrip(original.id, null)).status).toBe(401);
  expect((await startTrip(original.id, 'invalid')).status).toBe(401);
  const foreign = await startTrip(original.id, 'driver-b');
  const missing = await startTrip('missing', 'driver-b');
  expect(foreign.status).toBe(404);
  expect(foreign).toEqual(missing);
  expect((await get('/' + original.id)).data).toEqual(original);
});

test.each([
  ['trip-b', 'driver-b'],
  ['trip-completed', 'driver-closed'],
  ['trip-cancelled', 'driver-closed'],
])('rejects starting a trip with an ineligible status (%s)', async (id, owner) => {
  const original = await get('/' + id, owner);
  expect(original.status).toBe(200);
  expect((await startTrip(id, owner, {})).status).toBe(409);
  expect((await get('/' + id, owner)).data).toEqual(original.data);
});

test('rejects fields in the start request body', async () => {
  const original = await publishedTrip();
  for (const body of [{ status: 'in_progress' }, { ownerId: 'driver-b' }, { seats: 1 }]) {
    expect((await startTrip(original.id, 'driver-a', body)).status).toBe(400);
  }
  expect((await get('/' + original.id)).data).toEqual(original);
});

function completeTrip(id, token, body) {
  return tripAction('complete', id, token, body);
}

test('completes an in-progress trip and preserves its details in both GET routes', async () => {
  const owner = 'driver-complete';
  const id = 'trip-to-complete';
  const original = await get('/' + id, owner);
  expect(original.data.status).toBe('in_progress');

  const completed = await completeTrip(id, owner);
  expect(completed.status).toBe(200);
  expect(completed.data).toEqual({ ...original.data, status: 'completed' });
  expect((await get('/' + id, owner)).data).toEqual(completed.data);
  expect((await get('', owner)).data).toContainEqual(completed.data);
  expect((await completeTrip(id, owner)).status).toBe(409);
  expect((await get('/' + id, owner)).data).toEqual(completed.data);
});

test('requires authentication and hides another driver’s trip on completion', async () => {
  const owner = 'driver-complete';
  const id = 'trip-private-active';
  const original = await get('/' + id, owner);
  expect(original.data.status).toBe('in_progress');
  expect((await completeTrip(id, null)).status).toBe(401);
  expect((await completeTrip(id, 'invalid')).status).toBe(401);

  const foreign = await completeTrip(id, 'driver-a');
  const missing = await completeTrip('missing', 'driver-a');
  expect(foreign.status).toBe(404);
  expect(foreign).toEqual(missing);
  expect((await get('/' + id, owner)).data).toEqual(original.data);
});

test('rejects completing a trip that is still published', async () => {
  const original = await publishedTrip();
  expect((await completeTrip(original.id)).status).toBe(409);
  expect((await get('/' + original.id)).data).toEqual(original);
});

test.each(['trip-completed', 'trip-cancelled'])(
  'rejects completing an ineligible trip (%s)', async (id) => {
    const owner = 'driver-closed';
    const original = await get('/' + id, owner);
    expect(original.status).toBe(200);
    expect((await completeTrip(id, owner, {})).status).toBe(409);
    expect((await get('/' + id, owner)).data).toEqual(original.data);
  },
);

test('rejects fields in the completion request body', async () => {
  const owner = 'driver-complete';
  const id = 'trip-private-active';
  const original = await get('/' + id, owner);
  expect(original.data.status).toBe('in_progress');

  for (const body of [{ status: 'completed' }, { ownerId: 'driver-a' }, { seats: 1 }]) {
    expect((await completeTrip(id, owner, body)).status).toBe(400);
  }
  expect((await get('/' + id, owner)).data).toEqual(original.data);
});
