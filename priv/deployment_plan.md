
# Azure Deployment Plan for TPN Pharmacy Application

Based on analyzing your Phoenix/Elixir application, here's a comprehensive deployment plan for Azure with integrated printing solutions.

## 📋 Architecture Overview

### Current Stack
- **Framework**: Phoenix 1.7.18 (Elixir 1.18.4)
- **Database**: PostgreSQL
- **Web Server**: Bandit
- **Frontend**: Phoenix LiveView, Alpine.js, TailwindCSS
- **Cache**: Nebulex

---

## 🏗️ Azure Infrastructure Design

### **Option 1: Azure App Service (Recommended for Quick Start)**

#### Components:
1. **Azure App Service for Containers**
   - Linux-based container hosting
   - Built-in load balancing
   - Auto-scaling capabilities
   - Custom domain & SSL support

2. **Azure Database for PostgreSQL - Flexible Server**
   - Managed PostgreSQL service
   - Automated backups
   - High availability options
   - Point-in-time restore

3. **Azure Storage Account**
   - Static assets (CSS, JS, images)
   - File uploads
   - Backup storage

4. **Azure Virtual Network**
   - Private networking
   - Service endpoints
   - Network security groups

5. **Azure Key Vault**
   - Secrets management
   - Database credentials
   - API keys

### **Option 2: Azure Kubernetes Service (AKS) - For Enterprise Scale**

#### Components:
1. **AKS Cluster**
   - Container orchestration
   - Advanced scaling
   - Rolling updates
   - Multi-region deployment

2. **Azure Database for PostgreSQL**
   - Same as Option 1

3. **Azure Container Registry (ACR)**
   - Private Docker registry
   - Image scanning
   - Geo-replication

4. **Azure Application Gateway**
   - WAF protection
   - SSL termination
   - Path-based routing

---

## 🖨️ Remote Printing Solution

### **Option A: CUPS (Common UNIX Printing System)**

#### Architecture:
```
TPN App Server → CUPS Print Server (Azure VM) → Network Printers
```

#### Setup:
1. **Azure VM for CUPS Server**
   - Ubuntu 22.04 LTS
   - Size: Standard_B2s (2 vCPUs, 4GB RAM)
   - Install CUPS and configure as print server

2. **Configuration**:
   ```bash
   # Install CUPS
   sudo apt-get update
   sudo apt-get install cups cups-client
   
   # Configure CUPS for remote access
   sudo cupsctl --remote-any
   sudo systemctl restart cups
   ```

3. **Integration with Phoenix App**:
   - Use Elixir's `System.cmd/3` to send print jobs
   - Create print queue management module
   - Implement job tracking

4. **Pros**:
   - ✅ Free and open-source
   - ✅ Full control over configuration
   - ✅ Lightweight
   - ✅ Direct IPP protocol support

5. **Cons**:
   - ❌ Manual management required
   - ❌ Limited reporting/analytics
   - ❌ No built-in user authentication

### **Option B: PaperCut (Recommended for Healthcare)**

#### Architecture:
```
TPN App Server → PaperCut Application Server → PaperCut Print Deploy → Network Printers
```

#### Setup:
1. **Azure VM for PaperCut Server**
   - Windows Server 2022 or Ubuntu
   - Size: Standard_D4s_v3 (4 vCPUs, 16GB RAM)
   - Install PaperCut MF or NG

2. **Components**:
   - **PaperCut Application Server**: Central management
   - **PaperCut Print Deploy**: Client-side print queue deployment
   - **PaperCut Mobility Print**: Mobile/web printing

3. **Integration with Phoenix App**:
   - Use PaperCut's REST API
   - Implement Elixir HTTP client for API calls
   - Track print jobs, costs, and user quotas

4. **API Integration Example**:
   ```elixir
   defmodule Tpn.Printing.PaperCut do
     @api_base "https://papercut-server:9192/api"
     @auth_token System.get_env("PAPERCUT_API_TOKEN")
     
     def submit_print_job(user_id, document_path, printer_name) do
       HTTPoison.post(
         "#{@api_base}/print/submit",
         Jason.encode!(%{
           user: user_id,
           document: document_path,
           printer: printer_name
         }),
         [{"Authorization", "Bearer #{@auth_token}"}]
       )
     end
   end
   ```

5. **Pros**:
   - ✅ Enterprise-grade features
   - ✅ Comprehensive reporting & analytics
   - ✅ User authentication & quotas
   - ✅ HIPAA compliance features
   - ✅ Mobile printing support
   - ✅ Print job tracking & auditing
   - ✅ Cost allocation per department

6. **Cons**:
   - ❌ Licensing costs (~$1,000-5,000/year depending on users)
   - ❌ More complex setup

