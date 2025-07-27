# API Documentation

## Base URL
```
Production: https://your-domain.com
Development: http://localhost:3000
```

## Authentication
Most endpoints require Basic Authentication using username and password.

```
Authorization: Basic <base64(username:password)>
```

## Response Format
All API responses follow this format:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed successfully"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE"
  }
}
```

## Endpoints

### Health Check

#### GET /healthz
Check application health status.

**Response:**
- `200 OK` - Application is healthy
- `503 Service Unavailable` - Application is unhealthy

```bash
curl -X GET http://localhost:3000/healthz
```

---

### User Management

#### POST /v1/user
Create a new user account.

**Request Body:**
```json
{
  "first_name": "string (required)",
  "last_name": "string (required)", 
  "username": "string (required, unique)",
  "password": "string (required, min 8 chars)"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "first_name": "John",
  "last_name": "Doe",
  "username": "johndoe",
  "account_created": "2025-07-27T10:00:00Z",
  "account_updated": "2025-07-27T10:00:00Z"
}
```

**Example:**
```bash
curl -X POST http://localhost:3000/v1/user \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "username": "johndoe",
    "password": "securepassword123"
  }'
```

#### GET /v1/user/:userId
Get user information (requires authentication).

**Headers:**
- `Authorization: Basic <credentials>`

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "first_name": "John",
  "last_name": "Doe", 
  "username": "johndoe",
  "account_created": "2025-07-27T10:00:00Z",
  "account_updated": "2025-07-27T10:00:00Z"
}
```

#### PUT /v1/user/:userId
Update user information (requires authentication).

**Headers:**
- `Authorization: Basic <credentials>`

**Request Body:**
```json
{
  "first_name": "string (optional)",
  "last_name": "string (optional)",
  "password": "string (optional)"
}
```

---

### Product Management

#### POST /v1/product
Create a new product (requires authentication).

**Headers:**
- `Authorization: Basic <credentials>`

**Request Body:**
```json
{
  "name": "string (required)",
  "description": "string (required)",
  "sku": "string (required, unique)",
  "manufacturer": "string (required)",
  "quantity": "number (required, min 0, max 100)"
}
```

**Response:** `201 Created`
```json
{
  "id": "uuid",
  "name": "Sample Product",
  "description": "Product description",
  "sku": "PROD-001",
  "manufacturer": "Sample Corp",
  "quantity": 100,
  "date_added": "2025-07-27T10:00:00Z",
  "date_last_updated": "2025-07-27T10:00:00Z",
  "owner_user_id": "user-uuid"
}
```

#### GET /v1/product/:productId
Get product information.

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "name": "Sample Product",
  "description": "Product description", 
  "sku": "PROD-001",
  "manufacturer": "Sample Corp",
  "quantity": 100,
  "date_added": "2025-07-27T10:00:00Z",
  "date_last_updated": "2025-07-27T10:00:00Z",
  "owner_user_id": "user-uuid"
}
```

#### PUT /v1/product/:productId
Update entire product (requires authentication & ownership).

**Headers:**
- `Authorization: Basic <credentials>`

**Request Body:**
```json
{
  "name": "string (required)",
  "description": "string (required)",
  "sku": "string (required)",
  "manufacturer": "string (required)",
  "quantity": "number (required, 0-100)"
}
```

#### PATCH /v1/product/:productId
Partially update product (requires authentication & ownership).

**Headers:**
- `Authorization: Basic <credentials>`

**Request Body:** (all fields optional)
```json
{
  "name": "string",
  "description": "string", 
  "sku": "string",
  "manufacturer": "string",
  "quantity": "number (0-100)"
}
```

#### DELETE /v1/product/:productId
Delete product (requires authentication & ownership).

**Headers:**
- `Authorization: Basic <credentials>`

**Response:** `204 No Content`

---

### Image Management

#### GET /v1/product/:productId/image
Get all images for a product (requires authentication).

**Headers:**
- `Authorization: Basic <credentials>`

**Response:** `200 OK`
```json
[
  {
    "image_id": "uuid",
    "product_id": "uuid", 
    "file_name": "image.jpg",
    "date_created": "2025-07-27T10:00:00Z",
    "s3_bucket_path": "s3://bucket/path/image.jpg"
  }
]
```

#### GET /v1/product/:productId/image/:imageId
Get specific image details (requires authentication).

**Headers:**
- `Authorization: Basic <credentials>`

**Response:** `200 OK`
```json
{
  "image_id": "uuid",
  "product_id": "uuid",
  "file_name": "image.jpg", 
  "date_created": "2025-07-27T10:00:00Z",
  "s3_bucket_path": "s3://bucket/path/image.jpg"
}
```

#### POST /v1/product/:productId/image
Upload image for product (requires authentication & ownership).

**Headers:**
- `Authorization: Basic <credentials>`
- `Content-Type: multipart/form-data`

**Request Body:**
- `image`: File (required, image file)

**Response:** `201 Created`
```json
{
  "image_id": "uuid",
  "product_id": "uuid",
  "file_name": "uploaded_image.jpg",
  "date_created": "2025-07-27T10:00:00Z", 
  "s3_bucket_path": "s3://bucket/path/uploaded_image.jpg"
}
```

**Example:**
```bash
curl -X POST http://localhost:3000/v1/product/{productId}/image \
  -H "Authorization: Basic <credentials>" \
  -F "image=@/path/to/image.jpg"
```

#### DELETE /v1/product/:productId/image/:imageId
Delete image (requires authentication & ownership).

**Headers:**
- `Authorization: Basic <credentials>`

**Response:** `204 No Content`

---

## Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `BAD_REQUEST` | Invalid request data |
| 401 | `UNAUTHORIZED` | Authentication required |
| 403 | `FORBIDDEN` | Access denied |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource already exists |
| 422 | `VALIDATION_ERROR` | Data validation failed |
| 500 | `INTERNAL_ERROR` | Server error |

## Rate Limiting
- 100 requests per minute per IP
- 1000 requests per hour per authenticated user

## File Upload Limits
- Maximum file size: 10MB
- Supported formats: JPEG, PNG, GIF
- Maximum 10 images per product
