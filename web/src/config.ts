export const config = {
  apiBaseUrl: (import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000').replace(/\/+$/, ''),
  useMock: import.meta.env.VITE_USE_MOCK === 'true',
  appDownloadUrl: import.meta.env.VITE_APP_DOWNLOAD_URL ?? '',
} as const