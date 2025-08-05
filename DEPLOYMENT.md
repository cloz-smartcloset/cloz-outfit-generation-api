# Cloz Outfit Generation API

✅ **DEPLOYED**: https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator

## 🚀 Quick Test

### List Models
```bash
curl https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator/models
```

### Generate Outfit
```bash
curl -X POST https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator/generate \
  -H "Content-Type: application/json" \
  -d '{"products": ["test_product_1"], "options": {"model": "random", "maxPieces": 5}}'
```

## 📊 AWS Infrastructure

| Resource | ID | Status |
|----------|----|---------| 
| **Lambda Function** | ClozRandomLookGenerator | ✅ Active |
| **API Gateway** | kym0gf4um7 (Outfit_Generator_Backend) | ✅ Active |
| **PostgreSQL** | product_look_dim (8,684 products) | ✅ Connected |
| **DynamoDB** | Products-test (660 user items) | ✅ Connected |

## 🏷️ AWS Tags Applied
- Application: Cloz_Outfit_Generation_API
- Environment: production  
- Service: OutfitGeneration
- Component: Lambda/APIGateway
- Owner: Bernardo
- Project: ClozFashionPlatform

Full documentation in [README.md](./README.md)
