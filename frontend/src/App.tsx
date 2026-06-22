import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, theme } from 'antd';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import LandingPage from './pages/LandingPage.tsx';
import LoginPage from './pages/LoginPage.tsx';
import DashboardPage from './pages/DashboardPage.tsx';
import BookingFlow from './pages/BookingFlow.tsx';
import TrackingPage from './pages/TrackingPage.tsx';
import AdminDashboard from './pages/AdminDashboard.tsx';
import AdminPricing from './pages/AdminPricing.tsx';
import AdminCoupons from './pages/AdminCoupons.tsx';
import useAuthStore from './store/useAuthStore.ts';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1
    }
  }
});

// Guard route for authenticated users
const ProtectedRoute = ({ children, allowedRoles }: { children: React.ReactNode; allowedRoles?: string[] }) => {
  const { isAuthenticated, user } = useAuthStore();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (allowedRoles && user && !allowedRoles.includes(user.role)) {
    return <Navigate to={user.role === 'admin' ? '/admin' : '/dashboard'} replace />;
  }
  
  return <>{children}</>;
};

function App() {
  const { isDarkMode } = useAuthStore();

  return (
    <QueryClientProvider client={queryClient}>
      <ConfigProvider
        theme={{
          algorithm: isDarkMode ? theme.darkAlgorithm : theme.defaultAlgorithm,
          token: {
            colorPrimary: '#FF6B00',
            colorSuccess: '#00C853',
            colorWarning: '#FFC107',
            fontFamily: 'Outfit, Inter, sans-serif',
            borderRadius: 8
          },
          components: {
            Button: {
              controlHeight: 40,
              fontWeight: 500
            },
            Input: {
              controlHeight: 40
            }
          }
        }}
      >
        <BrowserRouter>
          <Routes>
            {/* Public routes */}
            <Route path="/" element={<LandingPage />} />
            <Route path="/login" element={<LoginPage />} />

            {/* Customer routes */}
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute allowedRoles={['customer', 'admin']}>
                  <DashboardPage />
                </ProtectedRoute>
              }
            />
            <Route
              path="/book"
              element={
                <ProtectedRoute allowedRoles={['customer']}>
                  <BookingFlow />
                </ProtectedRoute>
              }
            />
            <Route
              path="/track/:id"
              element={
                <ProtectedRoute allowedRoles={['customer', 'admin']}>
                  <TrackingPage />
                </ProtectedRoute>
              }
            />

            {/* Admin routes */}
            <Route
              path="/admin"
              element={
                <ProtectedRoute allowedRoles={['admin']}>
                  <AdminDashboard />
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/pricing"
              element={
                <ProtectedRoute allowedRoles={['admin']}>
                  <AdminPricing />
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/coupons"
              element={
                <ProtectedRoute allowedRoles={['admin']}>
                  <AdminCoupons />
                </ProtectedRoute>
              }
            />

            {/* Fallback */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </ConfigProvider>
    </QueryClientProvider>
  );
}

export default App;
