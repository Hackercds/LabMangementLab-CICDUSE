# Postman API 测试集合

## 使用方式

1. 打开 Postman → Import → 选择 `实验室管理系统.postman_collection.json`
2. 设置环境变量:
   - `baseUrl`: `http://localhost:8081/api`
   - `token`: (自动填充，首次留空)

3. 先执行"认证模块 → 用户登录"，响应中的 token 会自动写入环境变量
4. 其他需要认证的接口都已配置 `Authorization: Bearer {{token}}`

## JWT 鉴权说明

系统使用 `Authorization: Bearer <token>` 头鉴权，无 HMAC/API Key 等额外签名机制。
