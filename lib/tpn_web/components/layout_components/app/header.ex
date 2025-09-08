defmodule TpnWeb.LayoutComponents.App.TopBar do
  use Phoenix.Component

  import TpnWeb.CoreComponents

  attr :name, :string, default: "User"

  def app_header(assigns) do
    ~H"""
    <header class="bg-background sticky inset-x-0 top-0 isolate flex shrink-0 items-center gap-2 border-b z-10 px-4 h-14 w-full">
      <!-- Toggles the sidebar -->
      <button
        type="button"
        onclick="document.dispatchEvent(new CustomEvent('basecoat:sidebar'))"
        aria-label="Toggle sidebar"
        data-tooltip="Toggle sidebar"
        data-side="bottom"
        data-align="start"
        class="btn-sm-icon-ghost mr-auto size-7 -ml-1.5"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <rect width="18" height="18" x="3" y="3" rx="2"></rect>
          <path d="M9 3v18"></path>
        </svg>
      </button>
      <div class="flex flex-1 gap-x-4 self-stretch justify-end">
        <div class="flex items-center gap-x-4 lg:gap-x-6">
          <button type="button" class="btn-xs-icon-ghost">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="size-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0"
              />
            </svg>
          </button>
          <!-- Separator -->
          <div class="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-300/10" aria-hidden="true" />
          <!-- Profile dropdown -->
          <div id="profile-dropdown-menu" class="dropdown-menu">
            <button
              type="button"
              id="profile-dropdown-menu-trigger"
              aria-haspopup="menu"
              aria-controls="profile-dropdown-menu-menu"
              aria-expanded="false"
              class="btn-sm-outline flex items-center gap-4"
            >
              <span>{@name}</span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="text-muted-foreground ml-auto"
              >
                <path d="m7 15 5 5 5-5"></path>
                <path d="m7 9 5-5 5 5"></path>
              </svg>
            </button>
            <div
              id="profile-dropdown-menu-popover"
              data-popover
              data-side="bottom"
              data-align="end"
              data-offset="0"
              aria-hidden="true"
              class="min-w-32"
            >
              <div
                role="menu"
                id="profile-dropdown-menu-menu"
                aria-labelledby="profile-dropdown-menu-trigger"
              >
                <div role="menuitem">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                  Settings
                </div>
                <hr role="separator" />
                <div role="menuitem" hx-get="/logout" hx-trigger="click">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  >
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" x2="9" y1="12" y2="12" />
                  </svg>
                  Logout
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </header>
    """
  end
end
