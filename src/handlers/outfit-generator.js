/**
 * Cloz Outfit Generation API - Clean Lambda Handler
 * Generates outfits with multiple models using Google JavaScript Style Guide
 */

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');
const {Client} = require('pg');

// AWS services configuration
const dynamoDBClient = new DynamoDBClient({
  region: process.env.AWS_REGION || 'eu-west-3',
});
const dynamoDB = DynamoDBDocumentClient.from(dynamoDBClient);

// Generation models
const MODELS = {
  RANDOM: 'random',
  AI_MODEL_1: 'ai_model_1',
  AI_MODEL_2: 'ai_model_2',
  AI_MODEL_3: 'ai_model_3',
  COMMUNITY: 'community',
  STYLIST: 'stylist',
};

/**
 * Main Lambda handler for AWS API Gateway
 * @param {Object} event - API Gateway event
 * @return {Object} HTTP response
 */
exports.handler = async (event) => {
  console.log('Request:', JSON.stringify(event, null, 2));

  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };

  try {
    // Handle preflight CORS
    if (event.httpMethod === 'OPTIONS') {
      return {statusCode: 200, headers: corsHeaders, body: ''};
    }

    const {path = '/', httpMethod: method} = event;

    // GET /models
    if (method === 'GET' && path.includes('/models')) {
      return {
        statusCode: 200,
        headers: {...corsHeaders, 'Content-Type': 'application/json'},
        body: JSON.stringify({
          success: true,
          models: getAvailableModels(),
        }),
      };
    }

    // POST /generate
    if (method === 'POST' && 
        (path.includes('/generate') || path.includes('/outfit_generator'))) {
      const {products, userId, options = {}} = JSON.parse(event.body || '{}');

      if (!products || !Array.isArray(products) || products.length === 0) {
        return createErrorResponse(corsHeaders, 400, 
            'Products array required with at least one product ID');
      }

      const result = await generateOutfit(products, userId, options);
      return {
        statusCode: result.success ? 200 : 400,
        headers: {...corsHeaders, 'Content-Type': 'application/json'},
        body: JSON.stringify(result),
      };
    }

    // Not found
    return createErrorResponse(corsHeaders, 404, 'Endpoint not found');

  } catch (error) {
    console.error('Handler error:', error);
    return createErrorResponse(corsHeaders, 500, 'Internal server error');
  }
};

/**
 * Create error response
 * @param {Object} headers - Response headers
 * @param {number} statusCode - HTTP status code
 * @param {string} message - Error message
 * @return {Object} HTTP response
 */
function createErrorResponse(headers, statusCode, message) {
  return {
    statusCode,
    headers: {...headers, 'Content-Type': 'application/json'},
    body: JSON.stringify({
      success: false,
      error: message,
      outfit: null,
    }),
  };
}

/**
 * Get available generation models
 * @return {Array} List of models
 */
function getAvailableModels() {
  return Object.entries(MODELS).map(([key, value]) => ({
    id: value,
    name: formatModelName(key),
    version: value === MODELS.RANDOM ? '1.0.0' : '0.0.0',
    status: value === MODELS.RANDOM ? 'active' : 'coming_soon',
    description: getModelDescription(value),
  }));
}

/**
 * Format model name from constant
 * @param {string} key - Model constant key
 * @return {string} Formatted name
 */
function formatModelName(key) {
  return key.replace(/_/g, ' ').toLowerCase()
      .replace(/\b\w/g, (l) => l.toUpperCase());
}

/**
 * Get model description
 * @param {string} model - Model ID
 * @return {string} Model description
 */
function getModelDescription(model) {
  const descriptions = {
    [MODELS.RANDOM]: 'Random outfit generation with style coherence',
    [MODELS.AI_MODEL_1]: 'AI-powered style matching (coming soon)',
    [MODELS.AI_MODEL_2]: 'Advanced AI with preferences (coming soon)',
    [MODELS.AI_MODEL_3]: 'Trend-aware AI (coming soon)',
    [MODELS.COMMUNITY]: 'Community recommendations (coming soon)',
    [MODELS.STYLIST]: 'Professional curation (coming soon)',
  };
  return descriptions[model] || 'Model description not available';
}

/**
 * Generate outfit from input products
 * @param {Array} inputProducts - Product IDs
 * @param {string} userId - User ID (optional)
 * @param {Object} options - Generation options
 * @return {Object} Generation result
 */
