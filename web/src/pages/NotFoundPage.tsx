import { Link } from 'react-router-dom'

export function NotFoundPage() {
  return (
    <main className="page-shell">
      <section className="form-panel not-found-panel">
        <p className="eyebrow">404 · PAGE NOT FOUND</p>
        <h1>This page isn't here.</h1>
        <Link className="button button-primary" to="/register">Go to registration <span aria-hidden="true">→</span></Link>
      </section>
    </main>
  )
}