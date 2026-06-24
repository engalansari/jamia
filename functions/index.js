const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const enabledPushTypes = new Set(['requestCreated', 'shoppingStarted']);
const staleTokenMaxAgeMs = 30 * 24 * 60 * 60 * 1000;

exports.sendPushForNotification = onDocumentCreated(
  {
    document: 'notifications/{notificationId}',
    region: 'us-central1',
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notification = snapshot.data();
    const title = String(notification.title || 'جمعية');
    const body = String(notification.body || '');
    const type = String(notification.type || '');
    const createdBy = String(notification.createdBy || '');
    if (!enabledPushTypes.has(type)) {
      logger.info('Push skipped for disabled notification type.', {
        notificationId: event.params.notificationId,
        type,
      });
      return;
    }

    const targetUsers = Array.isArray(notification.targetUsers)
      ? notification.targetUsers.filter(Boolean)
      : [];

    const tokenDocs = targetUsers.length > 0
      ? await tokensForUsers(targetUsers, type, createdBy)
      : await tokensForActiveUsers(type, createdBy);

    if (tokenDocs.length === 0) {
      logger.info('No push tokens found for notification.', {
        notificationId: event.params.notificationId,
      });
      return;
    }

    const tokens = tokenDocs.map((tokenDoc) => tokenDoc.token);
    const payload = {
      notification: { title, body },
      data: cleanData({
        notificationId: event.params.notificationId,
        type,
        roundId: notification.roundId,
        requestId: notification.requestId,
        itemName: notification.itemName,
        url: '/',
        title,
        body,
      }),
      webpush: {
        fcmOptions: { link: '/' },
        notification: {
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          tag: type || 'jamia',
        },
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    const invalidTokenPaths = [];
    const staleTokenPaths = tokenDocs
      .filter((tokenDoc) => isStaleToken(tokenDoc.updatedAt))
      .map((tokenDoc) => tokenDoc.ref.path);
    let successCount = 0;
    let failureCount = 0;

    for (const chunk of chunks(tokens, 500)) {
      const response = await messaging.sendEachForMulticast({
        ...payload,
        tokens: chunk,
      });
      successCount += response.successCount;
      failureCount += response.failureCount;

      response.responses.forEach((result, index) => {
        if (result.success) return;
        const code = result.error && result.error.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          const token = chunk[index];
          const tokenDoc = tokenDocs.find((doc) => doc.token === token);
          if (tokenDoc) invalidTokenPaths.push(tokenDoc.ref.path);
        } else {
          logger.warn('Push send failed.', { code, notificationId: event.params.notificationId });
        }
      });
    }

    await deleteInvalidTokens([...invalidTokenPaths, ...staleTokenPaths]);
    logger.info('Push notification sent.', {
      notificationId: event.params.notificationId,
      successCount,
      failureCount,
      deletedInvalidTokens: invalidTokenPaths.length,
      deletedStaleTokens: staleTokenPaths.length,
    });
  },
);

async function tokensForActiveUsers(type, actorUserId) {
  const usersSnapshot = await db
    .collection('users')
    .where('status', '==', 'active')
    .get();
  return tokensForUsers(usersSnapshot.docs.map((doc) => doc.id), type, actorUserId);
}

async function tokensForUsers(userIds, type, actorUserId) {
  const tokenDocs = [];
  for (const userId of [...new Set(userIds)]) {
    if (actorUserId && userId === actorUserId) continue;

    const userSnapshot = await db.collection('users').doc(userId).get();
    if (!userSnapshot.exists || userSnapshot.get('status') !== 'active') {
      continue;
    }
    if (!(await userAllowsNotification(userSnapshot.ref, type))) {
      continue;
    }

    const tokensSnapshot = await userSnapshot.ref.collection('pushTokens').get();
    tokensSnapshot.docs.forEach((doc) => {
      const token = doc.get('token');
      if (typeof token === 'string' && token.length > 0) {
        tokenDocs.push({ token, ref: doc.ref, updatedAt: doc.get('updatedAt') });
      }
    });
  }
  return tokenDocs;
}

async function userAllowsNotification(userRef, type) {
  const preferenceSnapshot = await userRef
    .collection('settings')
    .doc('notificationPreferences')
    .get();
  const preferences = preferenceSnapshot.data() || {};
  if (type === 'requestCreated') {
    return preferences.requestCreated !== false;
  }
  if (type === 'shoppingStarted') {
    return preferences.shoppingStarted !== false;
  }
  return false;
}

function cleanData(data) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== undefined && value !== null)
      .map(([key, value]) => [key, String(value)]),
  );
}

function chunks(values, size) {
  const result = [];
  for (let index = 0; index < values.length; index += size) {
    result.push(values.slice(index, index + size));
  }
  return result;
}

function isStaleToken(updatedAt) {
  const updatedDate = parseDate(updatedAt);
  if (!updatedDate) return false;
  return Date.now() - updatedDate.getTime() > staleTokenMaxAgeMs;
}

function parseDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  if (typeof value === 'string') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  return null;
}

async function deleteInvalidTokens(paths) {
  const uniquePaths = [...new Set(paths)];
  if (uniquePaths.length === 0) return;

  const batch = db.batch();
  uniquePaths.forEach((path) => batch.delete(db.doc(path)));
  await batch.commit();
}
