import { config } from '../config'
import { ApiError, type ApiErrorBody } from './types'

const networkMessage = "Can't reach the server. Check your connection and try again."
const serverMessage = 'Something went wrong. Please try again.'

export async function request<T>(method: 'GET' | 'POST', path: string, body?: unknown): Promise<T> {
  const controller = new AbortController()
  const timeout = window.setTimeout(() => controller.abort(), 15_000)
  try {
    let response: Response
    try {
      response = await fetch(`${config.apiBaseUrl}${path}`, {
        method,
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: controller.signal,
      })
    } catch {
      throw new ApiError(0, 'network_error', networkMessage)
    }

    if (response.status === 204) return undefined as T
    if (response.ok) return await response.json() as T
    try {
      const payload = await response.json() as ApiErrorBody
      if (payload.error?.code) {
        throw new ApiError(response.status, payload.error.code, payload.error.message,
          payload.error.fields ?? {}, payload.error.retry_after)
      }
    } catch (error) {
      if (error instanceof ApiError) throw error
    }
    throw new ApiError(response.status, 'server_error', serverMessage)
  } finally {
    window.clearTimeout(timeout)
  }
}