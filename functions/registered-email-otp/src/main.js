import { Account, Client, ID, Query, TablesDB, Users } from 'node-appwrite';

const databaseId = process.env.DEEP_CARE_DATABASE_ID || '6acbac6a0016d4551f12';
const tableIds = {
  profiles: process.env.DEEP_CARE_USER_PROFILES_TABLE || '6acbad45001b46bb01cd',
  services: process.env.DEEP_CARE_SERVICES_TABLE || '6acf9e8d0034d5ede54b',
  providers: process.env.DEEP_CARE_PROVIDER_PROFILES_TABLE || '6acfa26a0014413c2ddc',
  orders: process.env.DEEP_CARE_ORDERS_TABLE || '6acfa6620002e1667c9d',
  events: process.env.DEEP_CARE_ORDER_EVENTS_TABLE || '6acfad54000fe0c6131f',
  counters: process.env.DEEP_CARE_BOOKING_COUNTERS_TABLE || '6adba477000bac6a2804',
};

export default async ({ req, res, error }) => {
  const path = normalizePath(req.path);
  if (path === '/') return handleRegisteredEmailOtp({ req, res, error });
  return handleCareApi({ req, res, error, path });
};

async function handleCareApi({ req, res, error, path }) {
  try {
    const userJwt = req.headers?.['x-appwrite-user-jwt'];
    const functionKey = req.headers?.['x-appwrite-key'];
    if (!userJwt || !functionKey) {
      return res.json({ message: 'Sign in to use the care service.' }, 401);
    }

    const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
    const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
    if (!endpoint || !projectId) {
      return res.json({ message: 'The backend is not configured.' }, 500);
    }

    const sessionClient = new Client().setEndpoint(endpoint).setProject(projectId).setJWT(userJwt);
    const user = await new Account(sessionClient).get();
    const tables = new TablesDB(
      new Client().setEndpoint(endpoint).setProject(projectId).setKey(functionKey),
    );
    const actorId = user.$id;
    const profile = await findProfile(tables, actorId);
    const role = profile?.role ?? null;
    const method = req.method.toUpperCase();
    const body = req.bodyJson && typeof req.bodyJson === 'object' ? req.bodyJson : {};

    if (method === 'GET' && path === '/services') {
      const rows = (await listRows(tables, 'services'))
        .filter((row) => row.isActive === true)
        .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));
      return res.json({ rows });
    }

    if (method === 'POST' && path === '/profile/sync') {
      const name = cleanText(body.name, 120);
      const phone = cleanText(body.phone, 32);
      if (!name) return res.json({ message: 'Your name is required.' }, 400);
      const data = { userId: actorId, name, role: profile?.role ?? 'client' };
      if (phone) data.phone = phone;
      if (['Woman', 'Man', 'Non-binary', 'Prefer not to say'].includes(body.gender)) data.gender = body.gender;
      if (Number.isInteger(body.age) && body.age >= 1 && body.age <= 150) data.age = body.age;
      let saved;
      if (profile) {
        if (!phone && !profile.phone) return res.json({ message: 'Add a phone number to your profile before booking.' }, 400);
        saved = await tables.updateRow({ databaseId, tableId: tableIds.profiles, rowId: profile.$id, data });
      } else {
        if (!phone) return res.json({ message: 'A phone number is required to create your care profile.' }, 400);
        saved = await tables.createRow({ databaseId, tableId: tableIds.profiles, rowId: ID.unique(), data });
      }
      return res.json({ row: saved });
    }

    if (!profile) return res.json({ message: 'Your account profile is not ready. Sign in again.' }, 403);

    if (method === 'GET' && path === '/orders') {
      if (role !== 'client') return res.json({ message: 'Client access is required.' }, 403);
      const rows = await listRows(tables, 'orders', [Query.equal('clientUserId', actorId), Query.limit(100)]);
      rows.sort((a, b) => new Date(b.$createdAt) - new Date(a.$createdAt));
      return res.json({ rows });
    }

    if (method === 'POST' && path === '/orders') {
      if (role !== 'client') return res.json({ message: 'Only client accounts can create a booking.' }, 403);
      return createOrder(tables, actorId, body, res);
    }

    const eventsMatch = path.match(/^\/orders\/([^/]+)\/events$/);
    if (method === 'GET' && eventsMatch) {
      const order = await getRow(tables, 'orders', eventsMatch[1]);
      if (!canReadOrder(order, actorId, role)) return res.json({ message: 'Booking not found.' }, 404);
      const rows = await listRows(tables, 'events', [Query.equal('orderId', order.$id), Query.limit(100)]);
      rows.sort((a, b) => new Date(a.$createdAt) - new Date(b.$createdAt));
      return res.json({ rows });
    }

    const cancelMatch = path.match(/^\/orders\/([^/]+)\/cancel$/);
    if (method === 'POST' && cancelMatch) {
      const order = await getRow(tables, 'orders', cancelMatch[1]);
      if (role !== 'admin' && !(role === 'client' && order.clientUserId === actorId)) {
        return res.json({ message: 'You cannot cancel this booking.' }, 403);
      }
      if (!['pending_assignment', 'assigned', 'accepted'].includes(order.status)) {
        return res.json({ message: 'This booking can no longer be cancelled in the app.' }, 409);
      }
      const updated = await changeOrder(tables, order, { status: 'cancelled' }, {
        actorUserId: actorId, eventType: 'cancelled', newStatus: 'cancelled', note: cleanText(body.note, 500),
      });
      return res.json({ row: updated });
    }

    const providerProfileMatch = path === '/provider/profile';
    if (method === 'GET' && providerProfileMatch) {
      if (role !== 'provider') return res.json({ message: 'This account is not registered as a provider.' }, 403);
      const row = await findProvider(tables, actorId);
      return row ? res.json({ row }) : res.json({ row: null }, 404);
    }
    if (method === 'POST' && providerProfileMatch) {
      if (role !== 'provider') return res.json({ message: 'This account is not registered as a provider.' }, 403);
      const businessName = cleanText(body.businessName, 120);
      const serviceIds = uniqueStrings(body.serviceIds, 255);
      const serviceAreas = uniqueStrings(body.serviceAreas, 100);
      if (!businessName || !serviceIds.length || !serviceAreas.length) {
        return res.json({ message: 'Business name, at least one service, and one service area are required.' }, 400);
      }
      const current = await findProvider(tables, actorId);
      const data = { userId: actorId, businessName, serviceIds, serviceAreas };
      const row = current
        ? await tables.updateRow({ databaseId, tableId: tableIds.providers, rowId: current.$id, data })
        : await tables.createRow({ databaseId, tableId: tableIds.providers, rowId: ID.unique(), data: { ...data, verificationStatus: 'pending', isAvailable: false, completedOrderCount: 0 } });
      return res.json({ row });
    }

    if (method === 'POST' && path === '/provider/availability') {
      if (role !== 'provider' || typeof body.isAvailable !== 'boolean') return res.json({ message: 'Invalid provider availability request.' }, 400);
      const provider = await findProvider(tables, actorId);
      if (!provider || provider.verificationStatus !== 'verified') return res.json({ message: 'Your provider profile must be verified first.' }, 403);
      const row = await tables.updateRow({ databaseId, tableId: tableIds.providers, rowId: provider.$id, data: { isAvailable: body.isAvailable } });
      return res.json({ row });
    }

    if (method === 'GET' && path === '/provider/orders') {
      if (role !== 'provider') return res.json({ message: 'Provider access is required.' }, 403);
      const rows = await listRows(tables, 'orders', [Query.equal('assignedProviderId', actorId), Query.limit(100)]);
      rows.sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt));
      return res.json({ rows });
    }

    const providerAction = path.match(/^\/provider\/orders\/([^/]+)\/(accept|reject|out-for-service|start|complete)$/);
    if (method === 'POST' && providerAction) {
      if (role !== 'provider') return res.json({ message: 'Provider access is required.' }, 403);
      return providerOrderAction(tables, actorId, providerAction[1], providerAction[2], body, res);
    }

    if (path.startsWith('/admin/')) {
      if (role !== 'admin') return res.json({ message: 'Admin access is required.' }, 403);
      return adminRoute(tables, actorId, method, path, body, res);
    }

    return res.json({ message: 'Unknown backend route.' }, 404);
  } catch (cause) {
    error(`Deep Care API error: ${cause?.message || cause}`);
    const code = Number.isInteger(cause?.code) ? cause.code : 500;
    const message = code >= 400 && code < 500 ? cause.message : 'The request could not be completed.';
    return res.json({ message }, code);
  }
}

