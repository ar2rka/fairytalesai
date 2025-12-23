import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { LoginPage } from './pages/auth/LoginPage';
import { RegisterPage } from './pages/auth/RegisterPage';
import { ResetPasswordPage } from './pages/auth/ResetPasswordPage';
import { ResetPasswordConfirmPage } from './pages/auth/ResetPasswordConfirmPage';
import { DashboardPage } from './pages/dashboard/DashboardPage';
import { AddChildPage } from './pages/children/AddChildPage';
import { ViewChildrenPage } from './pages/children/ViewChildrenPage';
import { ChildDetailPage } from './pages/children/ChildDetailPage';
import { GenerateStoryPage } from './pages/stories/GenerateStoryPage';
import { StoriesListPage } from './pages/stories/StoriesListPage';
import { StoryDetailPage } from './pages/stories/StoryDetailPage';
import { HeroesListPage } from './pages/heroes/HeroesListPage';
import { HeroDetailPage } from './pages/heroes/HeroDetailPage';
import { CreateHeroPage } from './pages/heroes/CreateHeroPage';
import { EditHeroPage } from './pages/heroes/EditHeroPage';
import { SubscriptionPage } from './pages/subscription/SubscriptionPage';
import { PlansPage } from './pages/subscription/PlansPage';
import { CheckoutPage } from './pages/subscription/CheckoutPage';

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          {/* Public Routes */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="/reset-password/confirm" element={<ResetPasswordConfirmPage />} />

          {/* Protected Routes */}
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <DashboardPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/children/add"
            element={
              <ProtectedRoute>
                <AddChildPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/children"
            element={
              <ProtectedRoute>
                <ViewChildrenPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/children/:childId"
            element={
              <ProtectedRoute>
                <ChildDetailPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/stories/generate"
            element={
              <ProtectedRoute>
                <GenerateStoryPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/stories"
            element={
              <ProtectedRoute>
                <StoriesListPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/stories/:storyId"
            element={
              <ProtectedRoute>
                <StoryDetailPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/heroes"
            element={
              <ProtectedRoute>
                <HeroesListPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/heroes/:heroId"
            element={
              <ProtectedRoute>
                <HeroDetailPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/heroes/create"
            element={
              <ProtectedRoute>
                <CreateHeroPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/heroes/:heroId/edit"
            element={
              <ProtectedRoute>
                <EditHeroPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/subscription"
            element={
              <ProtectedRoute>
                <SubscriptionPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/subscription/plans"
            element={
              <ProtectedRoute>
                <PlansPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/subscription/checkout"
            element={
              <ProtectedRoute>
                <CheckoutPage />
              </ProtectedRoute>
            }
          />

          {/* Catch all - redirect to home */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;