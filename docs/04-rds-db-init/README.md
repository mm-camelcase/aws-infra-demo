## **Database Setup**

Once the **RDS instance** is provisioned, follow these steps to set up the required databases and users.

### **1. Setup Port-forwarding to RDS**

see [Database Access](https://github.com/mm-camelcase/aws-infra-demo?tab=readme-ov-file#database-access)

### **2. Connect to PostgreSQL**

Use `psql` to connect to the PostgreSQL instance:

```bash
psql -h localhost -U [username] -d postgres
```

**Note:** password will be set in Secret Manager by RDS module.


### **3. Create Databases and Users**

#### ToDo Service Database

Create the database and user, then grant permissions:

```sql
-- Create the database
CREATE DATABASE todo_service_db;

-- Create the user with a secure password
CREATE USER todo_user WITH PASSWORD 'secure-password';

-- Grant database access
GRANT CONNECT ON DATABASE todo_service_db TO todo_user;
```

Switch to the newly created database:

```sql
\c todo_service_db;
```

Grant schema and table privileges:

```sql
GRANT USAGE, CREATE ON SCHEMA public TO todo_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO todo_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO todo_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO todo_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO todo_user;
```

#### Keycloak Database

Create the database and user, then grant access:

```sql
-- Create the database
CREATE DATABASE keycloak_db;

-- Create the user with a secure password
CREATE USER keycloak_user WITH PASSWORD 'keycloak-password';

-- Grant database access
GRANT CONNECT ON DATABASE keycloak_db TO keycloak_user;
```

Switch to the **Keycloak database**:

```sql
\c keycloak_db;
```

Grant schema and table privileges:

```sql
GRANT USAGE, CREATE ON SCHEMA public TO keycloak_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO keycloak_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO keycloak_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO keycloak_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO keycloak_user;
```