async function handleRegisteredEmailOtp({ req, res, error }) {
  if (req.method !== 'POST') return res.json({ message: 'Use POST.' }, 405);
  const email = typeof req.bodyJson?.email === 'string' ? req.bodyJson.email.trim().toLowerCase() : '';
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return res.json({ message: 'Enter a valid email address.' }, 400);
  }
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const apiKey = req.headers?.['x-appwrite-key'];
  if (!endpoint || !projectId || !apiKey) {
    error('Appwrite Function endpoint, project ID, or execution key is missing.');
    return res.json({ message: 'Account check is not configured.' }, 500);
  }
  try {
    const adminClient = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
    const users = await new Users(adminClient).list({ queries: [Query.equal('email', email)], total: false });
    const user = users.users.find((candidate) => candidate.email.toLowerCase() === email);
    if (!user) return res.json({ registered: false });
    const publicClient = new Client().setEndpoint(endpoint).setProject(projectId);
    const token = await new Account(publicClient).createEmailToken({ userId: user.$id, email });
    return res.json({ registered: true, userId: token.userId });
  } catch (cause) {
    error(`Registered-email OTP failed: ${cause?.message || cause}`);
    return res.json({ message: 'Could not check your account or send a login code.' }, 502);
  }
}

function normalizePath(path = '/') {
  const clean = `/${String(path).split('?')[0].split('/').filter(Boolean).join('/')}`;
  return clean === '/' ? '/' : clean.replace(/\/$/, '');
}

