import { Navigate, Route, Routes } from 'react-router-dom'
import { config } from './config'
import { MockBanner } from './components/MockBanner'
import { NotFoundPage } from './pages/NotFoundPage'
import { RegisterPage } from './pages/RegisterPage'
import { RegisteredPage } from './pages/RegisteredPage'

export default function App() {
  return (
    <>
      {config.useMock && <MockBanner />}
      <Routes>
        <Route path="/" element={<Navigate to="/register" replace />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/registered" element={<RegisteredPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </>
  )
}
