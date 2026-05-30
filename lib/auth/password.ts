import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";

const scrypt = promisify(scryptCallback);

const PASSWORD_HASH_ALGORITHM = "scrypt";
const SALT_LENGTH_BYTES = 16;
const KEY_LENGTH_BYTES = 64;

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(SALT_LENGTH_BYTES).toString("hex");
  const derivedKey = (await scrypt(password, salt, KEY_LENGTH_BYTES)) as Buffer;

  return `${PASSWORD_HASH_ALGORITHM}:${salt}:${derivedKey.toString("hex")}`;
}

export async function verifyPassword(password: string, storedPasswordHash: string): Promise<boolean> {
  const [algorithm, salt, storedKey] = storedPasswordHash.split(":");

  if (algorithm !== PASSWORD_HASH_ALGORITHM || !salt || !storedKey) {
    return false;
  }

  const storedKeyBuffer = Buffer.from(storedKey, "hex");
  const derivedKey = (await scrypt(password, salt, storedKeyBuffer.length)) as Buffer;

  if (storedKeyBuffer.length !== derivedKey.length) {
    return false;
  }

  return timingSafeEqual(storedKeyBuffer, derivedKey);
}
