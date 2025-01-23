defmodule TpnWeb.LayoutComponents.Administrator.Header do
  use Phoenix.Component

  import TpnWeb.CoreComponents

  def admin_header(assigns) do
    ~H"""
    <div class="flex h-16 shrink-0 items-center gap-x-4 px-4 sm:gap-x-6 sm:px-6 lg:px-8">
      <button type="button" class="-m-2.5 p-2.5 text-gray-700 lg:hidden">
        <span class="sr-only">Open sidebar</span>
        <svg
          class="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
          />
        </svg>
      </button>
      <!-- Separator -->
      <div class="divider divider-horizontal lg:hidden" aria-hidden="true" />
      <div class="flex flex-1 gap-x-4 self-stretch justify-end">
        <div class="flex items-center gap-x-4 lg:gap-x-6">
          <button type="button" class="-m-2.5 p-2.5">
            <span class="sr-only">View notifications</span> <.icon name="hero-bell" class="h-6 w-6" />
          </button>
          <!-- Separator -->
          <div class="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-300/10" aria-hidden="true" />
          <!-- Profile dropdown -->
          <div class="relative">
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="-m-1.5 flex items-center p-1.5 bg-none">
                Administrator <.icon name="hero-chevron-down" class="ml-2 h-4 w-4" />
              </div>
              
              <ul class="dropdown-content z-[1] menu p-2 shadow bg-base-200 rounded-box w-52">
                <li><a href="/profile" class="block px-3 py-1 text-sm leading-6">Profile</a></li>
                
                <li>
                  <.form
                    for={%{}}
                    method="delete"
                    action="/administrator/logout"
                    hx-delete="/administrator/logout"
                  >
                    <button class="block w-full bg-none border-none">
                      Sign Out
                    </button>
                  </.form>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
