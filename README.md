# Cloz Outfit Generation API

**Advanced outfit generation service with multiple AI models and realistic clothing constraints**

[![AWS](https://img.shields.io/badge/AWS-API%20Gateway%20%2B%20Lambda-orange)](https://aws.amazon.com/)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)](https://postgresql.org/)
[![DynamoDB](https://img.shields.io/badge/DynamoDB-NoSQL-yellow)](https://aws.amazon.com/dynamodb/)

---

## 🎯 Overview

The Cloz Outfit Generation API creates complete fashion looks from product inputs using multiple generation models. It combines **8,684 products** from PostgreSQL with **660 private user items** from DynamoDB, applying realistic clothing constraints for anatomically correct outfits.

### Key Features
- **Multiple Generation Models**: Random, AI, Community, Stylist (extensible)
- **Dual Data Sources**: Public catalog (PostgreSQL) + Private wardrobe (DynamoDB)
- **Realistic Constraints**: 15 body areas with proper layering (3-15 pieces per outfit)
- **Privacy-Aware**: Separates public and private products
- **Scalable Architecture**: AWS serverless with API Gateway + Lambda

---

## 🚀 Quick Start

### Base URL
```
https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator
```

### Generate Outfit
```bash
curl -X POST https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator/generate \
  -H "Content-Type: application/json" \
  -d '{
    "products": ["product_123", "product_456"],
    "userId": "user_789",
    "options": {
      "model": "random",
      "maxPieces": 8
    }
  }'
```

### List Available Models
```bash
curl https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator/models
```

---

## 📚 API Documentation

### Authentication
Currently **no authentication required**. Future versions will implement API key authentication.

### Endpoints

#### `GET /models`
List all available generation models.

**Response:**
```json
{
  "success": true,
  "models": [
    {
      "id": "random",
      "name": "Random",
      "version": "1.0.0",
      "status": "active",
      "description": "Random outfit generation with style coherence and clothing constraints"
    },
    {
      "id": "ai_model_1",
      "name": "Ai Model 1",
      "version": "0.0.0", 
      "status": "coming_soon",
      "description": "AI-powered style matching with color and occasion preferences"
    }
  ]
}
```

#### `POST /generate`
Generate a complete outfit from input products.

**Request Body:**
```json
{
  "products": ["product_id_1", "product_id_2"],
  "userId": "user123",
  "options": {
    "model": "random",
    "maxPieces": 10,
    "style": "casual",
    "occasion": "work"
  }
}
```

**Parameters:**
- `products` (required): Array of product IDs to include in outfit
- `userId` (optional): User ID for accessing private wardrobe items
- `options` (optional): Generation preferences
  - `model`: Generation model (`random`, `ai_model_1`, etc.)
  - `maxPieces`: Maximum items in outfit (3-15)
  - `style`: Style preference (future use)
  - `occasion`: Occasion targeting (future use)

**Response:**
```json
{
  "success": true,
  "outfit": {
    "id": "outfit_1691234567890_abc123def",
    "products": [
      {
        "product_id": "123",
        "title": "Blue Cotton Shirt",
        "category": "shirt",
        "price": "49.99",
        "color": "blue",
        "brand": "Zara",
        "source": "general",
        "privacy": "public",
        "match_reason": "input"
      }
    ],
    "metadata": {
      "total_pieces": 8,
      "generation_model": "random",
      "model_version": "1.0.0",
      "occasions": ["casual", "work"],
      "style_tags": ["minimalist", "professional"],
      "color_scheme": ["blue", "white", "black"],
      "price_range": {
        "min": 19.99,
        "max": 149.99,
        "total": 387.50
      },
      "brands": ["Zara", "H&M", "Nike"],
      "data_sources": {
        "general": 6,
        "user": 2
      }
    },
    "source": "mixed",
    "created_at": "2025-08-05T17:30:00.000Z"
  }
}
```

**Product Fields:**
- `source`: `"general"` (PostgreSQL) or `"user"` (DynamoDB)
- `privacy`: `"public"` or `"private"`
- `match_reason`: `"input"`, `"essential"`, or `"complementary"`

---

## 🧠 Generation Models

### Currently Available

#### **Random Model** (`random` v1.0.0)
- **Status**: ✅ Active
- **Logic**: Random selection with style coherence
- **Features**: 
  - Identifies missing essentials (shirt, pants, shoes)
  - Adds complementary pieces based on color/style matching
  - Applies realistic clothing constraints
- **Use Case**: Baseline generation for testing and fallback

### Coming Soon

#### **AI Model 1** (`ai_model_1`)
- **Features**: AI-powered style matching with color and occasion preferences
- **Training**: Color harmony, seasonal trends, occasion matching

#### **AI Model 2** (`ai_model_2`) 
- **Features**: Advanced AI with user preference learning
- **Training**: User interaction history, preference patterns

#### **AI Model 3** (`ai_model_3`)
- **Features**: Trend-aware AI with cultural intelligence
- **Training**: Fashion trends, cultural preferences, seasonal data

#### **Community Model** (`community`)
- **Features**: Community-driven recommendations
- **Data Source**: Popular outfit combinations from user interactions

#### **Stylist Model** (`stylist`)
- **Features**: Professional stylist curation
- **Data Source**: Expert fashion knowledge and manual curation

---

## 👗 Clothing Constraints

The API enforces realistic clothing limits per body area to ensure anatomically correct outfits:

### Body Areas (15 total)
- **HEAD**: Max 1 (hats, caps, beanies)
- **EYES**: Max 1 (glasses, sunglasses)  
- **NECK**: Max 1 (necklaces, scarves, ties)
- **TORSO**: Underwear(1) + Main(1) + Outer(1)
- **ARMS/WRISTS**: Max 1 (watches, bracelets)
- **WAIST**: Max 1 (belts, sashes)
- **LEGS**: Underwear(1) + Main(1) + Hosiery(1)
- **FEET**: Hosiery(1) + Main(1) (socks + shoes)
- **FINGERS**: Max 1 (rings)
- **EARS**: Max 1 (earrings)

### Outfit Limits
- **Minimum**: 3 pieces (underwear + main clothing + shoes)
- **Maximum**: 15 pieces (all body areas covered)
- **Typical**: 6-10 pieces for balanced looks

---

## 🗄️ Data Sources

### PostgreSQL (General Catalog)
- **Table**: `product_look_dim`
- **Records**: 8,684 products
- **Access**: Public, all users
- **Host**: `test-cloz.c[...].eu-west-3.rds.amazonaws.com`
- **Fields**: product_id, title, category, price, color, brand, style, occasion

### DynamoDB (User Private Data)
- **Table**: `Products-test`
- **Records**: 660 user items
- **Access**: Private, user-specific
- **Privacy**: Marked as private in API responses
- **Fields**: product_id, user_id, title, category, price, personal_tags

---

## 🏗️ Architecture

### AWS Serverless Stack
```
API Gateway (kym0gf4um7) 
    ↓
Lambda Function (ClozOutfitGenerator)
    ↓
┌─────────────────┬─────────────────┐
│   PostgreSQL    │    DynamoDB     │
│ (8,684 products)│ (660 user items)│
│   Public Data   │  Private Data   │
└─────────────────┴─────────────────┘
```

### Lambda Environment Variables
```bash
# PostgreSQL Connection
PG_HOST=test-cloz.c[...].eu-west-3.rds.amazonaws.com
PG_PORT=5432
PG_DATABASE=test-cloz
PG_USER=postgres
PG_PASSWORD=[secured]

# AWS Configuration
AWS_REGION=eu-west-3
DYNAMODB_PRODUCTS_TABLE=Products-test

# API Configuration
NODE_ENV=production
```

### IAM Permissions Required
- `dynamodb:GetItem` - Read user products
- `dynamodb:Query` - Search user products
- `rds:DescribeDBInstances` - PostgreSQL access
- `logs:CreateLogGroup` - CloudWatch logging
- `logs:CreateLogStream` - CloudWatch logging
- `logs:PutLogEvents` - CloudWatch logging

---

## 🔧 Development

### Local Setup
```bash
# Clone repository
git clone https://github.com/cloz-smartcloset/cloz-outfit-generation-api.git
cd cloz-outfit-generation-api

# Install dependencies
npm install

# Set environment variables
cp .env.example .env
# Edit .env with your database credentials

# Run tests
npm test

# Deploy to AWS
npm run deploy
```

### Project Structure
```
cloz-outfit-generation-api/
├── src/
│   ├── handlers/           # Lambda function handlers
│   ├── models/            # Generation model implementations
│   ├── services/          # Database and external services
│   ├── utils/             # Utility functions
│   └── constants/         # Configuration constants
├── tests/                 # Unit and integration tests
├── deploy/               # AWS deployment scripts
├── docs/                 # Additional documentation
└── README.md
```

---

## 🧪 Testing

### Unit Tests
```bash
npm test
```

### Integration Tests
```bash
npm run test:integration
```

### API Testing Examples

#### Test Random Generation
```bash
curl -X POST localhost:3000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "products": ["test_product_1"],
    "options": {"model": "random", "maxPieces": 5}
  }'
```

#### Test Model Validation
```bash
curl -X POST localhost:3000/generate \
  -H "Content-Type: application/json" \
  -d '{
    "products": ["test_product_1"],
    "options": {"model": "invalid_model"}
  }'
```

---

## 📊 Performance

### Response Times (Target)
- Model listing: < 100ms
- Outfit generation: < 2000ms
- Error responses: < 50ms

### Rate Limits
- 100 requests/minute per IP (current)
- 1000 requests/hour per user (planned)

### Caching Strategy
- Model metadata: 1 hour TTL
- Product data: 15 minutes TTL
- Generated outfits: No caching (always fresh)

---

## 🚀 Deployment

### AWS Lambda Deployment
```bash
# Package function
zip -r outfit-generator.zip src/ node_modules/

# Update Lambda function
aws lambda update-function-code \
  --function-name ClozOutfitGenerator \
  --zip-file fileb://outfit-generator.zip \
  --region eu-west-3
```

### API Gateway Configuration
- **Base Path**: `/outfit_generator`
- **Stage**: `prod`
- **CORS**: Enabled for all origins
- **Throttling**: 1000 requests/second

---

## 🔍 Monitoring

### CloudWatch Metrics
- Invocation count
- Error rate
- Duration
- Throttle count

### Custom Metrics
- Generation model usage
- Outfit complexity distribution
- Data source utilization
- User privacy preferences

### Alerts
- Error rate > 5%
- Average duration > 5 seconds
- DynamoDB throttling events

---

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards
- ESLint configuration provided
- Prettier for code formatting
- JSDoc for function documentation
- Unit tests required for new features

---

## 📄 License

This project is proprietary software owned by Cloz Smart Closet.

---

## 📞 Support

- **Technical Issues**: Create GitHub issue
- **Business Inquiries**: contact@cloz-smartcloset.com
- **API Status**: [AWS CloudWatch Dashboard]

---

## 🔮 Roadmap

### Q3 2025
- ✅ Random generation model
- 🔄 AI Model 1 (color matching)
- 🔄 API authentication
- 🔄 Rate limiting

### Q4 2025
- 📅 AI Model 2 (preference learning)
- 📅 Community model
- 📅 Advanced analytics
- 📅 Mobile SDK

### Q1 2026
- 📅 AI Model 3 (trend awareness)
- 📅 Stylist model
- 📅 Real-time recommendations
- 📅 Global expansion

---

**Made with ❤️ by the Cloz team**