import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Weather } from './pages/Weather';
import './App.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      // Consider data fresh for 30 seconds
      staleTime: 30 * 1000,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Weather />
    </QueryClientProvider>
  );
}

export default App;
