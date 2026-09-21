// Utilitaire concurrence partagé (Phase 4).

/** Exécute `tasks` avec au plus `limit` promesses simultanées. */
export async function runWithConcurrency<T>(
  tasks: Array<() => Promise<T>>,
  limit: number,
): Promise<T[]> {
  const results: T[] = new Array(tasks.length);
  let next = 0;
  const workers = Array.from(
    { length: Math.min(limit, tasks.length) },
    async () => {
      while (next < tasks.length) {
        const i = next++;
        results[i] = await tasks[i]();
      }
    },
  );
  await Promise.all(workers);
  return results;
}
