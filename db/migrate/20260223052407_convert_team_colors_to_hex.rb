class ConvertTeamColorsToHex < ActiveRecord::Migration[8.0]
  def up
    color_map = {
      "blue" => "#3B82F6",
      "green" => "#22C55E",
      "yellow" => "#F59E0B",
      "red" => "#E11D48"
    }

    color_map.each do |old_color, hex_color|
      execute "UPDATE teams SET color = '#{hex_color}' WHERE color = '#{old_color}'"
    end
  end

  def down
    color_map = {
      "#3B82F6" => "blue",
      "#22C55E" => "green",
      "#F59E0B" => "yellow",
      "#E11D48" => "red"
    }

    color_map.each do |hex_color, old_color|
      execute "UPDATE teams SET color = '#{old_color}' WHERE color = '#{hex_color}'"
    end
  end
end
