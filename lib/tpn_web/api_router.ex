defmodule TpnWeb.ApiRouter do
  use TpnWeb, :router

  import TpnWeb.UserAuth
  import TpnWeb.AdminAuth

  # API pipelines
  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :require_authenticated_dash_user
  end

  pipeline :api_admin do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :require_authenticated_admin
  end

  pipeline :api_no_auth do
    plug :accepts, ["json"]
    # For public API endpoints that don't require authentication
  end

  # Public API routes (no authentication required)
  scope "/api/v1", TpnWeb.Api.V1 do
    pipe_through :api_no_auth

    post "/login", TpnWeb.Login.LoginController, :create
    delete "/logout", TpnWeb.TpnWeb.Login.LoginController, :delete

    # Add public API routes here
    # Example: get "/health", HealthController, :check
  end

  # Authenticated user API routes
  scope "/api/v1", TpnWeb.Api.V1 do
    pipe_through :api_auth

    # Dashboard and general user endpoints
    get "/dashboard", DashboardController, :index

    # Health Networks API
    get "/health_networks", HealthNetworksController, :networks
    get "/health_networks/wards", HealthNetworksController, :wards
    get "/health_networks/rooms", HealthNetworksController, :rooms
    get "/health_networks/beds", HealthNetworksController, :beds
    get "/health_networks/hospitals", HealthNetworksController, :hospitals
    get "/health_networks/mrn", HealthNetworksController, :mrn

    # Template Products API
    get "/template_products/formularies", TemplateProductController, :formularies

    # Osmolarity API
    get "/osmolarity/limit", OsmolarityController, :get_limit
    get "/osmolarity/validate", OsmolarityController, :validate
    get "/osmolarity/validate_with_override", OsmolarityController, :validate_with_override
    post "/osmolarity/calculate_total_osmoles", OsmolarityController, :calculate_total_osmoles
    post "/osmolarity/calculate_osmolarity", OsmolarityController, :calculate_osmolarity

    # Resources API endpoints
    resources "/wards", WardsController, except: [:new, :edit]
    resources "/rooms", RoomsController, except: [:new, :edit]
    resources "/beds", BedsController, except: [:new, :edit]
    resources "/unit_types", UnitTypesController, except: [:new, :edit]
    resources "/units", UnitsController, except: [:new, :edit]
    resources "/vascular_accesses", VascularAccessesController, except: [:new, :edit]
    resources "/solution_types", SolutionTypesController, except: [:new, :edit]
    resources "/classes", ClassesController, except: [:new, :edit]
    resources "/filling_methods", FillingMethodsController, except: [:new, :edit]
    resources "/patient_types", PatientTypesController, except: [:new, :edit]
    resources "/osmolarities", OsmolaritiesController, except: [:new, :edit]
    resources "/ingredients", IngredientsController, except: [:new, :edit]
    resources "/formularies", FormulariesController, except: [:new, :edit]
    resources "/templates", TemplateController, except: [:new, :edit]
    resources "/template_products", TemplateProductController, except: [:new, :edit]

    # Patient and Hospital API
    resources "/patients", PatientController, except: [:new, :edit]
    get "/patients/:patient_id/admissions", AdmissionsController, :index
    post "/patients/:patient_id/admissions", AdmissionsController, :create
    get "/patients/:patient_id/orders", OrdersController, :index
    post "/patients/:patient_id/orders", OrdersController, :create

    # Settings API
    get "/settings", SettingsController, :show
    put "/settings", SettingsController, :update
  end

  # Admin API routes
  scope "/api/v1/admin", TpnWeb.Api.V1.Admin do
    pipe_through :api_admin

    # Admin-only API endpoints
    resources "/roles", RolesController, except: [:new, :edit]
    get "/roles/:id/rights", RolesController, :rights
    put "/roles/:id/rights", RolesController, :update_rights

    resources "/accounts", AccountsController, except: [:new, :edit]
    put "/accounts/:id/password", AccountsController, :update_password

    resources "/lhn", LocalHealthNetworksController, except: [:new, :edit]
    resources "/facilities", FacilitiesController, except: [:new, :edit]
    resources "/campuses", CampusesController, except: [:new, :edit]
  end

  # API v2 scope for future versions
  scope "/api/v2", TpnWeb.Api.V2 do
    pipe_through :api_auth

    # Future API v2 endpoints will go here
  end
end
