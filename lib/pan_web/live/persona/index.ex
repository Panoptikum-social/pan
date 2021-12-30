defmodule PanWeb.Live.Persona.Index do
  use Surface.LiveView

  def render(assigns) do
    # TODO: Search for ID, Persona, Pid}

    ~F"""
    <h1>Personas</h1>

    <p>Use the searchbox to find personas by name, id or pid.<br/><br/></p>

    <table id="datatable" class="table table-striped table-condensed table-bordered">
    </table>

    <script>
      $(function() {
        $('#datatable').DataTable({
          serverSide: true,
          ajax: {url: '<%= persona_frontend_path(@conn, :datatable) %>'},
          order: [ 1, 'asc' ],
          columns: [
            { data: 'id' },
            { data: 'name' },
            { data: 'pid' }
          ]
        })
      })
    </script>
    """
  end
end
