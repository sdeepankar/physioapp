const json = (res, status, body) => res.json(body, status);

function normalizePhone(countryCode, phoneNumber) {
  const country = String(countryCode || '').replace(/\D/g, '');
  const number = String(phoneNumber || '').replace(/\D/g, '');
  if (country !== '91' || !/^[6-9]\d{9}$/.test(number)) return null;
  return `+${country}${number}`;
}

async function appwriteRequest(endpoint, projectId, apiKey, path, method, body) {
  const response = await fetch(`${endpoint.replace(/\/$/, '')}${path}`, {
    method,
    headers: {
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
      'Content-Type': 'application/json',
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const payload = await response.json().catch(() => ({}));
  return { response, payload };
}

module.exports = async ({ req, res, error }) => {
  if (req.method !== 'POST') return json(res, 405, { error: 'Use POST.' });

  const accessToken = req.bodyJson?.accessToken;
  const submittedFirstName = String(req.bodyJson?.firstName || '').trim().slice(0, 60);
  const submittedLastName = String(req.bodyJson?.lastName || '').trim().slice(0, 60);
  const submittedName = [submittedFirstName, submittedLastName].filter(Boolean).join(' ').slice(0, 120);
  const phoneEmailClientId = process.env.PHONE_EMAIL_CLIENT_ID;
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const functionApiKey = req.headers?.['x-appwrite-key'];

  if (typeof accessToken !== 'string' || accessToken.length < 10 ||
      !submittedFirstName || !submittedLastName) {
    return json(res, 400, { error: 'Enter your first and last name, then complete phone verification.' });
  }
  if (!phoneEmailClientId || !endpoint || !projectId || !functionApiKey) {
    error('Phone.Email or Appwrite Function configuration is incomplete.');
    return json(res, 503, { error: 'Phone registration is not configured yet.' });
  }

  try {
    const providerResponse = await fetch('https://eapi.phone.email/getuser', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ access_token: accessToken, client_id: phoneEmailClientId }),
    });
    if (!providerResponse.ok) {
      return json(res, 401, { error: 'Phone.Email could not confirm your number. Please verify again.' });
    }

    const providerUser = await providerResponse.json();
    if (providerUser.status !== 200) {
      return json(res, 401, { error: 'Phone.Email could not confirm your number. Please verify again.' });
    }

    // Phone.Email validates the SDK access token and returns the verified
    // phone over HTTPS. Keep this provider lookup on the server so the client
    // cannot assert its own verified phone number.
    const verifiedPhone = normalizePhone(providerUser.country_code, providerUser.phone_no);
    const providerFirstName = String(providerUser.user_first_name || '').trim().slice(0, 60);
    const providerLastName = String(providerUser.user_last_name || '').trim().slice(0, 60);
    let firstName = submittedFirstName || providerFirstName;
    let lastName = submittedLastName || providerLastName;
    const providerName = [providerFirstName, providerLastName].filter(Boolean).join(' ').slice(0, 120);
    if (!verifiedPhone) {
      return json(res, 401, { error: 'Deep Care currently supports verified Indian mobile numbers.' });
    }
    // A deterministic internal ID allows repeat registration to sign in to
    // the same phone account without exposing a phone lookup endpoint.
    const userId = 'phone_' + verifiedPhone.replace(/\D/g, '');
    let profileName = submittedName || providerName || 'Deep Care User';
    const createUser = await appwriteRequest(endpoint, projectId, functionApiKey, '/users', 'POST', {
      userId,
      phone: verifiedPhone,
      name: profileName,
    });
    if (!createUser.response.ok && createUser.response.status !== 409) {
      const appwriteType = String(createUser.payload?.type || 'unknown');
      const appwriteMessage = String(createUser.payload?.message || 'No Appwrite message');
      error('Appwrite user creation failed (' + createUser.response.status + ', ' + appwriteType + '): ' + appwriteMessage);
      return json(res, 502, { error: 'Could not create your account. Please try again.' });
    }
    if (createUser.response.status === 409) {
      const existing = await appwriteRequest(
        endpoint, projectId, functionApiKey, `/users/${encodeURIComponent(userId)}`, 'GET',
      );
      if (!existing.response.ok || existing.payload.phone !== verifiedPhone || existing.payload.status === false) {
        return json(res, 409, { error: 'This phone account cannot be used. Please contact support.' });
      }
      if (!submittedName && !providerName) {
        profileName = String(existing.payload.name || profileName).trim().slice(0, 120) || 'Deep Care User';
        const nameParts = profileName.split(/\s+/);
        firstName = nameParts.shift() || '';
        lastName = nameParts.join(' ');
      }
    }

    const verification = await appwriteRequest(
      endpoint, projectId, functionApiKey,
      `/users/${encodeURIComponent(userId)}/verification/phone`, 'PATCH',
      { phoneVerification: true },
    );
    if (!verification.response.ok) {
      error(`Appwrite phone verification update failed (${verification.response.status}).`);
      return json(res, 502, { error: 'Could not finish verifying your account. Please try again.' });
    }

    const token = await appwriteRequest(
      endpoint, projectId, functionApiKey,
      `/users/${encodeURIComponent(userId)}/tokens`, 'POST', {},
    );
    if (!token.response.ok || typeof token.payload.secret !== 'string') {
      error(`Appwrite custom token creation failed (${token.response.status}).`);
      return json(res, 502, { error: 'Could not start your account session. Please try again.' });
    }

    return json(res, 200, { userId, secret: token.payload.secret, phone: verifiedPhone, name: profileName, firstName, lastName });
  } catch (cause) {
    error(`Phone.Email registration failed: ${cause?.message || cause}`);
    return json(res, 502, { error: 'Phone registration could not be completed. Please try again.' });
  }
};
