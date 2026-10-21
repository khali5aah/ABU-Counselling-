export interface RegistrationRequest {
  first_name: string
  last_name: string
  matric_number: string
  phone_number: string
}

export interface RegistrationResponse extends RegistrationRequest {
  created_at: string
}

export interface ApiErrorBody {
  error: {
    code: string
    message: string
    fields?: Record<string, string[]>
    retry_after?: number
  }
}

export type ErrorCode =
  | 'validation_error' | 'invalid_otp' | 'otp_expired' | 'otp_attempts_exceeded'
  | 'setup_token_invalid' | 'invalid_credentials' | 'not_authenticated' | 'token_invalid'
  | 'permission_denied' | 'not_found' | 'method_not_allowed' | 'duplicate'
  | 'rate_limited' | 'server_error' | 'network_error'

export class ApiError extends Error {
  status: number
  code: ErrorCode | string
  fields: Record<string, string[]>
  retryAfter?: number

  constructor(
    status: number,
    code: ErrorCode | string,
    message: string,
    fields: Record<string, string[]> = {},
    retryAfter?: number,
  ) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
    this.fields = fields
    this.retryAfter = retryAfter
  }
}