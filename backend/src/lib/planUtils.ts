export function normalizePlanFeatures(features?: string[]): string[] {
  if (!features) return [];

  const seen = new Set<string>();
  return features.reduce<string[]>((normalized, feature) => {
    const value = feature.trim();
    const key = value.toLocaleLowerCase();
    if (!value || seen.has(key)) return normalized;
    seen.add(key);
    normalized.push(value);
    return normalized;
  }, []);
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function exactPlanNamePattern(name: string): RegExp {
  return new RegExp(`^${escapeRegex(name.trim())}$`, "i");
}

export function partialPlanNamePattern(search: string): RegExp {
  return new RegExp(escapeRegex(search.trim()), "i");
}
