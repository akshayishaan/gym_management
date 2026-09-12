import mongoose, { type ClientSession } from "mongoose";

/**
 * Runs `work` inside a MongoDB transaction, mirroring the Next.js
 * `lib/mongoTransaction.ts` semantics exactly.
 *
 * Starts a session, executes `work(session)` within `session.withTransaction`
 * (which commits on success and aborts on throw), ends the session in a
 * `finally`, and fails loudly when no result was produced.
 */
export async function withMongoTransaction<T>(
  work: (session: ClientSession) => Promise<T>,
): Promise<T> {
  const session = await mongoose.startSession();
  let result: T | undefined;

  try {
    await session.withTransaction(async () => {
      result = await work(session);
    });
  } finally {
    await session.endSession();
  }

  if (result === undefined) throw new Error("Transaction completed without a result");
  return result;
}
