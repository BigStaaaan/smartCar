jest.mock('../src/config/firebase', () => ({
  auth: () => ({
    async verifyIdToken(token) {
      if (!/^(driver|other)-\d+$/.test(token)) throw new Error('Invalid token');
      return { uid: token };
    },
  }),
}));

jest.mock('../src/repositories/vehicles/vehicles.repository', () =>
  require('./support/memory-vehicles'));

const app = require('../src/app');

const vehicleInput = {
  make: 'Renault',
  model: 'Clio',
  color: 'Bleue',
  year: 2021,
  registrationNumber: '12345 ب 33',
  passengerCapacity: 4,
};
const png = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jFFcAAAAASUVORK5CYII=',
  'base64',
);

let server;
let baseUrl;
let scenario = 0;
let driver;
let other;

beforeAll(async () => {
  await new Promise((resolve, reject) => {
    server = app.listen(0, '127.0.0.1', resolve);
    server.once('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}/api/v1/vehicles`;
});

afterAll(async () => {
  if (server?.listening) {
    await new Promise((resolve, reject) =>
      server.close((error) => (error ? reject(error) : resolve())));
  }
});

beforeEach(() => {
  scenario++;
  driver = `driver-${scenario}`;
  other = `other-${scenario}`;
});

async function request(method, path = '', { token = driver, body } = {}) {
  const headers = token ? { Authorization: `Bearer ${token}` } : {};
  if (body && !(body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(body);
  }
  const response = await fetch(baseUrl + path, { method, headers, body });
  return {
    status: response.status,
    cacheControl: response.headers.get('cache-control'),
    data: response.status === 204 ? null : await response.json(),
  };
}

test('requires a valid Firebase bearer token', async () => {
  expect((await request('GET', '', { token: null })).status).toBe(401);
  expect((await request('POST', '', { token: 'bad', body: vehicleInput })).status)
    .toBe(401);
});

test('creates, lists, reads, patches and deletes a vehicle', async () => {
  expect(await request('GET')).toMatchObject({ status: 200, data: [] });
  const created = await request('POST', '', { body: vehicleInput });
  expect(created).toMatchObject({
    status: 201,
    data: { ...vehicleInput, registrationNumber: '12345 | ب | 33' },
  });
  expect(created.data).not.toHaveProperty('ownerId');
  const path = '/' + created.data.id;
  expect(await request('GET')).toMatchObject({ data: [{ id: created.data.id }] });
  expect(await request('GET', path)).toMatchObject({ status: 200, data: created.data });

  expect(await request('PATCH', path, { body: { color: ' Grise ', year: null } }))
    .toMatchObject({ status: 200, data: { make: 'Renault', color: 'Grise', year: null } });
  expect(await request('DELETE', path)).toMatchObject({ status: 204, data: null });
  expect((await request('GET', path)).status).toBe(404);
  expect(await request('GET')).toMatchObject({ status: 200, data: [] });
});

test('isolates all vehicle operations between drivers', async () => {
  const { data: { id } } = await request('POST', '', { body: vehicleInput });
  const path = '/' + id;
  await request('POST', '', { token: other, body: { ...vehicleInput, model: 'Captur' } });

  expect(await request('GET', '', { token: other })).toMatchObject({
    status: 200, data: [{ model: 'Captur' }],
  });
  expect((await request('GET', path, { token: other })).status).toBe(404);
  expect((await request('PATCH', path, { token: other, body: { color: 'Rouge' } })).status)
    .toBe(404);
  expect((await request('DELETE', path, { token: other })).status).toBe(404);
  expect(await request('GET', path)).toMatchObject({ data: { color: 'Bleue' } });
});

test.each([
  { make: '   ' },
  { color: null },
  { year: 1899 },
  { year: new Date().getFullYear() + 2 },
  { registrationNumber: '123456 | A | 333' },
  { registrationNumber: '123 | ١ | 3' },
  { passengerCapacity: 0 },
  { passengerCapacity: 2.5 },
  { ownerId: 'spoofed' },
  { registrationPhoto: 'untrusted-json' },
])('rejects invalid creation fields %j', async (fields) => {
  const result = await request('POST', '', { body: { ...vehicleInput, ...fields } });
  expect(result.status).toBe(400);
  expect(Array.isArray(result.data.error)).toBe(true);
  expect(result.data.error).toHaveLength(1);
});

test('rejects missing mandatory fields, empty patches and owner overrides', async () => {
  expect((await request('POST', '', { body: { make: 'Renault' } })).status).toBe(400);
  const { data: { id } } = await request('POST', '', { body: vehicleInput });
  expect((await request('PATCH', '/' + id, { body: {} })).status).toBe(400);
  expect((await request('PATCH', '/' + id, { body: { ownerId: other } })).status)
    .toBe(400);
  expect((await request('PATCH', '/' + id, { body: { passengerCapacity: 0 } })).status)
    .toBe(400);
  expect((await request('GET', '/' + id)).status).toBe(200);
});

test('keeps registration images out of lists and limits access to the owner', async () => {
  const body = new FormData();
  for (const [key, value] of Object.entries(vehicleInput)) body.set(key, String(value));
  body.set('photo', new Blob([png], { type: 'image/png' }), 'vehicle.png');
  body.set('registrationPhoto', new Blob([png], { type: 'image/png' }), 'registration.png');

  const created = await request('POST', '', { body });
  expect(created).toMatchObject({
    status: 201,
    cacheControl: 'no-store',
    data: { photo: png.toString('base64'), hasRegistrationPhoto: true },
  });
  const path = '/' + created.data.id;
  const list = await request('GET');
  expect(list.data[0]).not.toHaveProperty('registrationPhoto');
  expect(await request('GET', path)).toMatchObject({
    status: 200,
    cacheControl: 'no-store',
    data: { registrationPhoto: png.toString('base64') },
  });
  const denied = await request('GET', path, { token: other });
  expect(denied.status).toBe(404);
  expect(denied.data).not.toHaveProperty('registrationPhoto');

  const replacement = new FormData();
  replacement.set('registrationPhoto', new Blob([png], { type: 'image/png' }), 'replacement.png');
  expect((await request('PATCH', path, { body: replacement })).status).toBe(200);
  expect(await request('PATCH', path, { body: { removeRegistrationPhoto: true } }))
    .toMatchObject({ status: 200, data: { registrationPhoto: null, hasRegistrationPhoto: false } });
});

test('rejects unsupported documents and uploads over the per-file limit', async () => {
  const { data: { id } } = await request('POST', '', { body: vehicleInput });
  const form = new FormData();
  form.set('registrationPhoto', new Blob(['data'], { type: 'text/plain' }), 'doc.txt');
  expect((await request('PATCH', '/' + id, { body: form })).status).toBe(400);

  form.set('registrationPhoto', new Blob(['data'], { type: 'image/png' }), 'false.png');
  expect((await request('PATCH', '/' + id, { body: form })).status).toBe(400);

  form.set('registrationPhoto',
    new Blob([Buffer.alloc(2 * 1024 * 1024 + 1)], { type: 'image/png' }), 'big.png');
  expect((await request('PATCH', '/' + id, { body: form })).status).toBe(413);
});
