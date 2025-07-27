# Development Guide

This guide helps developers set up the local development environment and contribute to the project.

## Local Development Setup

### Prerequisites
- **Node.js** (v16+ recommended)
- **MySQL** (v8.0+)
- **Git**
- **VS Code** (recommended) with extensions:
  - REST Client
  - MySQL
  - Terraform
  - AWS Toolkit

### 1. Environment Setup

#### Clone and Install Dependencies
```bash
cd "Cloud Project/webapp"
npm install
```

#### Database Setup
```bash
# Start MySQL service
brew services start mysql  # macOS
sudo systemctl start mysql  # Linux

# Create database
mysql -u root -p
```

```sql
CREATE DATABASE webapp_dev;
CREATE USER 'webapp_user'@'localhost' IDENTIFIED BY 'dev_password';
GRANT ALL PRIVILEGES ON webapp_dev.* TO 'webapp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### Environment Configuration
```bash
cp .env.example .env
```

Edit `.env` for development:
```env
# Database Configuration
DB_HOST=localhost
DB_USER=webapp_user
DB_PASSWORD=dev_password
DB_NAME=webapp_dev
DB_PORT=3306

# Application Configuration
PORT=3000
NODE_ENV=development

# AWS Configuration (for S3 uploads)
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=webapp-dev-bucket
# Note: Configure AWS credentials via AWS CLI

# Logging
LOG_LEVEL=debug
```

### 2. Running the Application

#### Start the Server
```bash
npm start
# or for development with auto-reload
npm run dev  # If you add nodemon
```

#### Verify Installation
```bash
curl http://localhost:3000/healthz
# Should return 200 OK
```

### 3. Development Workflow

#### Database Migrations
```bash
# Install Sequelize CLI globally
npm install -g sequelize-cli

# Run migrations
npx sequelize-cli db:migrate

# Create new migration
npx sequelize-cli migration:generate --name add-new-field
```

#### Testing
```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- test/user.test.js
```

#### Code Quality
```bash
# Lint code
npm run lint

# Format code
npm run format

# Type checking (if using TypeScript)
npm run type-check
```

## Project Structure Deep Dive

```
webapp/
├── 📱 Application Entry Points
│   ├── app.js              # Main application entry
│   ├── index.js            # Express app configuration
│   └── package.json        # Dependencies and scripts
│
├── 🔧 Configuration
│   ├── config/
│   │   ├── sequelize.js    # Database ORM setup
│   │   ├── dbConfig.js     # Database connection
│   │   ├── user.js         # User model definition
│   │   ├── product.js      # Product model definition
│   │   └── image.js        # Image model definition
│   └── .env               # Environment variables
│
├── 🎯 Business Logic
│   ├── controllers/        # Request handlers
│   │   ├── userController.js
│   │   ├── productController.js
│   │   └── imageController.js
│   ├── routes/
│   │   └── route.js        # API route definitions
│   └── auth.js            # Authentication middleware
│
├── 🛠️ Utilities & Services
│   ├── database.js         # Database utilities
│   ├── upload.js          # File upload handling
│   ├── logging.js         # Winston logger setup
│   ├── userauth.js        # User authentication
│   └── utils.js           # General utilities
│
├── 🧪 Testing
│   └── test.js            # Test suites
│
└── 📦 Deployment
    └── packer/            # AMI building scripts
        ├── app.pkr.hcl    # Packer configuration
        ├── app.sh         # Installation script
        └── webapp.service # Systemd service file
```

## API Development

### Adding New Endpoints

#### 1. Create Controller
```javascript
// controllers/newController.js
const { Model } = require('../config/sequelize');
const logger = require('../logging');

exports.createItem = async (req, res) => {
  try {
    logger.info('Creating new item');
    
    // Validation
    const { field1, field2 } = req.body;
    if (!field1 || !field2) {
      return res.status(400).json({
        error: { message: 'Required fields missing' }
      });
    }

    // Business logic
    const item = await Model.create({
      field1,
      field2,
      userId: req.user.id
    });

    res.status(201).json(item);
  } catch (error) {
    logger.error('Error creating item:', error);
    res.status(500).json({
      error: { message: 'Internal server error' }
    });
  }
};
```

#### 2. Add Routes
```javascript
// routes/route.js
const newController = require('../controllers/newController');

module.exports = (app) => {
  // Existing routes...
  
  // New routes
  app.post('/v1/items', auth, newController.createItem);
  app.get('/v1/items/:id', newController.getItem);
  app.put('/v1/items/:id', auth, newController.updateItem);
  app.delete('/v1/items/:id', auth, newController.deleteItem);
};
```

#### 3. Add Tests
```javascript
// test/item.test.js
const request = require('supertest');
const app = require('../index');

