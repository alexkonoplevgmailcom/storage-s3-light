// MongoDB initialization script
// This script creates the BfbTemplate database and a user for the application

db = db.getSiblingDB('BfbTemplate');

// Create a user for the application
db.createUser({
  user: 'bfbapp',
  pwd: 'bfbapp123',
  roles: [
    {
      role: 'readWrite',
      db: 'BfbTemplate'
    }
  ]
});

// Create indexes for better performance
db.customers.createIndex({ "business_id": 1 }, { unique: true });
db.customers.createIndex({ "email": 1 }, { unique: true });
db.customerTransactions.createIndex({ "business_id": 1 }, { unique: true });
db.customerTransactions.createIndex({ "customer_id": 1 });

print('Database initialization completed successfully');
