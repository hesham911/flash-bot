import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Dashboard = () => {
  const [status, setStatus] = useState({ loading: true });

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await axios.get('/api/health', {
          headers: { Authorization: `Bearer ${token}` }
        });
        setStatus({ ...response.data, loading: false });
      } catch (error) {
        setStatus({ error: error.message, loading: false });
      }
    };

    fetchStatus();
  }, []);

  if (status.loading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="dashboard">
      <h1>🚀 FlashLoan Arbitrage Bot</h1>
      <div className="status-card">
        <h2>System Status</h2>
        <p>Status: {status.status || 'Error'}</p>
        <p>Uptime: {status.uptime ? Math.floor(status.uptime) + 's' : 'N/A'}</p>
        <p>Environment: {status.environment || 'Unknown'}</p>
        {status.error && <p style={{color: 'red'}}>Error: {status.error}</p>}
      </div>
    </div>
  );
};

export default Dashboard;
