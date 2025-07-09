# **Keycloak Setup Guide**

This document provides step-by-step instructions for setting up **Keycloak**, importing a realm, creating users, and testing authentication with APIs.

---

## **1. Importing a Realm from a File**
Keycloak allows importing realm configurations from a file. Follow these steps:

1. **Create a New Realm** (even if an error appears, it will still work):
   - Go to **Keycloak Admin Console**.
   - Create a realm with the name **`demo-realm`**.
   - Choose the option to **import a realm file** and choose the attached `realm-export.json`

2. **Verify Realm Import**:
   - After import, check the **Clients** and **Roles** (Clients --> `static-app` --> Roles) sections to ensure they were created correctly.

---

## **2. Creating Users & Assigning Roles**
1. **Create a new user** in the `demo-realm`.
2. Assign the **api-viewer** role to the user.
   - Role-Mapping --> "Assign Role" dropdown --> `api-viewer` --> Assign
3. Set a password for authentication.

---

## **3. Keycloak URLs**
Once Keycloak is set up, you can retrieve the **OpenID Connect (OIDC) discovery document** at:

🔗 **OIDC Configuration URL**  

https://auth.camelcase.club/realms/demo-realm/.well-known/openid-configuration

This URL contains all necessary endpoints for authentication and token retrieval.

---

## **4. API Authentication Tests**

### **4.1 Obtain an Access Token**
To get an **OAuth 2.0 access token**, use the following **`curl`** command:

```bash
curl -X POST "https://auth.camelcase.club/realms/demo-realm/protocol/openid-connect/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "client_id=static-app" \
     -d "client_secret=**********************" \
     -d "grant_type=password" \
     -d "username=mark@camelcase.email" \
     -d "password=************" \
     -o token.json
```

**Notes:**

- This request retrieves an access token from Keycloak.
- The token is stored in a file named token.json.

### 4.2 Calling a Protected API

Once you have an access token, you can call a **protected API endpoint**:

```bash
curl -X GET "http://localhost:8080/api/todo" \
     -H "Authorization: Bearer $(jq -r '.access_token' token.json)" \
     -H "accept: */*"
```

**Explanation:**

- The access token is extracted from ``token.json`` using ``jq``.
- The token is passed in the **Authorization header**.
- This request should return user data if authentication is successful.
