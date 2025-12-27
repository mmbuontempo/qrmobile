
// ============================================================================
// GOOGLE AUTH IMPLEMENTATION FOR SERVER
// ============================================================================
// 
// Add this to your server/mobile.routes.ts file.
// You will need to install: npm install google-auth-library
//
// import { OAuth2Client } from 'google-auth-library';
//
// const googleClient = new OAuth2Client(
//   process.env.GOOGLE_CLIENT_ID, // Use the same Web Client ID as in the app
//   process.env.GOOGLE_CLIENT_SECRET
// );

/**
 * POST /api/mobile/auth/google
 * 
 * Authenticates user via Google ID Token (Native Sign-In)
 * 
 * Body: { idToken, deviceId, deviceName, deviceOS, appVersion }
 */
router.post('/auth/google', async (req, res) => {
  const { idToken, deviceId, deviceName, deviceOS, appVersion } = req.body;
  
  if (!idToken || !deviceId) {
    return res.status(400).json({ error: 'missing_fields' });
  }
  
  try {
    // 1. Verify Google Token
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID, // Must match your Web Client ID
    });
    
    const payload = ticket.getPayload();
    if (!payload || !payload.email) {
      return res.status(401).json({ error: 'invalid_google_token' });
    }
    
    const { email, name, picture, sub: googleId } = payload;
    
    // 2. Find or Create User
    let user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, role: true, companyId: true, isActive: true }
    });
    
    if (!user) {
      // Create new user if registration is allowed
      // Or return error if invite-only
      /*
      user = await prisma.user.create({
        data: {
          email,
          name: name || 'User',
          avatarUrl: picture,
          googleId,
          isActive: true,
          // ... other fields
        }
      });
      */
      return res.status(401).json({ error: 'user_not_found' });
    }
    
    if (!user.isActive) {
      return res.status(401).json({ error: 'user_inactive' });
    }
    
    // 3. Generate Tokens (Same as code exchange)
    const accessToken = generateAccessToken(user.id, user.companyId || '', user.role);
    
    const refreshToken = generateSecureToken('rt');
    const refreshTokenHash = hashToken(refreshToken);
    const refreshExpiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRY * 24 * 60 * 60 * 1000);
    
    // 4. Store Refresh Token
    await prisma.mobileRefreshToken.create({
      data: {
        userId: user.id,
        tokenHash: refreshTokenHash,
        deviceId,
        deviceName: deviceName || 'Mobile App',
        deviceOS: deviceOS || null,
        appVersion: appVersion || null,
        expiresAt: refreshExpiresAt,
        lastUsedAt: new Date(),
        lastIp: req.ip || null,
      }
    });
    
    // 5. Return Session
    res.json({
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TOKEN_EXPIRY * 60,
      refreshExpiresAt: refreshExpiresAt.toISOString(),
      user: {
        id: user.id,
        email,
        name,
        avatarUrl: picture,
        role: user.role,
      }
    });
    
  } catch (error) {
    console.error('[mobile] Google auth error:', error);
    res.status(401).json({ error: 'google_auth_failed', details: error.message });
  }
});
