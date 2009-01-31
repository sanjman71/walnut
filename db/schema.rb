# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "address_areas", :force => true do |t|
    t.integer "area_id"
    t.integer "address_id"
  end

  create_table "addresses", :force => true do |t|
    t.string "name"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
  end

  create_table "areas", :force => true do |t|
    t.integer "extent_id"
    t.string  "extent_type"
  end

  create_table "cities", :force => true do |t|
    t.string  "name"
    t.integer "state_id"
  end

  create_table "city_neighborhoods", :force => true do |t|
    t.integer "city_id"
    t.integer "neighborhood_id"
  end

  create_table "city_zips", :force => true do |t|
    t.integer "city_id"
    t.integer "zip_id"
  end

  create_table "neighborhoods", :force => true do |t|
    t.string  "name"
    t.integer "city_id"
    t.integer "state_id"
  end

  create_table "states", :force => true do |t|
    t.string "name"
    t.string "ab"
    t.string "country"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "zips", :force => true do |t|
    t.string  "name"
    t.integer "state_id"
  end

end