describe('Item API', () => {
  describe('POST /v1/items', () => {
    it('should create a new item', async () => {
      const response = await request(app)
        .post('/v1/items')
        .set('Authorization', 'Basic ' + Buffer.from('user:pass').toString('base64'))
        .send({
          field1: 'value1',
          field2: 'value2'
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('id');
    });
  });
});
```

### Database Models

#### Creating New Models
```javascript
// config/newModel.js
const { DataTypes } = require('sequelize');
const { sequelize } = require('./sequelize');

const NewModel = sequelize.define('NewModel', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  field1: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      notEmpty: true,
      len: [1, 255]
    }
  },
  field2: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id'
    }
  }
}, {
  tableName: 'new_models',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = NewModel;
```

#### Model Associations
```javascript
// config/sequelize.js
const User = require('./user');
const Product = require('./product');
const Image = require('./image');
const NewModel = require('./newModel');

// Define associations
User.hasMany(Product, { foreignKey: 'owner_user_id' });
Product.belongsTo(User, { foreignKey: 'owner_user_id' });

Product.hasMany(Image, { foreignKey: 'product_id' });
Image.belongsTo(Product, { foreignKey: 'product_id' });

User.hasMany(NewModel, { foreignKey: 'userId' });
NewModel.belongsTo(User, { foreignKey: 'userId' });
```

## Testing Strategy

### Unit Tests
```javascript
// test/unit/userController.test.js
const userController = require('../../controllers/userController');
const User = require('../../config/user');

jest.mock('../../config/user');

describe('UserController', () => {
  describe('createUser', () => {
    it('should create user with valid data', async () => {
      const mockUser = { id: '123', username: 'test' };
      User.create.mockResolvedValue(mockUser);

      const req = {
        body: {
          first_name: 'John',
          last_name: 'Doe',
          username: 'johndoe',
          password: 'password123'
        }
      };
      const res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };

      await userController.createUser(req, res);

      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(mockUser);
    });
  });
});
```

### Integration Tests
```javascript
// test/integration/api.test.js
const request = require('supertest');
const app = require('../../index');
const { sequelize } = require('../../config/sequelize');

describe('API Integration Tests', () => {
  beforeAll(async () => {
    await sequelize.sync({ force: true });
  });

  afterAll(async () => {
    await sequelize.close();
  });

  describe('User Flow', () => {
    it('should complete full user flow', async () => {
      // Create user
      const userResponse = await request(app)
        .post('/v1/user')
        .send({
          first_name: 'John',
          last_name: 'Doe',
          username: 'johndoe',
          password: 'password123'
        });

      expect(userResponse.status).toBe(201);
      const userId = userResponse.body.id;

      // Get user
      const getResponse = await request(app)
        .get(`/v1/user/${userId}`)
        .set('Authorization', 'Basic ' + Buffer.from('johndoe:password123').toString('base64'));

      expect(getResponse.status).toBe(200);
      expect(getResponse.body.username).toBe('johndoe');
    });
  });
});
```

## Debugging

### VS Code Debug Configuration
Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Node.js App",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/webapp/app.js",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "envFile": "${workspaceFolder}/webapp/.env"
    }
  ]
}
```

### Logging Best Practices
```javascript
const logger = require('./logging');

// Use appropriate log levels
logger.error('Critical error occurred', { error: err, userId: req.user.id });
logger.warn('Warning condition', { condition: 'high_cpu' });
logger.info('User action', { action: 'login', userId: req.user.id });
logger.debug('Debug information', { query: sql, params: values });

// Log request/response for debugging
app.use((req, res, next) => {
  logger.debug('Incoming request', {
    method: req.method,
    url: req.url,
    headers: req.headers,
    body: req.body
  });
  next();
});
```

### Database Debugging
```javascript
// Enable Sequelize logging
const sequelize = new Sequelize(database, username, password, {
  host,
  dialect: 'mysql',
  logging: (sql, timing) => {
    logger.debug('SQL Query', { sql, timing });
  }
});

// Log query performance
const queryInterface = sequelize.getQueryInterface();
queryInterface.addIndex = function(...args) {
  logger.info('Adding database index', { args });
  return originalAddIndex.apply(this, args);
};
```

## Performance Optimization

### Database Optimization
```javascript
// Use indexes for frequently queried fields
// migrations/add-indexes.js
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addIndex('users', ['username']);
    await queryInterface.addIndex('products', ['sku']);
    await queryInterface.addIndex('products', ['owner_user_id']);
  }
};

// Use eager loading to avoid N+1 queries
const products = await Product.findAll({
  include: [
    { model: User, attributes: ['id', 'username'] },
    { model: Image, attributes: ['id', 'file_name'] }
  ]
});
```

### Caching Strategies
```javascript
const Redis = require('redis');
const client = Redis.createClient();

// Cache frequently accessed data
exports.getProduct = async (req, res) => {
  const productId = req.params.productId;
  const cacheKey = `product:${productId}`;
  
  // Try cache first
  const cached = await client.get(cacheKey);
  if (cached) {
    return res.json(JSON.parse(cached));
  }
  
  // Fetch from database
  const product = await Product.findByPk(productId);
  
  // Cache for 5 minutes
  await client.setex(cacheKey, 300, JSON.stringify(product));
  
  res.json(product);
};
```

## Git Workflow

### Branch Strategy
```bash
# Feature development
git checkout -b feature/user-authentication
git commit -m "feat: add user authentication middleware"
git push origin feature/user-authentication

# Create pull request for review

# Bug fixes
git checkout -b fix/database-connection-error
git commit -m "fix: resolve database connection timeout"
```

### Commit Message Convention
```
feat: add new product search functionality
fix: resolve user authentication bug
docs: update API documentation
test: add unit tests for user controller
refactor: optimize database queries
style: fix code formatting issues
```

## Code Standards

### ESLint Configuration
Create `.eslintrc.js`:
```javascript
module.exports = {
  env: {
    node: true,
    es2021: true,
    jest: true
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  rules: {
    'no-unused-vars': 'error',
    'no-console': 'warn',
    'semi': ['error', 'always'],
    'quotes': ['error', 'single']
  }
};
```

### Prettier Configuration
Create `.prettierrc`:
```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
```
