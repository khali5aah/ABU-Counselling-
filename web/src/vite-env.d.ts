/// <reference types="vite/client" />

interface ImportMetaEnv {
	readonly VITE_API_BASE_URL?: string
	readonly VITE_USE_MOCK?: string
	readonly VITE_APP_DOWNLOAD_URL?: string
	readonly VITE_SHOW_DEV_OTP?: string
}

interface ImportMeta {
	readonly env: ImportMetaEnv
}
