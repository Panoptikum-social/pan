defmodule PanWeb.ViewHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Link
  alias PanWeb.Endpoint

  def icon(name), do: icon(name, class: "")

  def icon(name, class: class) do
    class = if class == "", do: "h-6 w-6 inline", else: class

    icon_string =
      case name do
        "cog-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065
                  2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572
                  1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0
                  00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07
                  2.572-1.065z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          """

        "rss-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 5c7.18 0 13 5.82 13 13M6 11a7 7 0 017 7m-6 0a1 1 0 11-2 0 1 1 0 012 0z" />
          </svg>
          """

        "search-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          """

        "map-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
                class="#{class}"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021
                    18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
          </svg>
          """

        "beaker-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
                class="#{class}"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0
                     00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782
                     0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
          </svg>
          """

        "question-mark-circle-heroicons-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
                class="#{class}"
                viewBox="0 0 20 20"
                fill="currentColor">
            <path fill-rule="evenodd"
                  d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-3a1 1 0 00-.867.5 1 1 0 11-1.731-1A3 3 0 0113 8a3.001 3.001 0 01-2 2.83V11a1 1 0
                      11-2 0v-1a1 1 0 011-1 1 1 0 100-2zm0 8a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
          </svg>
          """

        "newspaper-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
                class="#{class}"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7
                      16h6M7 8h6v4H7V8z" />
          </svg>
          """

        "user-secret-lineawesome-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M13.06 4c-.87 0-1.64.45-2.19 1.03-.54.58-.93 1.31-1.28 2.1a27.35 27.35 0 00-1.25 3.8c-1.08.32-2 .72-2.75 1.2C4.73
                     12.68 4 13.46 4 14.5c0 .9.55 1.63 1.25 2.16.6.44 1.32.81 2.19 1.12.05.23.12.47.22.69-.85.48-2.18 1.4-3.47 3.16l-.6.84.85.6
                     3.28 2.24L6.38 28h19.25l-1.35-2.69 3.28-2.25.85-.6-.6-.84a11.03 11.03 0 00-3.47-3.15c.1-.22.17-.46.22-.69.87-.3 1.6-.68
                     2.19-1.12.7-.53 1.25-1.25 1.25-2.16 0-1.04-.73-1.82-1.6-2.38-.74-.47-1.66-.87-2.74-1.18-.38-1.3-.8-2.67-1.32-3.88A7.11
                     7.11 0 0021.1 5a3 3 0 00-2.15-1c-.58 0-1.03.16-1.5.28-.48.12-.96.22-1.44.22-.96 0-1.77-.5-2.94-.5zm0 2c.21 0 1.44.5
                     2.94.5.75 0 1.42-.15 1.94-.28.52-.13.91-.22 1-.22.23 0 .4.07.68.38.29.3.63.84.91 1.5.54 1.24.96 2.93 1.4 4.5 0 0
                     .06-.05-.09.03-.25.13-.77.3-1.4.4-1.27.2-3 .19-4.44.19-1.43 0-3.16-.02-4.44-.22a4.83 4.83 0
                     01-1.4-.4c-.08-.05-.1-.03-.13-.04v-.03-.03l.03-.03c.08-.13.12-.29.13-.44v-.03c.36-1.33.76-2.73
                     1.25-3.84.29-.67.6-1.21.9-1.53.3-.32.5-.41.72-.41zM8.2 13.1c.22.46.62.84 1.03 1.06.6.32 1.3.47 2.06.59 1.5.23 3.27.25
                     4.72.25 1.44 0 3.2 0 4.72-.22a6.18 6.18 0 002.06-.6c.41-.22.81-.61 1.03-1.09a7.5 7.5 0 011.5.7c.58.37.69.64.69.71 0
                     .06-.05.25-.47.56a7.3 7.3 0 01-2.06.97A25.9 25.9 0 0116 17a25.9 25.9 0 01-7.47-.97 7.3 7.3 0
                     01-2.06-.97c-.42-.31-.47-.5-.47-.56 0-.07.08-.32.66-.69a8 8 0 011.53-.72zm2.6 5.46c.32.06.64.15 1 .19.12.88.8 1.65 1.9
                     1.72.84.05 1.79-.35 1.87-1.47h.88c.08 1.12 1.03 1.52 1.87 1.47a1.99 1.99 0 001.9-1.72c.36-.04.68-.13 1-.19l-.09.63a9.05
                     9.05 0 01-1.96 4.22C18.23 24.46 17.14 25 16 25a4.26 4.26 0 01-3.16-1.63 9.13 9.13 0 01-1.96-4.18zM23 20c.37.22 1.35.86
                     2.47 2.1l-3.03 2.09-.72.47.37.78.29.56h-3.16c.52-.35 1-.8 1.44-1.28a10.66 10.66 0 002.25-4.66L23 20zm-14.03.03l.12.06a10.83
                     10.83 0 002.25 4.6c.45.5.98.95 1.54 1.31H9.62l.29-.56.37-.78-.72-.47-3.03-2.1a11.23 11.23 0 012.44-2.06z"/>
          </svg>
          """

        "user-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
                class="#{class}"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          """

        "adjustments-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0
                  110-4m0 4v2m0-6V4" />
          </svg>
          """

        "user-circle-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0
                    0118 0z" />
          </svg>
          """

        "inbox-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414
                     2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
          </svg>
          """

        "podcast-lineawesome-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               viewBox="0 0 32 32"
               fill="currentColor">
            <path d="M16.5 3C10.159 3 5 8.159 5 14.5c0 4.649 2.779 8.654 6.758 10.465a30.38 30.38 0 01-.238-2.39C8.813 20.897 7 17.91 7
                     14.5 7 9.262 11.262 5 16.5 5S26 9.262 26 14.5c0 3.411-1.813 6.398-4.52 8.074a30.427 30.427 0 01-.238 2.39C25.222
                     23.155 28 19.15 28 14.5 28 8.159 22.841 3 16.5 3zm0 4C12.364 7 9 10.364 9 14.5a7.487 7.487 0 002.795 5.832 4.098
                     4.098 0 011.143-1.65A5.488 5.488 0 0111 14.5c0-3.032 2.468-5.5 5.5-5.5s5.5 2.468 5.5 5.5a5.488 5.488 0 01-1.938
                     4.182 4.075 4.075 0 011.143 1.65A7.487 7.487 0 0024 14.5c0-4.136-3.364-7.5-7.5-7.5zm0 4c-1.93 0-3.5 1.57-3.5
                     3.5s1.57 3.5 3.5 3.5 3.5-1.57 3.5-3.5-1.57-3.5-3.5-3.5zm0 2c.827 0 1.5.673 1.5 1.5s-.673 1.5-1.5
                     1.5-1.5-.673-1.5-1.5.673-1.5 1.5-1.5zm0 6c-3.159 0-3.5 2.076-3.5 2.969 0 1.644.537 4.95.83 6.205.13.55.648 1.826
                     2.67 1.826s2.54-1.276 2.67-1.826c.293-1.253.83-4.561.83-6.205 0-.893-.341-2.969-3.5-2.969zm0 2c1.5 0 1.5.56
                     1.5.969 0 1.335-.47 4.43-.777 5.748-.025.105-.067.283-.723.283-.656 0-.698-.177-.723-.281-.306-1.314-.777-4.414-.777-5.75
                     0-.41 0-.969 1.5-.969z"/>
          </svg>
          """

        "pencil-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
          </svg>
          """

        "login-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
          </svg>
          """

        "logout-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          """

        "gift-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0
                     002 2h10a2 2 0 002-2v-7" />
          </svg>
          """

        "file-audio-lineawesome" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               viewBox="0 0 32 32"
               class="#{class}"
               fill="currentColor">
            <path d="M6 3v26h20V3zm2 2h16v22H8zm8 4.72v6.47a2.95 2.95 0 00-1-.19c-1.64 0-3 1.36-3 3s1.36 3 3 3 3-1.36
                     3-3v-6.72l2.75.69.5-1.94zM15 18c.56 0 1 .44 1 1s-.44 1-1 1-1-.44-1-1 .44-1 1-1z"/>
          </svg>
          """

        "briefcase-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2
                     2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
          </svg>
          """

        "user-astronaut-lineawesome-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M16 4c-5 0-9 4-9 9-.3 0-.6.2-.8.4-.2.3-.3.6-.1.9l1 3c.1.4.5.7.9.7h.5c.2.29.4.56.63.82.3.48.67.91 1.08 1.3A9 9 0 007
                     27h2a7.03 7.03 0 012.92-5.7c.93.44 1.97.7 3.08.7h2c1.1 0 2.12-.25 3.04-.69A7.04 7.04 0 0123 27h2a8.87 8.87 0
                     00-3.24-6.85c.42-.4.8-.84 1.11-1.33.23-.26.44-.53.63-.82h.5c.4 0 .8-.3.9-.7l1-3c.2-.3.1-.6-.1-.9-.2-.2-.5-.4-.8-.4
                     0-5-4-9-9-9zm0 2a6.94 6.94 0 016.9 5.88A4.95 4.95 0 0019 10h-6c-1.6 0-3 .74-3.9 1.88A6.94 6.94 0 0116 6zm-3 6h6c1.7 0 3 1.3 3
                     3 0 .72-.15 1.39-.4 2H17a1 1 0 000 2h2.62a7 7 0 01-8.86-1.34A5.01 5.01 0 0110 15c0-1.7 1.3-3 3-3z"/>
          </svg>
          """

        "folder-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
          """

        "folder-open-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 19a2 2 0 01-2-2V7a2 2 0 012-2h4l2 2h4a2 2 0 012 2v1M5 19h14a2 2 0 002-2v-5a2 2 0 00-2-2H9a2 2 0 00-2
                     2v5a2 2 0 01-2 2z" />
          </svg>
          """

        "calendar-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          """

        "photograph-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0
                     00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          """

        "headphones-lineawesome-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M16 5C9.94 5 5 9.94 5 16v8c0 1.64 1.36 3 3 3h3v-9H7v-2c0-4.98 4.02-9 9-9s9 4.02 9 9v2h-4v9h3c1.64 0 3-1.36
                     3-3v-8c0-6.06-4.94-11-11-11zM7 20h2v5H8c-.57 0-1-.43-1-1zm16 0h2v4c0 .57-.43 1-1 1h-1z"/>
          </svg>
          """

        "stopwatch-lineawesome-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M13 4v2h6V4zm3 3C9.94 7 5 11.94 5 18s4.94 11 11 11a11.02 11.02 0 008-18.56l1.72-1.72-1.44-1.44-1.81 1.81A10.97 10.97 0 0016
                     7zm0 2c4.98 0 9 4.02 9 9s-4.02 9-9 9-9-4.02-9-9 4.02-9 9-9zm-1 2v5.28a1.98 1.98 0 000 3.44V21h2v-1.28a1.98 1.98 0
                     000-3.44V11z"/>
          </svg>
          """

        "female-lineawesome-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M16 2a3.98 3.98 0 00-2.75 6.88c-.24.17-.46.35-.66.56A6.54 6.54 0 0011 12.8h.03l-2 10L8.78
                     24H13v6h2v-6h2v6h2v-6h4.22l-.25-1.19-2-10A6.65 6.65 0 0019.4 9.5c-.21-.23-.44-.44-.7-.63A3.95 3.95 0 0016 2zm0
                     2c1.12 0 2 .88 2 2s-.88 2-2 2-2-.88-2-2 .88-2 2-2zm0 6c.83 0 1.42.32 1.94.88.51.55.92 1.38 1.1 2.3L20.77
                     22h-9.56l1.75-8.81H13c.18-1 .56-1.84 1.06-2.38.5-.53 1.1-.81 1.94-.81z"/>
          </svg>
          """

        "thumb-up-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0
                     00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0
                     012-2h2.5" />
          </svg>
          """

        "heart-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0
                     00-6.364 0z" />
          </svg>
          """

        "annotation-heroicons-outline" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="none"
               viewBox="0 0 24 24"
               stroke="currentColor">
            <path stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
          </svg>
          """

        "indent-lineawesome-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M 3 7 L 3 9 L 29 9 L 29 7 Z M 3 11 L 3 13 L 22 13 L 22 11 Z M 29 11 L 24 16 L 29 21 Z M 3 15 L 3 17 L 22 17 L 22 15 Z M 3 19 L 3 21 L 22 21
                     L 22 19 Z M 3 23 L 3 25 L 29 25 L 29 23 Z"/>
          </svg>
          """

        "sort-amount-down-alt-solid" ->
          """
          <svg xmlns="http://www.w3.org/2000/svg"
               class="#{class}"
               fill="currentColor"
               viewBox="0 0 32 32">
            <path d="M 4 5 L 4 7 L 6 7 L 6 5 Z M 21 5 L 21 23.6875 L 18.40625 21.09375 L 17 22.5 L 21.28125 26.8125 L 22 27.5 L 22.71875 26.8125 L 27 22.5 L
                     25.59375 21.09375 L 23 23.6875 L 23 5 Z M 4 9 L 4 11 L 8 11 L 8 9 Z M 4 13 L 4 15 L 10 15 L 10 13 Z M 4 17 L 4 19 L 12 19 L 12 17 Z M 4 21 L 4
                     23 L 14 23 L 14 21 Z M 4 25 L 4 27 L 16 27 L 16 25 Z"/>
          </svg>
          """

          "sort-amount-down-solid" ->
            """
            <svg xmlns="http://www.w3.org/2000/svg"
                 class="#{class}"
                 fill="currentColor"
                 viewBox="0 0 32 32">
              <path d="M 4 5 L 4 7 L 16 7 L 16 5 Z M 21 5 L 21 23.6875 L 18.40625 21.09375 L 17 22.5 L 21.28125 26.8125 L 22 27.5 L 22.71875 26.8125 L 27 22.5
                       L 25.59375 21.09375 L 23 23.6875 L 23 5 Z M 4 9 L 4 11 L 14 11 L 14 9 Z M 4 13 L 4 15 L 12 15 L 12 13 Z M 4 17 L 4 19 L 10 19 L 10 17 Z
                       M 4 21 L 4 23 L 8 23 L 8 21 Z M 4 25 L 4 27 L 6 27 L 6 25 Z"/>
            </svg>
            """

        _ ->
          raise "An icon is missing: " <> name
      end

    raw(icon_string)
  end

  def nav_icon(name) do
    icon(name, class: "h-6 w-6 inline")
  end

  def btn_cycle(counter) do
    Enum.at(
      [
        "btn-default",
        "btn-gray-lighter",
        "btn-gray",
        "btn-gray-darker",
        "btn-success",
        "btn-info",
        "btn-primary",
        "btn-blue-jeans",
        "btn-lavender",
        "btn-pink-rose",
        "btn-danger",
        "btn-bittersweet",
        "btn-warning"
      ],
      rem(counter, 13)
    )
  end

  def color_class_cycle(counter) do
    Enum.at(
      [
        "bg-white hover:bg-gray-lighter text-gray-darker border-gray",
        "bg-gray-lighter hover:bg-gray-lightest text-gray-darker border-gray",
        "bg-gray hover:bg-gray-light text-white",
        "bg-gray-darker hover:bg-gray-darker text-white",
        "bg-success hover:bg-success-light text-white",
        "bg-mint hover:bg-mint-light text-white",
        "bg-info hover:bg-info-light text-white",
        "bg-blue-jeans hover:bg-blue-jeans-light text-white",
        "bg-lavender hover:bg-lavender-light text-white",
        "bg-pink-rose hover:bg-pink-rose-light text-white",
        "bg-danger hover:bg-danger-light text-white",
        "bg-bittersweet hover:bg-bittersweet-light text-white",
        "bg-warning hover:bg-warning-light text-white"
      ],
      rem(counter, 13)
    )
  end

  def truncate_string(string, len) do
    length = len - 3

    if string do
      if String.length(string) > length do
        String.slice(string, 0, length) <> "..."
      else
        string
      end
    else
      ""
    end
  end

  def ej(nil), do: ""
  def ej(string), do: javascript_escape(string)

  def my_safe_to_string({:safe, string}), do: safe_to_string({:safe, string})
  def my_safe_to_string(string), do: string

  def datatable_actions(record_id, path) do
    [
      "<nobr>",
      link("Show",
        to: path.(Endpoint, :show, record_id),
        class: "btn btn-default btn-xs"
      ),
      " ",
      link("Edit",
        to: path.(Endpoint, :edit, record_id),
        class: "btn btn-warning btn-xs"
      ),
      " ",
      link("Delete",
        to: path.(Endpoint, :delete, record_id),
        method: :delete,
        data: [confirm: "Are you sure?"],
        class: "btn btn-danger btn-xs"
      ),
      "</nobr>"
    ]
    |> Enum.map(&my_safe_to_string/1)
    |> Enum.join()
  end
end