### **Recommended Choice: PaperCut**
For a healthcare/pharmacy application, PaperCut is recommended due to:
- Audit trail requirements
- User accountability
- Cost tracking per department/patient
- HIPAA compliance features

---

## 🚀 Deployment Steps

### **Phase 1: Infrastructure Setup (Week 1)**

#### 1. Create Azure Resources
```bash
# Login to Azure
az login

# Create Resource Group
az group create --name tpn-prod-rg --location eastus

# Create PostgreSQL Database
az postgres flexible-server create \
  --name tpn-db-prod \
  --resource-group tpn-prod-rg \
  --location eastus \
  --admin-user tpnadmin \
  --admin-password <secure-password> \
  --sku-name Standard_D2s_v3 \
  --tier GeneralPurpose \
  --version 14 \
  --storage-size 128

# Create App Service Plan
az appservice plan create \
  --name tpn-app-plan \
  --resource-group tpn-prod-rg \
  --is-linux \
  --sku P1V3

# Create Web App
az webapp create \
  --name tpn-app-prod \
  --resource-group tpn-prod-rg \
  --plan tpn-app-plan \
  --deployment-container-image-name <your-registry>/tpn:latest
```

#### 2. Create Virtual Network
```bash
# Create VNet
az network vnet create \
  --name tpn-vnet \
  --resource-group tpn-prod-rg \
  --address-prefix 10.0.0.0/16 \
  --subnet-name app-subnet \
  --subnet-prefix 10.0.1.0/24

# Create subnet for database
az network vnet subnet create \
  --name db-subnet \
  --resource-group tpn-prod-rg \
  --vnet-name tpn-vnet \
  --address-prefix 10.0.2.0/24

# Create subnet for print server
az network vnet subnet create \
  --name print-subnet \
  --resource-group tpn-prod-rg \
  --vnet-name tpn-vnet \
  --address-prefix 10.0.3.0/24
```

### **Phase 2: Application Containerization (Week 1)**

#### 1. Create Dockerfile
```dockerfile
# Dockerfile
FROM elixir:1.18.4-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git nodejs npm

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application files
COPY config config
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile
RUN mix release

# Prepare release image
FROM alpine:3.18 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=build /app/_build/prod/rel/tpn ./

ENV HOME=/app
ENV MIX_ENV=prod

CMD ["bin/tpn", "start"]
```

#### 2. Build and Push Container
```bash
# Build image
docker build -t tpn:latest .

# Tag for Azure Container Registry
docker tag tpn:latest <your-acr>.azurecr.io/tpn:latest

# Login to ACR
az acr login --name <your-acr>

# Push image
docker push <your-acr>.azurecr.io/tpn:latest
```

### **Phase 3: Database Migration (Week 2)**

#### 1. Backup Current Database
```bash
pg_dump -h localhost -U postgres tpn_prod > tpn_backup.sql
```

#### 2. Restore to Azure PostgreSQL
```bash
# Get connection string
az postgres flexible-server show-connection-string \
  --server-name tpn-db-prod

# Restore database
psql "host=tpn-db-prod.postgres.database.azure.com port=5432 dbname=postgres user=tpnadmin password=<password> sslmode=require" < tpn_backup.sql
```

#### 3. Configure Database Firewall
```bash
# Allow Azure services
az postgres flexible-server firewall-rule create \
  --resource-group tpn-prod-rg \
  --name tpn-db-prod \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### **Phase 4: Print Server Setup (Week 2)**

#### For PaperCut:

1. **Create VM**
```bash
az vm create \
  --resource-group tpn-prod-rg \
  --name tpn-print-server \
  --image UbuntuLTS \
  --size Standard_D4s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name tpn-vnet \
  --subnet print-subnet
```

2. **Install PaperCut**
```bash
# SSH into VM
ssh azureuser@<vm-ip>

# Download PaperCut
wget https://www.papercut.com/products/ng/download/

# Install (follow PaperCut documentation)
sudo ./pc-install.sh
```

3. **Configure Network Security Group**
```bash
# Allow PaperCut ports
az network nsg rule create \
  --resource-group tpn-prod-rg \
  --nsg-name tpn-print-server-nsg \
  --name AllowPaperCut \
  --priority 100 \
  --destination-port-ranges 9191 9192 9193 \
  --protocol Tcp
```

### **Phase 5: Application Configuration (Week 3)**

#### 1. Configure Environment Variables
```bash
az webapp config appsettings set \
  --resource-group tpn-prod-rg \
  --name tpn-app-prod \
  --settings \
    DATABASE_URL="ecto://tpnadmin:<password>@tpn-db-prod.postgres.database.azure.com/tpn_prod?ssl=true" \
    SECRET_KEY_BASE="<generate-with-mix-phx.gen.secret>" \
    PHX_HOST="tpn-app-prod.azurewebsites.net" \
    POOL_SIZE="10" \
    PAPERCUT_API_URL="http://10.0.3.4:9192/api" \
    PAPERCUT_API_TOKEN="<your-token>"