function cleanText(value, maxLength) {
  return typeof value === 'string' ? value.trim().slice(0, maxLength) : '';
}

function uniqueStrings(value, maxLength) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((item) => cleanText(item, maxLength)).filter(Boolean))];
}

async function listRows(tables, table, queries = []) {
  if (!queries.length) queries = [Query.limit(100)];
  const result = await tables.listRows({ databaseId, tableId: tableIds[table], queries, total: false });
  return result.rows;
}

async function getRow(tables, table, rowId) {
  return tables.getRow({ databaseId, tableId: tableIds[table], rowId });
}

async function findProfile(tables, userId) {
  const rows = await listRows(tables, 'profiles', [Query.equal('userId', userId), Query.limit(1)]);
  return rows[0] ?? null;
}

async function findProvider(tables, userId) {
  const rows = await listRows(tables, 'providers', [Query.equal('userId', userId), Query.limit(1)]);
  return rows[0] ?? null;
}

function canReadOrder(order, userId, role) {
  return role === 'admin' || order.clientUserId === userId || (role === 'provider' && order.assignedProviderId === userId);
}

async function addEvent(tables, { orderId, actorUserId, eventType, previousStatus, newStatus, note = '' }) {
  const data = { orderId, actorUserId, eventType, previousStatus, newStatus };
  if (note) data.note = note;
  return tables.createRow({ databaseId, tableId: tableIds.events, rowId: ID.unique(), data });
}

async function changeOrder(tables, order, data, event) {
  const updated = await tables.updateRow({ databaseId, tableId: tableIds.orders, rowId: order.$id, data });
  try {
    await addEvent(tables, { orderId: order.$id, previousStatus: order.status, ...event });
  } catch (cause) {
    const rollback = Object.fromEntries(
      Object.keys(data).map((field) => [field, order[field] ?? null]),
    );
    await tables.updateRow({ databaseId, tableId: tableIds.orders, rowId: order.$id, data: rollback }).catch(() => {});
    throw cause;
  }
  return updated;
}