async function generateOutfit(inputProducts, userId = null, options = {}) {
  try {
    const model = options.model || MODELS.RANDOM;

    // Validate model
    if (!Object.values(MODELS).includes(model)) {
      throw new Error(`Invalid model: ${model}`);
    }

    // Only random model implemented
    if (model !== MODELS.RANDOM) {
      throw new Error(`${model} not yet implemented. Use 'random'`);
    }

    // Get products from databases
    const baseProducts = await getProductDetails(inputProducts, userId);

    // Generate random outfit
    const outfitProducts = await generateRandomOutfit(baseProducts, options);

    return {
      success: true,
      outfit: {
        id: `outfit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        products: outfitProducts,
        metadata: {
          total_pieces: outfitProducts.length,
          generation_model: model,
          model_version: '1.0.0',
          data_sources: {
            general: outfitProducts.filter((p) => p.source === 'general').length,
            user: outfitProducts.filter((p) => p.source === 'user').length,
          },
        },
        source: userId ? 'mixed' : 'general',
        created_at: new Date().toISOString(),
      },
    };

  } catch (error) {
    console.error('Generation failed:', error);
    return {
      success: false,
      error: error.message,
      outfit: null,
    };
  }
}

/**
 * Get product details from PostgreSQL and DynamoDB
 * @param {Array} productIds - Product IDs to fetch
 * @param {string} userId - User ID for private products
 * @return {Array} Product details
 */
async function getProductDetails(productIds, userId) {
  const products = [];
  
  const pgClient = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.USER,
    password: process.env.DB_PASSWORD,
    ssl: {rejectUnauthorized: false},
  });

  try {
    await pgClient.connect();

    for (const productId of productIds) {
      // Check user's private products first
      if (userId) {
        const userProduct = await getUserProduct(productId, userId);
        if (userProduct) {
          products.push({
            ...userProduct,
            source: 'user',
            privacy: 'private',
            match_reason: 'input',
          });
          continue;
        }
      }

      // Get from general catalog
      const generalProduct = await getGeneralProduct(pgClient, productId);
      if (generalProduct) {
        products.push({
          ...generalProduct,
          source: 'general',
          privacy: 'public',
          match_reason: 'input',
        });
      }
    }
  } catch (error) {
    console.error('PostgreSQL connection error:', error.message);
    throw error;
  } finally {
    await pgClient.end();
  }

  return products;
}

/**
 * Get user's private product from DynamoDB
 * @param {string} productId - Product ID
 * @param {string} userId - User ID
 * @return {Object|null} Product or null
 */
async function getUserProduct(productId, userId) {
  try {
    const result = await dynamoDB.send(new GetCommand({
      TableName: 'Products-test',
      Key: {product_id: productId},
    }));

    // Check if product belongs to user
    if (result.Item && result.Item.user_id === userId) {
      return result.Item;
    }
    return null;
  } catch (error) {
    console.error('DynamoDB error:', error);
    return null;
  }
}

/**
 * Get general product from PostgreSQL
 * @param {Object} pgClient - PostgreSQL client
 * @param {string} productId - Product ID
 * @return {Object|null} Product or null
 */
async function getGeneralProduct(pgClient, productId) {
  try {
    const result = await pgClient.query(
        'SELECT * FROM product_look_dim WHERE product_id = $1 LIMIT 1',
        [productId]
    );
    return result.rows[0] || null;
  } catch (error) {
    console.error('PostgreSQL error:', error);
    return null;
  }
}

/**
 * Generate random outfit
 * @param {Array} baseProducts - Base products from input
 * @param {Object} options - Generation options
 * @return {Array} Complete outfit products
 */
async function generateRandomOutfit(baseProducts, options) {
  const maxPieces = Math.min(options.maxPieces || 15, 15);
  const targetPieces = Math.min(
      Math.max(baseProducts.length, 3),
      maxPieces
  );

  const outfitProducts = [...baseProducts];

  // Add random complementary products if needed
  if (outfitProducts.length < targetPieces) {
    const complementary = await getComplementaryProducts(
        targetPieces - outfitProducts.length
    );
    outfitProducts.push(...complementary);
  }

  return outfitProducts.slice(0, targetPieces);
}

/**
 * Get complementary products from PostgreSQL
 * @param {number} count - Number of products needed
 * @return {Array} Complementary products
 */
async function getComplementaryProducts(count) {
  const products = [];
  
      const pgClient = new Client({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME,
      user: process.env.USER,
      password: process.env.DB_PASSWORD,
      ssl: {rejectUnauthorized: false},
    });

  try {
    await pgClient.connect();
    
    const result = await pgClient.query(
        'SELECT * FROM product_look_dim WHERE title IS NOT NULL ORDER BY RANDOM() LIMIT $1',
        [count]
    );

    result.rows.forEach((product) => {
      products.push({
        ...product,
        source: 'general',
        privacy: 'public',
        match_reason: 'complementary',
      });
    });
  } catch (error) {
    console.error('Complementary Products - PostgreSQL connection error:', error.message);
  } finally {
    await pgClient.end();
  }

  return products;
}