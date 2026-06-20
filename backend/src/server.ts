import app from './app';
import { initDatabase } from './config/db';

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    // Initialise database schema and test connections
    await initDatabase();
    
    app.listen(PORT, () => {
      console.log(`Laundry App Backend service running in ${process.env.NODE_ENV || 'development'} mode.`);
      console.log(`HTTP Server ready at http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server due to database bootstrapping error:', error);
    process.exit(1);
  }
};

startServer();
