interface AlertProps {
  children: React.ReactNode
  type: 'error' | 'success'
}

export function Alert({ children, type }: AlertProps) {
  return <div className={`alert alert-${type}`} role="alert">{children}</div>
}