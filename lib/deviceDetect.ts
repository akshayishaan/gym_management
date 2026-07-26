// Matches phone browsers only. Deliberately excludes iPad/tablet UAs — this
// app targets phone widths (~375-430px), tablets get the same
// unsupported-device gate as desktop. Modern iPadOS Safari sends a
// desktop-like "Macintosh" UA by default, so it already falls through to
// "not mobile" without needing an explicit iPad exclusion.
const TABLET_UA_REGEX = /iPad|Tablet|SM-T|Kindle|Silk/i;
const PHONE_UA_REGEX = /iPhone|iPod|CriOS|FxiOS|Windows Phone/i;

export function isMobileUserAgent(userAgent: string | null | undefined): boolean {
  if (!userAgent) return false;
  if (TABLET_UA_REGEX.test(userAgent)) return false;

  // Android alone isn't enough — tablets carry "Android" too but omit
  // "Mobile" from the UA string, which is the standard signal phones include
  // and tablets don't.
  if (/Android/i.test(userAgent)) return /Mobile/i.test(userAgent);

  return PHONE_UA_REGEX.test(userAgent);
}
