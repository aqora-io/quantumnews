class AddStoryText < ActiveRecord::Migration[7.1]
  def up
    add_column :stories, :story_cache, :text
  end

  def down
    remove_column :stories, :story_cache
  end
end
