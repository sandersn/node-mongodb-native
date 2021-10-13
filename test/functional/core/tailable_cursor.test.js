'use strict';
const { expect } = require('chai');
const { runLater } = require('../../tools/utils');

describe('Tailable cursor tests', function () {
  describe('awaitData', () => {
    let client;

    beforeEach(async function () {
      client = this.configuration.newClient();
      await client.connect();
    });

    afterEach(async () => {
      await client.close();
    });

    it(
      'should block waiting for new data to arrive when the cursor reaches the end of the capped collection',
      {
        metadata: { requires: { mongodb: '>=3.2' } },
        async test() {
          const db = client.db('cursor_tailable');

          try {
            await db.collection('cursor_tailable').drop();
            // eslint-disable-next-line no-empty
          } catch (_) {}

          const collection = await db.createCollection('cursor_tailable', {
            capped: true,
            size: 10000
          });

          const res = await collection.insertOne({ a: 1 });
          expect(res).property('insertedId').to.exist;

          const cursor = collection.find({}, { batchSize: 2, tailable: true, awaitData: true });
          const doc = await cursor.next();
          expect(doc).to.exist;

          // After 300ms make an insert
          const later = runLater(async () => {
            const res = await collection.insertOne({ a: 1 });
            expect(res).property('insertedId').to.exist;
          }, 300);

          const start = new Date();
          await cursor.next();
          const end = new Date();

          await later; // make sure this finished, without a failure

          // We should see here that cursor.next blocked for at least 300ms
          expect(end.getTime() - start.getTime()).to.be.at.least(300);
          await cursor.close();
        }
      }
    );
  });
});
