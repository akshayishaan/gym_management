import mongoose, { type ClientSession } from "mongoose";

export async function withMongoTransaction<T>(
  work: (session: ClientSession) => Promise<T>
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