async function createOrder(tables, clientUserId, body, res) {
  const clientRequestId = cleanText(body.clientRequestId, 36);
  if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$/.test(clientRequestId)) {
    return res.json({ message: 'The booking request ID is invalid. Please retry.' }, 400);
  }
  const priorRows = await listRows(tables, 'orders', [Query.equal('clientRequestId', clientRequestId), Query.limit(1)]);
  if (priorRows.length) {
    if (priorRows[0].clientUserId !== clientUserId) return res.json({ message: 'This booking request ID is already in use.' }, 409);
    return res.json({ row: priorRows[0] });
  }

  const serviceId = cleanText(body.serviceId, 255);
  const scheduledAt = typeof body.scheduledAt === 'string' ? new Date(body.scheduledAt) : null;
  const addressType = cleanText(body.addressType, 30);
  const address = cleanText(body.address, 1000);
  const area = cleanText(body.area, 255);
  const city = cleanText(body.city, 255);
  const state = cleanText(body.state, 255);
  const pinCode = cleanText(body.pinCode, 10);
  const landmark = cleanText(body.landmark, 500);
  if (!serviceId || !scheduledAt || Number.isNaN(scheduledAt.getTime()) || !addressType || !address || !area || !city || !state || !/^\d{6}$/.test(pinCode)) {
    return res.json({ message: 'Complete the service, appointment time, and address before submitting.' }, 400);
  }
  const service = await getRow(tables, 'services', serviceId);
  if (service.isActive !== true) return res.json({ message: 'This service is currently unavailable.' }, 409);
  const serviceCode = serviceCodeFor(service.name);
  const bookingMonth = `${scheduledAt.getUTCFullYear()}${String(scheduledAt.getUTCMonth() + 1).padStart(2, '0')}`;
  const sequenceKey = `DC${serviceCode}${bookingMonth}`;
  const nextNumber = await nextBookingNumber(tables, sequenceKey);
  if (nextNumber > 99999) {
    const cause = new Error('This service has reached its 99,999 booking limit for the month.');
    cause.code = 409;
    throw cause;
  }
  const orderId = `${sequenceKey}${String(nextNumber).padStart(5, '0')}`;
  const rowData = {
    clientRequestId,
    clientUserId,
    serviceId,
    serviceName: service.name,
    servicePrice: service.basePrice,
    scheduledAt: scheduledAt.toISOString(),
    addressType,
    address,
    area,
    city,
    state,
    pinCode,
    status: 'pending_assignment',
    paymentStatus: 'pending',
  };
  if (landmark) rowData.landmark = landmark;
  let row;
  try {
    row = await tables.createRow({ databaseId, tableId: tableIds.orders, rowId: orderId, data: rowData });
  } catch (cause) {
    if (cause?.code === 409) {
      const duplicateRows = await listRows(tables, 'orders', [Query.equal('clientRequestId', clientRequestId), Query.limit(1)]);
      if (duplicateRows.length && duplicateRows[0].clientUserId === clientUserId) {
        return res.json({ row: duplicateRows[0] });
      }
    }
    throw cause;
  }
  try {
    await addEvent(tables, { orderId, actorUserId: clientUserId, eventType: 'created', previousStatus: 'pending_assignment', newStatus: 'pending_assignment', note: 'Client submitted a care request.' });
  } catch (cause) {
    await tables.deleteRow({ databaseId, tableId: tableIds.orders, rowId: orderId }).catch(() => {});
    throw cause;
  }
  return res.json({ row });
}

function serviceCodeFor(name = '') {
  const codes = {
    'home nursing': 'HN',
    physiotherapy: 'PT',
    caregiver: 'CG',
    'elder care': 'EC',
    'lab sample': 'LS',
    'doctor visit': 'DV',
    'health check': 'HC',
    ambulance: 'AM',
  };
  const normalized = cleanText(name, 120).toLowerCase();
  if (codes[normalized]) return codes[normalized];
  const fallback = normalized.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 2);
  return fallback.padEnd(2, 'X');
}

async function nextBookingNumber(tables, sequenceKey) {
  try {
    await getRow(tables, 'counters', sequenceKey);
  } catch (cause) {
    if (cause?.code !== 404) throw cause;
    try {
      await tables.createRow({
        databaseId,
        tableId: tableIds.counters,
        rowId: sequenceKey,
        data: { value: 0 },
      });
    } catch (createCause) {
      // Another request may have initialized this service/month counter first.
      if (createCause?.code !== 409) throw createCause;
    }
  }

  const updated = await tables.incrementRowColumn({
    databaseId,
    tableId: tableIds.counters,
    rowId: sequenceKey,
    column: 'value',
    value: 1,
  });
  if (!Number.isInteger(updated.value)) {
    throw new Error('Appwrite did not return the incremented booking counter.');
  }
  return updated.value;
}

