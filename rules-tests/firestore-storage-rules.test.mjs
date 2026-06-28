import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { ref, uploadString } from 'firebase/storage';

const root = resolve('..');
const projectId = 'jamiaq8';

const testEnv = await initializeTestEnvironment({
  projectId,
  firestore: {
    rules: readFileSync(
      resolve(root, 'firebase/firestore.production.rules'),
      'utf8',
    ),
  },
  storage: {
    rules: readFileSync(
      resolve(root, 'firebase/storage.production.rules'),
      'utf8',
    ),
  },
});

const user = {
  userId: 'regular',
  displayName: 'Regular User',
  username: 'regular',
  role: 'regular',
  status: 'active',
  createdAt: '2026-06-27T00:00:00.000Z',
};
const admin = {
  ...user,
  userId: 'admin',
  displayName: 'Admin User',
  username: 'admin',
  role: 'admin',
};
const disabled = {
  ...user,
  userId: 'disabled',
  username: 'disabled',
  status: 'disabled',
};

function firestoreAs(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function storageAs(uid) {
  return testEnv.authenticatedContext(uid).storage();
}

async function seed() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/admin'), admin);
    await setDoc(doc(db, 'users/regular'), user);
    await setDoc(doc(db, 'users/disabled'), disabled);
    await setDoc(doc(db, 'items/item-1'), {
      itemId: 'item-1',
      nameAr: 'Tomato',
      nameEn: 'Tomato',
      categoryId: 'veg',
      defaultUnit: 'kg',
      isFavorite: false,
      isActive: true,
    });
  });
}

function requestData(overrides = {}) {
  return {
    requestId: 'request-1',
    roundId: 'round-1',
    itemId: 'item-1',
    itemName: 'Tomato',
    categoryId: 'veg',
    categoryName: 'Vegetables',
    quantity: 1,
    unit: 'kg',
    priority: 'normal',
    note: null,
    imageUrl: null,
    thumbnailUrl: null,
    requestedBy: 'regular',
    requestedByName: 'Regular User',
    requestedAt: '2026-06-27T00:00:00.000Z',
    status: 'needed',
    purchasedBy: null,
    purchasedByName: null,
    purchasedAt: null,
    ...overrides,
  };
}

try {
  await seed();

  const regularDb = firestoreAs('regular');
  const adminDb = firestoreAs('admin');
  const disabledDb = firestoreAs('disabled');

  await assertSucceeds(getDoc(doc(regularDb, 'users/regular')));
  await assertFails(getDoc(doc(disabledDb, 'items/item-1')));

  await assertSucceeds(
    updateDoc(doc(regularDb, 'users/regular'), {
      userId: 'regular',
      lastLogin: '2026-06-27T01:00:00.000Z',
    }),
  );
  await assertFails(
    updateDoc(doc(regularDb, 'users/admin'), {
      role: 'regular',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(adminDb, 'users/regular'), {
      status: 'disabled',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(adminDb, 'users/regular'), {
      status: 'active',
    }),
  );

  await assertSucceeds(
    setDoc(doc(regularDb, 'rounds/round-1'), {
      roundId: 'round-1',
      name: 'Round',
      date: '2026-06-27T00:00:00.000Z',
      closeAt: '2026-06-28T00:00:00.000Z',
      status: 'open',
      createdBy: 'regular',
      createdAt: '2026-06-27T00:00:00.000Z',
      shoppingStartedAt: null,
    }),
  );
  await assertFails(
    setDoc(doc(regularDb, 'rounds/forged-round'), {
      roundId: 'forged-round',
      name: 'Bad Round',
      date: '2026-06-27T00:00:00.000Z',
      closeAt: '2026-06-28T00:00:00.000Z',
      status: 'open',
      createdBy: 'admin',
      createdAt: '2026-06-27T00:00:00.000Z',
    }),
  );

  await assertSucceeds(
    setDoc(doc(regularDb, 'requests/request-1'), requestData()),
  );
  await assertFails(
    setDoc(
      doc(firestoreAs('admin'), 'requests/forged-request'),
      requestData({
        requestId: 'forged-request',
        requestedBy: 'regular',
      }),
    ),
  );
  await assertSucceeds(
    updateDoc(doc(regularDb, 'requests/request-1'), {
      quantity: 2,
      updatedAt: '2026-06-27T01:00:00.000Z',
    }),
  );
  await assertFails(
    updateDoc(doc(firestoreAs('regular'), 'requests/request-1'), {
      requestedBy: 'admin',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(firestoreAs('admin'), 'requests/request-1'), {
      status: 'purchased',
      purchasedBy: 'admin',
      purchasedByName: 'Admin User',
      purchasedAt: '2026-06-27T02:00:00.000Z',
    }),
  );

  await assertSucceeds(
    setDoc(doc(regularDb, 'operationLogs/log-1'), {
      logId: 'log-1',
      actionType: 'requestCreated',
      userId: 'regular',
      userName: 'Regular User',
      itemName: 'Tomato',
      details: 'Created',
      createdAt: '2026-06-27T00:00:00.000Z',
    }),
  );
  await assertFails(
    setDoc(doc(regularDb, 'operationLogs/forged-log'), {
      logId: 'forged-log',
      actionType: 'requestCreated',
      userId: 'admin',
      userName: 'Admin User',
      itemName: 'Tomato',
      details: 'Forged',
      createdAt: '2026-06-27T00:00:00.000Z',
    }),
  );

  await assertFails(deleteDoc(doc(regularDb, 'requests/request-1')));
  await assertSucceeds(deleteDoc(doc(adminDb, 'requests/request-1')));

  await assertSucceeds(getDocs(collection(regularDb, 'notifications')));
  await assertFails(
    setDoc(doc(regularDb, 'notifications/forged-notification'), {
      notificationId: 'forged-notification',
      title: 'Bad',
      body: 'Bad',
      type: 'adminMessage',
      createdBy: 'admin',
      createdAt: '2026-06-27T00:00:00.000Z',
      targetUsers: [],
    }),
  );

  const regularStorage = storageAs('regular');
  await assertSucceeds(
    uploadString(
      ref(regularStorage, 'request-images/regular/request-1/original'),
      'image',
      'raw',
      { contentType: 'image/png' },
    ),
  );
  await assertFails(
    uploadString(
      ref(regularStorage, 'request-images/admin/request-1/original'),
      'image',
      'raw',
      { contentType: 'image/png' },
    ),
  );
  await assertFails(
    uploadString(
      ref(regularStorage, 'request-images/regular/request-1/text'),
      'not an image',
      'raw',
      { contentType: 'text/plain' },
    ),
  );

  assert.ok(true);
  console.log('Rules tests passed');
} finally {
  await testEnv.cleanup();
}
