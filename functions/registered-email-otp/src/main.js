import { Account, Client, Query, Users } from 'node-appwrite';

export default async ({ req, res, error }) => {
  if (req.method !== 'POST') {
    return res.json({ message: 'Use POST.' }, 405);
  }

  const email =
    typeof req.bodyJson?.email === 'string'
      ? req.bodyJson.email.trim().toLowerCase()
      : '';
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
    const adminClient = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);
    const users = await new Users(adminClient).list({
      queries: [Query.equal('email', email)],
      total: false,
    });
    const user = users.users.find(
      (candidate) => candidate.email.toLowerCase() === email,
    );

    if (!user) {
      return res.json({ registered: false });
    }

    const publicClient = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId);
    const token = await new Account(publicClient).createEmailToken({
      userId: user.$id,
      email,
    });
    return res.json({ registered: true, userId: token.userId });
  } catch (cause) {
    error(`Registered-email OTP failed: ${cause?.message || cause}`);
    return res.json(
      { message: 'Could not check your account or send a login code.' },
      502,
    );
  }
};
