class RenameSeasSectionsToSeasDomains < ActiveRecord::Migration[8.1]
  def change
    rename_table :seas_sections, :seas_domains
    rename_column :seas_questions, :seas_section_id, :seas_domain_id
    rename_column :seas_evaluations, :current_section_position, :current_domain_position
  end
end
