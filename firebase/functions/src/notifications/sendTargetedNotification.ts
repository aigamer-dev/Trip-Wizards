import * as functions from 'firebase-functions';
import type {DocumentReference, QueryDocumentSnapshot} from 'firebase-admin/firestore';
import type {SendResponse} from 'firebase-admin/messaging';
import {messaging, db} from '../admin';

type NotificationPayload = {
  recipientUid: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
  dryRun?: boolean;
};

type CallableContext = functions.https.CallableContext;

type TokenDocument = {
  token?: string;
};

const MAX_TOKENS_PER_BATCH = 500;

function assertAuthorized(context: CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required.',
    );
  }

  const claims = context.auth.token as Record<string, unknown>;
  const isAdmin = claims['admin'] === true;
  const roles = Array.isArray(claims['roles']) ? claims['roles'] : [];
  const isNotifier = roles.includes('notification-operator');

  if (!isAdmin && !isNotifier) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Caller lacks permission to send notifications.',
    );
  }
}

async function fetchRecipientTokens(recipientUid: string): Promise<string[]> {
  const tokenSnapshots = await db
    .collection('users')
    .doc(recipientUid)
    .collection('fcmTokens')
    .get();

  if (tokenSnapshots.empty) {
    return [];
  }

  return tokenSnapshots.docs
    .map((doc: QueryDocumentSnapshot) => {
      const tokenDoc = doc.data() as TokenDocument | undefined;
      return tokenDoc?.token ?? doc.id;
    })
    .filter((token: string | undefined): token is string =>
      typeof token === 'string' && token.length > 0,
    );
}

async function pruneInvalidTokens(
  recipientUid: string,
  invalidTokens: string[],
): Promise<void> {
  if (invalidTokens.length === 0) return;

  const batch = db.batch();
  const collection = db
    .collection('users')
    .doc(recipientUid)
    .collection('fcmTokens');

  invalidTokens.forEach((token) => {
    const ref: DocumentReference = collection.doc(token);
    batch.delete(ref);
  });

  await batch.commit();
}

function chunkTokens(tokens: string[]): string[][] {
  const chunks: string[][] = [];
  for (let i = 0; i < tokens.length; i += MAX_TOKENS_PER_BATCH) {
    chunks.push(tokens.slice(i, i + MAX_TOKENS_PER_BATCH));
  }
  return chunks;
}

export async function sendTargetedNotificationHandler(
  data: NotificationPayload,
  context: CallableContext,
) {
  assertAuthorized(context);

  const {
    recipientUid,
    title,
    body,
    data: payloadData = {},
    imageUrl,
    dryRun = false,
  } = data;

  if (!recipientUid || typeof recipientUid !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'recipientUid is required.',
    );
  }
  if (!title || typeof title !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'title is required.',
    );
  }
  if (!body || typeof body !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'body is required.',
    );
  }

  const tokens = await fetchRecipientTokens(recipientUid);
  if (tokens.length === 0) {
    return {
      success: false,
      message: 'No FCM tokens registered for recipient.',
      sentCount: 0,
      failureCount: 0,
      invalidTokens: [],
    };
  }

  const chunks = chunkTokens(tokens);
  let sentCount = 0;
  let failureCount = 0;
  const invalidTokens: string[] = [];

  for (const chunk of chunks) {
    const response = await messaging.sendEachForMulticast(
      {
        notification: {title, body, imageUrl},
        data: payloadData,
        tokens: chunk,
      },
      dryRun,
    );

    sentCount += response.successCount;
    failureCount += response.failureCount;

    response.responses.forEach((res: SendResponse, index: number) => {
      if (!res.success) {
        const code = res.error?.code ?? 'unknown';
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          invalidTokens.push(chunk[index]);
        }
      }
    });
  }

  await pruneInvalidTokens(recipientUid, invalidTokens);

  return {
    success: failureCount === 0,
    message: failureCount === 0
      ? 'Notification sent to all registered tokens.'
      : 'Notification delivered with some failures.',
    sentCount,
    failureCount,
    invalidTokens,
  };
}
