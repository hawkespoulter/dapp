# A running list of bugs, jotted down from the bug button in the navbar.
class CreateBugReports < ActiveRecord::Migration[7.1]
  def change
    create_table :bug_reports do |t|
      t.text :note, null: false
      t.string :page
      t.datetime :fixed_at
      t.timestamps
    end
  end
end
