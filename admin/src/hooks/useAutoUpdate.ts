'use client';

import { useEffect, useRef, useState } from 'react';

interface VersionInfo {
  v: string;
  t: number;
}

interface UseAutoUpdateOptions {
  /** Intervalo de polling en ms. Default: 90_000 (90s) */
  pollInterval?: number;
  /** Segundos de countdown antes de recargar automáticamente. Default: 8 */
  autoReloadAfter?: number;
}

interface UseAutoUpdateResult {
  updateAvailable: boolean;
  countdown: number;
  reloadNow: () => void;
  dismiss: () => void;
}

/**
 * 🔄 useAutoUpdate — Detección liviana de nuevas versiones del admin.
 *
 * Estrategia (consumo mínimo de red):
 * 1. Obtiene /version.json al montar (20 bytes, contiene el hash del build actual).
 * 2. Re-verifica en window 'focus' (cuando el usuario vuelve a la pestaña).
 * 3. Re-verifica cada `pollInterval` ms (default 90s).
 * 4. Si el hash cambió → muestra banner con countdown → recarga automática.
 *
 * Consumo de red estimado: ~1.5 KB/hora (20 bytes cada 90s).
 */
export function useAutoUpdate({
  pollInterval = 90_000,
  autoReloadAfter = 8,
}: UseAutoUpdateOptions = {}): UseAutoUpdateResult {
  const currentVersion = useRef<string | null>(null);
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [dismissed, setDismissed] = useState(false);
  const [countdown, setCountdown] = useState(autoReloadAfter);

  const fetchVersion = async (): Promise<VersionInfo | null> => {
    try {
      // Cache-busting con query param para evitar caché del browser en este fetch puntual
      const res = await fetch(`/version.json?_=${Date.now()}`, {
        cache: 'no-store',
        signal: AbortSignal.timeout(5000),
      });
      if (!res.ok) return null;
      return (await res.json()) as VersionInfo;
    } catch {
      return null;
    }
  };

  const checkForUpdate = async () => {
    const info = await fetchVersion();
    if (!info) return;

    // Primera visita: guardar la versión inicial
    if (currentVersion.current === null) {
      currentVersion.current = info.v;
      return;
    }

    // Detectar cambio de versión
    if (info.v !== currentVersion.current && !dismissed) {
      setUpdateAvailable(true);
    }
  };

  // Setup del polling y listener de window focus
  useEffect(() => {
    checkForUpdate(); // Check inmediato al montar

    const interval = setInterval(checkForUpdate, pollInterval);
    window.addEventListener('focus', checkForUpdate);

    return () => {
      clearInterval(interval);
      window.removeEventListener('focus', checkForUpdate);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pollInterval]);

  // Countdown de auto-recarga
  useEffect(() => {
    if (!updateAvailable || dismissed) return;

    setCountdown(autoReloadAfter);
    const timer = setInterval(() => {
      setCountdown(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          window.location.reload();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [updateAvailable, dismissed]);

  return {
    updateAvailable: updateAvailable && !dismissed,
    countdown,
    reloadNow: () => window.location.reload(),
    dismiss: () => {
      setDismissed(true);
      setUpdateAvailable(false);
    },
  };
}
