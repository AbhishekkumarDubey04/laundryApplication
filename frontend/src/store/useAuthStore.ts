import { create } from 'zustand';

export interface User {
  id: number;
  name: string;
  phone: string;
  email?: string;
  role: 'customer' | 'admin' | 'agent';
}

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isDarkMode: boolean;
  setAuth: (token: string, user: User) => void;
  updateUser: (user: Partial<User>) => void;
  logout: () => void;
  toggleTheme: () => void;
}

const useAuthStore = create<AuthState>((set) => {
  // Read initial states from LocalStorage for persistence
  const savedToken = localStorage.getItem('laundry_token');
  const savedUser = localStorage.getItem('laundry_user');
  const savedTheme = localStorage.getItem('laundry_theme') || 'light';
  
  // Set dark mode attribute on document root
  if (savedTheme === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
  } else {
    document.documentElement.removeAttribute('data-theme');
  }

  return {
    token: savedToken,
    user: savedUser ? JSON.parse(savedUser) : null,
    isAuthenticated: !!savedToken,
    isDarkMode: savedTheme === 'dark',
    
    setAuth: (token, user) => {
      localStorage.setItem('laundry_token', token);
      localStorage.setItem('laundry_user', JSON.stringify(user));
      set({ token, user, isAuthenticated: true });
    },
    
    updateUser: (updatedFields) => {
      set((state) => {
        if (!state.user) return {};
        const newUser = { ...state.user, ...updatedFields };
        localStorage.setItem('laundry_user', JSON.stringify(newUser));
        return { user: newUser };
      });
    },
    
    logout: () => {
      localStorage.removeItem('laundry_token');
      localStorage.removeItem('laundry_user');
      set({ token: null, user: null, isAuthenticated: false });
    },
    
    toggleTheme: () => {
      set((state) => {
        const nextTheme = !state.isDarkMode ? 'dark' : 'light';
        localStorage.setItem('laundry_theme', nextTheme);
        if (nextTheme === 'dark') {
          document.documentElement.setAttribute('data-theme', 'dark');
        } else {
          document.documentElement.removeAttribute('data-theme');
        }
        return { isDarkMode: !state.isDarkMode };
      });
    }
  };
});

export default useAuthStore;
