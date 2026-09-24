export function normalizeHex(value: string): string | null {
  const text = value.trim().replace(/^#/, "");
  if (/^[\da-f]{3}$/i.test(text))
    return `#${text
      .split("")
      .map((c) => c + c)
      .join("")
      .toUpperCase()}`;
  return /^[\da-f]{6}$/i.test(text) ? `#${text.toUpperCase()}` : null;
}
export function safeHex(value: unknown, fallback: string): string {
  return typeof value === "string"
    ? (normalizeHex(value) ?? fallback)
    : fallback;
}
