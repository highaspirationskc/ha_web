module ApplicationHelper
  def team_color_badge(team)
    content_tag(:span, class: "inline-flex items-center gap-1.5 px-2 text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800") do
      content_tag(:span, "", class: "h-2 w-2 rounded-full", style: "background-color: #{team.color_hex}") +
        team.name
    end
  end

  def team_color_swatch(team, size: "h-5 w-5")
    content_tag(:span, "", class: "#{size} inline-block rounded-full", style: "background-color: #{team.color_hex}")
  end
end