async function providerOrderAction(tables, actorId, orderId, action, body, res) {
  const order = await getRow(tables, 'orders', orderId);
  if (order.assignedProviderId !== actorId) return res.json({ message: 'This booking is not assigned to your provider account.' }, 403);
  const note = cleanText(body.note, 500);
  if (action === 'accept' && order.status === 'assigned') {
    return res.json({ row: await changeOrder(tables, order, { status: 'accepted' }, { actorUserId: actorId, eventType: 'accepted', newStatus: 'accepted', note }) });
  }
  if (action === 'reject' && order.status === 'assigned') {
    const replacement = await chooseProvider(tables, order, actorId);
    if (replacement) {
      const updated = await changeOrder(tables, order, { assignedProviderId: replacement.userId, assignedAt: new Date().toISOString(), status: 'assigned' }, { actorUserId: actorId, eventType: 'reassigned', newStatus: 'assigned', note: `Provider ${actorId} declined.${note ? ` Note: ${note}.` : ''} Reassigned to ${replacement.businessName}.` });
      return res.json({ row: updated, reassigned: true });
    }
    const updated = await changeOrder(tables, order, { assignedProviderId: null, assignedAt: null, status: 'pending_assignment' }, { actorUserId: actorId, eventType: 'rejected', newStatus: 'pending_assignment', note: note || 'No other verified, available provider matched. Admin intervention is needed.' });
    return res.json({ row: updated, reassigned: false, manualInterventionRequired: true });
  }
  if (action === 'out-for-service' && order.status === 'accepted') {
    return res.json({ row: await changeOrder(tables, order, { status: 'out_for_service' }, { actorUserId: actorId, eventType: 'accepted', newStatus: 'out_for_service', note: note || 'Provider is on the way.' }) });
  }
  if (action === 'start' && order.status === 'out_for_service') {
    return res.json({ row: await changeOrder(tables, order, { status: 'in_progress' }, { actorUserId: actorId, eventType: 'started', newStatus: 'in_progress', note: note || 'Service started at the client location.' }) });
  }
  if (action === 'complete' && order.status === 'in_progress') {
    const result = await changeOrder(tables, order, { status: 'completed' }, { actorUserId: actorId, eventType: 'completed', newStatus: 'completed', note });
    const provider = await findProvider(tables, actorId);
    if (provider) {
      await tables.updateRow({ databaseId, tableId: tableIds.providers, rowId: provider.$id, data: { completedOrderCount: (provider.completedOrderCount ?? 0) + 1 } }).catch(() => {});
    }
    return res.json({ row: result });
  }
  return res.json({ message: 'That action is not valid for the current booking status.' }, 409);
}

async function chooseProvider(tables, order, excludedProviderId = '') {
  const [providers, orders] = await Promise.all([
    listRows(tables, 'providers'),
    listRows(tables, 'orders', [Query.limit(100)]),
  ]);
  const candidates = providers.filter((provider) => provider.userId !== excludedProviderId && provider.verificationStatus === 'verified' && provider.isAvailable === true &&
    Array.isArray(provider.serviceIds) && provider.serviceIds.includes(order.serviceId) &&
    areaMatches(provider.serviceAreas, order));
  candidates.sort((a, b) => activeOrderCount(orders, a.userId) - activeOrderCount(orders, b.userId));
  return candidates[0] ?? null;
}

function areaMatches(areas, order) {
  if (!Array.isArray(areas) || !areas.length) return false;
  const targets = [order.area, order.city, order.state, order.pinCode].filter(Boolean).map((x) => x.toLowerCase());
  return areas.some((area) => {
    const value = String(area).toLowerCase().trim();
    return value === '*' || value === 'all' || targets.some((target) => value.includes(target) || target.includes(value));
  });
}

function activeOrderCount(orders, providerId) {
  return orders.filter((order) => order.assignedProviderId === providerId && ['assigned', 'accepted', 'out_for_service', 'in_progress'].includes(order.status)).length;
}

