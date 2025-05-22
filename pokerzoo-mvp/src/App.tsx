// App.tsx

import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import HomeTables from './pages/HomeTables';
import HomePage from './pages/HomePage';


export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/play" element={<HomeTables />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
