export const config = {
  apiBaseUrl: (import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8000').replace(/\/+$/, ''),
  useMock: import.meta.env.VITE_USE_MOCK === 'true',
  appDownloadUrl: import.meta.env.VITE_APP_DOWNLOAD_URL ?? '',
  // Development only: show console OTP codes from the backend. Never enable in production.
  showDevOtp: import.meta.env.VITE_SHOW_DEV_OTP === 'true',
} as const