async function adminRoute(tables, actorId, method, path, body, res) {
  if (method === 'GET' && path === '/admin/orders') {
    const rows = await listRows(tables, 'orders');
    rows.sort((a, b) => new Date(b.$createdAt) - new Date(a.$createdAt));
    return res.json({ rows });
  }
  if (method === 'GET' && path === '/admin/providers') return res.json({ rows: await listRows(tables, 'providers', [Query.limit(100)]) });
  if (method === 'GET' && path === '/admin/services') {
    const rows = await listRows(tables, 'services');
    rows.sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));
    return res.json({ rows });
  }

  if (method === 'POST' && path === '/admin/services') {
    const name = cleanText(body.name, 120);
    const description = cleanText(body.description, 2000);
    const category = cleanText(body.category, 120);
    const basePrice = Number(body.basePrice);
    const priceUnit = ['per_visit', 'per_hour', 'from'].includes(body.priceUnit) ? body.priceUnit : 'per_visit';
    if (!name || !description || !category || !Number.isFinite(basePrice) || basePrice < 0 || basePrice > 100000) {
      return res.json({ message: 'Provide a service name, description, category, and valid price.' }, 400);
    }
    const row = await tables.createRow({
      databaseId,
      tableId: tableIds.services,
      rowId: ID.unique(),
      data: { name, description, category, basePrice, priceUnit, isActive: true, sortOrder: Number.isInteger(body.sortOrder) ? body.sortOrder : 0 },
    });
    return res.json({ row }, 201);
  }

  const serviceMatch = path.match(/^\/admin\/services\/([^/]+)$/);
  if (method === 'POST' && serviceMatch) {
    const data = {};
    for (const field of ['name', 'description', 'category']) {
      if (typeof body[field] === 'string') data[field] = cleanText(body[field], field === 'description' ? 2000 : 120);
    }
    if (body.basePrice !== undefined) {
      const price = Number(body.basePrice);
      if (!Number.isFinite(price) || price < 0 || price > 100000) return res.json({ message: 'Enter a valid service price.' }, 400);
      data.basePrice = price;
    }
    if (['per_visit', 'per_hour', 'from'].includes(body.priceUnit)) data.priceUnit = body.priceUnit;
    if (typeof body.isActive === 'boolean') data.isActive = body.isActive;
    if (Number.isInteger(body.sortOrder)) data.sortOrder = body.sortOrder;
    if (!Object.keys(data).length) return res.json({ message: 'No service changes were provided.' }, 400);
    return res.json({ row: await tables.updateRow({ databaseId, tableId: tableIds.services, rowId: serviceMatch[1], data }) });
  }

  const assignMatch = path.match(/^\/admin\/orders\/([^/]+)\/assign$/);
  if (method === 'POST' && assignMatch) {
    const order = await getRow(tables, 'orders', assignMatch[1]);
    if (!['pending_assignment', 'assigned'].includes(order.status)) {
      return res.json({ message: 'Only unassigned or currently assigned orders can be assigned.' }, 409);
    }
    const provider = await findProvider(tables, cleanText(body.providerUserId, 255));
    if (!provider || provider.verificationStatus !== 'verified' || provider.isAvailable !== true || !Array.isArray(provider.serviceIds) || !provider.serviceIds.includes(order.serviceId) || !areaMatches(provider.serviceAreas, order)) {
      return res.json({ message: 'Select a verified, available provider who offers this service in the client’s area.' }, 400);
    }
    const previousStatus = order.status;
    const updated = await changeOrder(tables, order, { assignedProviderId: provider.userId, assignedAt: new Date().toISOString(), status: 'assigned', createdByAdminId: actorId }, {
      actorUserId: actorId,
      eventType: order.assignedProviderId ? 'reassigned' : 'assigned',
      newStatus: 'assigned',
      note: cleanText(body.note, 500),
    });
    return res.json({ row: updated, previousStatus });
  }

  const roleMatch = path.match(/^\/admin\/profiles\/([^/]+)\/role$/);
  if (method === 'POST' && roleMatch) {
    if (!['client', 'provider'].includes(body.role)) return res.json({ message: 'Admin roles must be assigned through the Appwrite Console.' }, 400);
    const targetId = roleMatch[1];
    const profile = await findProfile(tables, targetId);
    if (!profile) return res.json({ message: 'Create the user profile by having the user sign in first.' }, 404);
    return res.json({ row: await tables.updateRow({ databaseId, tableId: tableIds.profiles, rowId: profile.$id, data: { role: body.role } }) });
  }

  const verifyMatch = path.match(/^\/admin\/providers\/([^/]+)\/verify$/);
  if (method === 'POST' && verifyMatch) {
    const status = body.verificationStatus;
    if (!['verified', 'rejected', 'suspended'].includes(status)) return res.json({ message: 'Invalid verification status.' }, 400);
    const provider = await findProvider(tables, verifyMatch[1]);
    if (!provider) return res.json({ message: 'Provider profile not found.' }, 404);
    const data = { verificationStatus: status };
    if (status !== 'verified') data.isAvailable = false;
    return res.json({ row: await tables.updateRow({ databaseId, tableId: tableIds.providers, rowId: provider.$id, data }) });
  }

  return res.json({ message: 'Unknown admin route.' }, 404);
}
