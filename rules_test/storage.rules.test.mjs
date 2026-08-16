// Cloud Storage security-rules tests (SEC-7).
//
// The project shipped with no storage.rules at all, so driver identity
// documents were governed by whatever default the bucket carried. These pin
// down the ownership model the new rules introduce.

import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { getBytes, ref, uploadBytes } from 'firebase/storage';
import {
  ADMIN,
  CUSTOMER,
  OTHER_CUSTOMER,
  UNVERIFIED_DRIVER,
  TINY_PNG,
  makeTestEnv,
  seedUsers,
} from './helpers.mjs';

let testEnv;

const storage = (uid) =>
  uid === null
    ? testEnv.unauthenticatedContext().storage()
    : testEnv.authenticatedContext(uid).storage();

const png = { contentType: 'image/png' };

before(async () => {
  testEnv = await makeTestEnv();
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
  await testEnv.clearFirestore();
  // storage.rules resolves isAdmin() by reading the users collection.
  await seedUsers(testEnv);
});

async function seedFile(path) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), path), TINY_PNG, png);
  });
}

describe('profile_photos', () => {
  it('allows uploading your own photo', async () => {
    await assertSucceeds(
      uploadBytes(
        ref(storage(CUSTOMER), `profile_photos/${CUSTOMER}.png`),
        TINY_PNG,
        png,
      ),
    );
  });

  it('rejects overwriting another user photo', async () => {
    await assertFails(
      uploadBytes(
        ref(storage(CUSTOMER), `profile_photos/${OTHER_CUSTOMER}.png`),
        TINY_PNG,
        png,
      ),
    );
  });

  it('rejects a non-image upload', async () => {
    await assertFails(
      uploadBytes(
        ref(storage(CUSTOMER), `profile_photos/${CUSTOMER}.png`),
        Buffer.from('#!/bin/sh\nrm -rf /'),
        { contentType: 'application/x-sh' },
      ),
    );
  });

  it('rejects an oversized upload', async () => {
    await assertFails(
      uploadBytes(
        ref(storage(CUSTOMER), `profile_photos/${CUSTOMER}.png`),
        Buffer.alloc(6 * 1024 * 1024, 1),
        png,
      ),
    );
  });

  it('allows any signed-in user to read a profile photo', async () => {
    await seedFile(`profile_photos/${CUSTOMER}.png`);
    await assertSucceeds(
      getBytes(ref(storage(OTHER_CUSTOMER), `profile_photos/${CUSTOMER}.png`)),
    );
  });

  it('rejects an anonymous read', async () => {
    await seedFile(`profile_photos/${CUSTOMER}.png`);
    await assertFails(
      getBytes(ref(storage(null), `profile_photos/${CUSTOMER}.png`)),
    );
  });
});

describe('driver_applications — identity documents stay private', () => {
  const docPath = `driver_applications/${UNVERIFIED_DRIVER}/nin.png`;

  it('allows an applicant to upload their own document', async () => {
    await assertSucceeds(
      uploadBytes(ref(storage(UNVERIFIED_DRIVER), docPath), TINY_PNG, png),
    );
  });

  it('allows the applicant to read it back', async () => {
    await seedFile(docPath);
    await assertSucceeds(
      getBytes(ref(storage(UNVERIFIED_DRIVER), docPath)),
    );
  });

  it('rejects another user reading somebody NIN slip', async () => {
    await seedFile(docPath);
    await assertFails(getBytes(ref(storage(CUSTOMER), docPath)));
  });

  it('allows an admin to read it for verification', async () => {
    await seedFile(docPath);
    await assertSucceeds(getBytes(ref(storage(ADMIN), docPath)));
  });

  it('rejects uploading into another applicant folder', async () => {
    await assertFails(
      uploadBytes(
        ref(storage(CUSTOMER), `driver_applications/${UNVERIFIED_DRIVER}/fake.png`),
        TINY_PNG,
        png,
      ),
    );
  });
});

describe('proof_of_delivery', () => {
  it('allows a signed-in user to upload proof', async () => {
    await assertSucceeds(
      uploadBytes(
        ref(storage(UNVERIFIED_DRIVER), 'proof_of_delivery/o1/drop.png'),
        TINY_PNG,
        png,
      ),
    );
  });

  it('rejects an anonymous upload', async () => {
    await assertFails(
      uploadBytes(
        ref(storage(null), 'proof_of_delivery/o1/drop.png'),
        TINY_PNG,
        png,
      ),
    );
  });
});

describe('catch-all', () => {
  it('rejects writing to an unlisted path', async () => {
    await assertFails(
      uploadBytes(ref(storage(CUSTOMER), 'random/evil.png'), TINY_PNG, png),
    );
  });

  it('rejects reading from an unlisted path', async () => {
    await seedFile('random/evil.png');
    await assertFails(getBytes(ref(storage(ADMIN), 'random/evil.png')));
  });
});
