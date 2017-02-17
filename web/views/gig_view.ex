defmodule Pan.GigView do
  use Pan.Web, :view

  def render("datatable.json", %{gigs: gigs,
                                 draw: draw,
                                 records_total: records_total,
                                 records_filtered: records_filtered}) do
    %{ draw: draw,
       recordsTotal: records_total,
       recordsFiltered: records_filtered,
       data: Enum.map(gigs, &gig_json/1) }
  end


  def gig_json(gig) do
    %{ id:              gig.id,
       persona_id:      gig.persona_id,
       persona_name:    gig.persona_name,
       episode_id:      gig.episode_id,
       episode_title:   gig.episode_title,
       from_in_s:       gig.from_in_s,
       until_in_s:      gig.until_in_s,
       comment:         gig.comment,
       publishing_date: gig.publishing_date,
       role:            gig.role,
       actions:         datatable_actions(gig.id, &gig_path/3) }
  end
end