```

#### 2. Update Production Config
```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      """

  config :tpn, Tpn.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true,
    ssl_opts: [
      verify: :verify_peer,
      cacertfile: "/etc/ssl/certs/ca-certificates.crt"
    ]

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :tpn, TpnWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # PaperCut configuration
  config :tpn, :papercut,
    api_url: System.get_env("PAPERCUT_API_URL"),
    api_token: System.get_env("PAPERCUT_API_TOKEN")
end
```

### **Phase 6: CI/CD Pipeline (Week 3)**

#### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Login to Azure Container Registry
      uses: azure/docker-login@v1
      with:
        login-server: ${{ secrets.ACR_LOGIN_SERVER }}
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}
    
    - name: Build and push Docker image
      run: |
        docker build -t ${{ secrets.ACR_LOGIN_SERVER }}/tpn:${{ github.sha }} .
        docker push ${{ secrets.ACR_LOGIN_SERVER }}/tpn:${{ github.sha }}
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: tpn-app-prod
        images: ${{ secrets.ACR_LOGIN_SERVER }}/tpn:${{ github.sha }}
    
    - name: Run Database Migrations
      run: |
        az webapp ssh --resource-group tpn-prod-rg --name tpn-app-prod \
          --command "bin/tpn eval 'Tpn.Release.migrate()'"
```

---

## 💰 Cost Estimates (Monthly)

### Option 1: App Service
| Service | Tier | Cost |
|---------|------|------|
| App Service Plan (P1V3) | 2 vCPU, 8GB RAM | ~$146 |
| PostgreSQL Flexible Server | Standard_D2s_v3 | ~$140 |
| Storage Account | Standard LRS | ~$20 |
| Virtual Network | Standard | ~$10 |
| PaperCut VM (D4s_v3) | 4 vCPU, 16GB RAM | ~$175 |
| PaperCut License | Per user | ~$100-400 |
| **Total** | | **~$591-891/month** |

### Option 2: AKS (Enterprise)
| Service | Tier | Cost |
|---------|------|------|
| AKS Cluster | 3 nodes (D2s_v3) | ~$210 |
| PostgreSQL Flexible Server | Standard_D4s_v3 | ~$280 |
| Application Gateway | Standard_v2 | ~$250 |
| Container Registry | Standard | ~$20 |
| PaperCut VM | Same as above | ~$175 |
| **Total** | | **~$935-1,235/month** |

---

## 🔒 Security Considerations

1. **Network Security**
   - Use Private Endpoints for database
   - Configure NSG rules restrictively
   - Enable Azure DDoS Protection

2. **Application Security**
   - Store secrets in Azure Key Vault
   - Enable HTTPS only
   - Implement WAF rules

3. **Database Security**
   - Enable SSL/TLS connections
   - Use Azure AD authentication
   - Enable audit logging

4. **Compliance (HIPAA)**
   - Enable Azure Security Center
   - Configure diagnostic logging
   - Implement data encryption at rest

---

## 📊 Monitoring & Logging

```elixir
# Add to mix.exs
{:new_relic_agent, "~> 1.27"},
{:logger_json, "~> 5.1"}

# config/prod.exs
config :logger,
  backends: [LoggerJSON]

config :new_relic_agent,
  app_name: "TPN Pharmacy",
  license_key: System.get_env("NEW_RELIC_LICENSE_KEY")
```

### Azure Monitor Integration
- Application Insights for APM
- Log Analytics for centralized logging
- Alerts for critical errors
- Performance metrics dashboard

---

## 🎯 Deployment Checklist

- [ ] Azure subscription created
- [ ] Resource group provisioned
- [ ] PostgreSQL database created
- [ ] Database migrated and tested
- [ ] Docker image built and pushed
- [ ] App Service configured
- [ ] Environment variables set
- [ ] SSL certificate configured
- [ ] Custom domain configured
- [ ] Print server VM created
- [ ] PaperCut installed and configured
- [ ] Network printers added to PaperCut
- [ ] API integration tested
- [ ] CI/CD pipeline configured
- [ ] Monitoring and alerts set up
- [ ] Backup strategy implemented
- [ ] Security review completed
- [ ] Load testing performed
- [ ] Documentation updated

---

This plan provides a production-ready deployment strategy with enterprise-grade printing capabilities suitable for a healthcare pharmacy application. Would you like me to elaborate on any specific section or create implementation scripts for any phase?
