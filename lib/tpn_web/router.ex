defmodule TpnWeb.Router do
  use TpnWeb, :router
  use Plug.ErrorHandler

  import TpnWeb.UserAuth
  import TpnWeb.AdminAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TpnWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_without_csrf_for_delete do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  pipeline :administrator_layout do
    plug :fetch_current_administrator
    plug :put_layout, html: {TpnWeb.Layouts, :administrator}
  end

  pipeline :authenticated_administrator do
    plug :require_authenticated_administrator
  end

  pipeline :no_layout do
    plug :put_root_layout, false
    plug :put_layout, false
  end

  pipeline :aes_pieline do
    plug TpnWeb.Plugs.AesPlug
  end

  pipeline :decrypt do
    plug TpnWeb.Plugs.DecryptPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TpnWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/logout", Login.LoginController, :delete

    get "/login", Login.LoginController, :index
    post "/login", Login.LoginController, :create
  end

  scope "/", TpnWeb do
    pipe_through [:browser, :require_authenticated_dash_user]

    get "/dashboard", DashBoardController, :index

    pipe_through [:no_layout, :aes_pieline, :decrypt]
    get "/dash", DashBoardController, :dash
    get "/dash/key", DashBoardController, :key
    get "/health_networks", HealthNetworks.HealthNetworksController, :networks
    get "/health_networks/wards", HealthNetworks.HealthNetworksController, :wards
    get "/health_networks/rooms", HealthNetworks.HealthNetworksController, :rooms
    get "/health_networks/beds", HealthNetworks.HealthNetworksController, :beds
    get "/health_networks/hospitals", HealthNetworks.HealthNetworksController, :hospitals
    get "/health_networks/mrn", HealthNetworks.HealthNetworksController, :mrn
    get "/template_products/formularies", TemplateProductController, :formularies

    resources "/wards", WardsController, except: [:show, :delete]
    resources "/rooms", RoomsController, except: [:show, :delete]
    resources "/beds", BedsController, except: [:show, :delete]
    resources "/unit_types", UnitTypesController, except: [:show, :delete]
    resources "/units", UnitsController, except: [:show, :delete]
    resources "/vascular_accesses", VascularAccessesController, except: [:show, :delete]
    resources "/solution_types", SolutionTypesController, except: [:show, :delete]
    resources "/classes", ClassesController, except: [:show, :delete]
    resources "/filling_methods", FillingMethodsController, except: [:show, :delete]
    resources "/patient_types", PatientTypesController, except: [:show, :delete]
    resources "/osmolarities", OsmolaritiesController, except: [:show, :delete]
    resources "/ingredients", IngredientsController, except: [:show, :delete]
    resources "/formularies", FormulariesController, except: [:show, :delete]
    resources "/templates", TemplateController, except: [:show, :delete]
    resources "/template_products", TemplateProductController, except: [:show, :delete]
    resources "/patients/dashboard", Hospital.PatientDashboardController, except: [:delete]
    get "/patients/admissions/search", Hospital.AdmissionsController, :search
    post "/patients/admissions", Hospital.AdmissionsController, :create
    post "/patients/admissions/discharge", Hospital.AdmissionsController, :discharge

    get "/patients/:id/admissions", Hospital.AdmissionsController, :index
    get "/patients/:id/admissions/new", Hospital.AdmissionsController, :new

    get "/settings", SettingsController, :index
    post "/settings", SettingsController, :update

    # admin
    pipe_through :require_authenticated_admin
    resources "/roles", RolesController, except: [:show, :delete]
    get "/roles/:id/rights", RolesController, :rights
    post "/role/context/rights", RolesController, :update_rights
    resources "/accounts", AccountsController, except: [:show, :delete]
    get "/accounts/:id/change_password", AccountsController, :change_password
    put "/accounts/:id/change_password", AccountsController, :update_password
    resources "/lhn", Networks.LocalHealthNetworksController, except: [:show, :delete]
    resources "/facilities", FacilitiesController, except: [:show, :delete]
    resources "/campuses", CampusesController, except: [:show, :delete]
  end

  scope "/", TpnWeb do
    pipe_through [:browser_without_csrf_for_delete, :require_authenticated_dash_user]

    delete "/wards/:id", WardsController, :delete
    delete "/rooms/:id", RoomsController, :delete
    delete "/beds/:id", BedsController, :delete
    delete "/unit_types/:id", UnitTypesController, :delete
    delete "/units/:id", UnitsController, :delete
    delete "/vascular_accesses/:id", VascularAccessesController, :delete
    delete "/solution_types/:id", SolutionTypesController, :delete
    delete "/classes/:id", ClassesController, :delete
    delete "/filling_methods/:id", FillingMethodsController, :delete
    delete "/patient_types/:id", PatientTypesController, :delete
    delete "/osmolarities/:id", OsmolaritiesController, :delete
    delete "/ingredients/:id", IngredientsController, :delete
    delete "/formularies/:id", FormulariesController, :delete
    delete "/templates/:id", TemplateController, :delete
    delete "/template_products/:id", TemplateProductController, :delete

    # admin
    pipe_through :require_authenticated_admin
    delete "/roles/:id", RolesController, :delete
    delete "/accounts/:id", AccountsController, :delete
    delete "/lhn/:id", Networks.LocalHealthNetworksController, :delete
    delete "/facilities/:id", FacilitiesController, :delete
    delete "/campuses/:id", CampusesController, :delete
  end

  scope "/administrator", TpnWeb.Administrator do
    pipe_through :browser

    get "/login", Login.LoginController, :index
    post "/login", Login.LoginController, :create
    delete "/logout", Login.LoginController, :delete

    pipe_through [:administrator_layout]
    get "/dashboard", DashBoardController, :index
    pipe_through :no_layout
    get "/dash", DashBoardController, :dash
    get "/users", UsersController, :index
    get "/users/new", UsersController, :new
    post "/users/new", UsersController, :create
    get "/users/:id/edit", UsersController, :edit
    put "/users/:id/edit", UsersController, :update
    get "/users/:id/change_password", UsersController, :change_password
    put "/users/:id/change_password", UsersController, :update_password
    delete "/users/:id/delete", UsersController, :delete

    # Contexts
    resources "/contexts", ContextsController, except: [:show, :delete]
    # Roles
    resources "/roles", RolesController, except: [:show, :delete]
    # Accounts
    resources "/accounts", AccountsController, except: [:show, :delete]
    get "/accounts/:id/change_password", AccountsController, :change_password
    put "/accounts/:id/change_password", AccountsController, :update_password
  end

  scope "/administrator", TpnWeb.Administrator do
    pipe_through [:browser_without_csrf_for_delete, :authenticated_administrator]
    delete "/contexts/:id", ContextsController, :delete
    delete "/roles/:id", RolesController, :delete
    delete "/accounts/:id", AccountsController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", TpnWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:tpn, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TpnWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: _reason, stack: _stack}) do
    if kind in [:error, :throw] do
      conn
      |> put_resp_header("hx-redirect", "/login")
      |> send_resp(200, "")
    end
  end
end
