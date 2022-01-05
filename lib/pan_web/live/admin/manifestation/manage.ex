defmodule PanWeb.Live.Manifestation.Manage do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.Endpoint
  alias PanWeb.Surface.{Icon, LinkButton}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  # get users and personas

  def render(assigns) do
    ~F"""
    <p class="text-center">
      <a class="btn btn-primary" onclick="toggle_manifestation()">
        <Icon name="user-heroicons-outline" />
        <Icon name="arrow-sm-left-heroicons-outline" />
        <Icon name="arrow-sm-right-heroicons-outline" />
        <Icon name="user-heroicons-outline" /> &nbsp;
        Toggle Manifestation
      </a>
    </p>

    <div class="row">
      <div class="col-md-6">
        <h1 class="text-3xl">Users</h1>

        <table id="users" class="table table-striped table-condensed table-bordered">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Username</th>
              <th>Email</th>
              <th>Podcaster</th>

              <th></th>
            </tr>
          </thead>
          <tbody>
            {#for user <- @users}
              <tr>
                <td>{user.id}</td>
                <td>{user.name}</td>
                <td>{user.username}</td>
                <td>{user.email}</td>
                <td>{user.podcaster}</td>

                <td><nobr>
                  <LinkButton title="Show"
                              to={databrowser_path(Endpoint, :show, "user", user.id)}
                              class="text-link" />
                  <LinkButton title="Edit"
                              to={databrowser_path(Endpoint, :edit, "user", user.id)}
                              class="text-link" />
                  </nobr></td>
              </tr>
            {/for}
          </tbody>
        </table>


        <h4 class="text-">Manifestations</h4>

        <div id="userManifestations"></div>
      </div>

      <div class="col-md-6">
        <h2>Personas</h2>

        <table id="personas" class="table table-striped table-condensed table-bordered">
          <thead>
            <tr>
              <th>Id</th>
              <th>Pid</th>
              <th>Name</th>
              <th>Uri</th>
              <th>Email</th>

              <th></th>
            </tr>
          </thead>
          <tbody>
            {#for persona <- @personas}
                <tr>
                  <td>{persona.id}</td>
                  <td><nobr>{truncate_string(persona.pid, 13)}</nobr></td>
                  <td width="50%">{persona.name}</td>
                  <td>{persona.uri}</td>
                  <td>{persona.email}</td>

                  <td class="text-right">
                    <nobr>
                      <LinkButton title="Show"
                                  to={databrowser_path(Endpoint, :show, "persona", persona)}
                                  class="btn btn-default btn-xs" />
                      <LinkButton title="Edit"
                                  to={databrowser_path(Endpoint, :edit, "persona", persona)}
                                  class="btn btn-warning btn-xs" />
                    </nobr>
                  </td>
                </tr>
            {/for}
          </tbody>
        </table>


        <h4>Manifestations</h4>

        <div id="personaManifestations"></div>
      </div>
    </div>

    <script>
      $(function() {
        var usertable = $('#users').DataTable({select: "single"});

        usertable
          .on( 'select', function (e, dt, type, indexes) {
            var rowData = usertable.rows(indexes).data().toArray();
            get_manifestations_by_user(rowData[0][0])
          })

        var personatable = $('#personas').DataTable({select: "single"});

        personatable
          .on( 'select', function (e, dt, type, indexes) {
            var rowData = personatable.rows(indexes).data().toArray();
            get_manifestations_by_persona(rowData[0][0])
          })
      })


      function get_manifestations_by_user(user_id) {
        $.ajax({
          type: "GET",
          url: "<%= manifestation_url(@conn, :index) %>/" + user_id + '/get_by_user',
          headers: {"X-CSRF-TOKEN": "<%= get_csrf_token() %>" },
          success: function(data) {
            $('#userManifestations')[0].innerHTML = data
          }
        })
      }


      function get_manifestations_by_persona(persona_id) {
        $.ajax({
          type: "GET",
          url: "<%= manifestation_url(@conn, :index) %>/" + persona_id + '/get_by_persona',
          headers: {"X-CSRF-TOKEN": "<%= get_csrf_token() %>" },
          success: function(data) {
            $('#personaManifestations')[0].innerHTML = data
          }
        })
      }


      function toggle_manifestation() {
        var user_id = $('#users').DataTable()
                                .rows({ selected: true })
                                .data()
                                .toArray()[0][0]
        var persona_id =  $('#personas').DataTable()
                                        .rows({ selected: true })
                                        .data()
                                        .toArray()[0][0]
        $.ajax({
          type: "POST",
          url: "<%= manifestation_url(@conn, :toggle) %>",
          data: { user_id: user_id,
                  persona_id: persona_id},
          headers: {"X-CSRF-TOKEN": "<%= get_csrf_token() %>" },
          success: function(data) {
            get_manifestations_by_user(user_id)
            get_manifestations_by_persona(persona_id)
          }
        })
      }
    </script>
    """
  end
end
