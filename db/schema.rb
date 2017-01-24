# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131027234949) do

  create_table "basicdata", force: :cascade do |t|
    t.integer  "resource_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",         limit: 255
    t.text     "value",       limit: 65535
  end

  add_index "basicdata", ["resource_id"], name: "index_basicdata_on_resource_id", using: :btree

  create_table "feed_tags", force: :cascade do |t|
    t.integer "feed_id",     limit: 4
    t.integer "resource_id", limit: 4
  end

  add_index "feed_tags", ["feed_id"], name: "index_feed_tags_on_feed_id", using: :btree
  add_index "feed_tags", ["resource_id"], name: "index_feed_tags_on_resource_id", using: :btree

  create_table "feeds", force: :cascade do |t|
    t.string   "facebook_id",   limit: 255
    t.text     "data",          limit: 65535
    t.string   "data_type",     limit: 255
    t.string   "feed_type",     limit: 255
    t.datetime "created_time"
    t.datetime "updated_time"
    t.integer  "like_count",    limit: 4
    t.integer  "comment_count", limit: 4
    t.integer  "resource_id",   limit: 4
    t.integer  "from_id",       limit: 4
    t.integer  "to_id",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",     limit: 4
  end

  add_index "feeds", ["from_id"], name: "index_feeds_on_from_id", using: :btree
  add_index "feeds", ["parent_id"], name: "index_feeds_on_parent_id", using: :btree
  add_index "feeds", ["resource_id"], name: "index_feeds_on_resource_id", using: :btree
  add_index "feeds", ["to_id"], name: "index_feeds_on_to_id", using: :btree

  create_table "group_metrics", force: :cascade do |t|
    t.string   "metric_class",      limit: 255
    t.string   "name",              limit: 255
    t.text     "value",             limit: 65535
    t.integer  "resource_group_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "resource_id",       limit: 4
  end

  add_index "group_metrics", ["resource_group_id"], name: "index_group_metrics_on_resource_group_id", using: :btree
  add_index "group_metrics", ["resource_id"], name: "index_group_metrics_on_resource_id", using: :btree

  create_table "group_metrics_resources", id: false, force: :cascade do |t|
    t.integer "group_metric_id", limit: 4
    t.integer "resource_id",     limit: 4
  end

  add_index "group_metrics_resources", ["group_metric_id"], name: "index_group_metrics_resources_on_group_metric_id", using: :btree
  add_index "group_metrics_resources", ["resource_id", "group_metric_id"], name: "index_group_metrics_resources_on_resource_and_group_metric", unique: true, using: :btree
  add_index "group_metrics_resources", ["resource_id"], name: "index_group_metrics_resources_on_resource_id", using: :btree

  create_table "likes", force: :cascade do |t|
    t.integer  "resource_id", limit: 4
    t.integer  "feed_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "likes", ["feed_id"], name: "index_likes_on_feed_id", using: :btree
  add_index "likes", ["resource_id"], name: "index_likes_on_resource_id", using: :btree

  create_table "metrics", force: :cascade do |t|
    t.string   "metric_class", limit: 255
    t.string   "name",         limit: 255
    t.text     "value",        limit: 65535
    t.integer  "resource_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metrics", ["resource_id"], name: "index_metrics_on_resource_id", using: :btree

  create_table "resource_groups", force: :cascade do |t|
    t.string "group_name", limit: 255
  end

  create_table "resource_groups_resources", id: false, force: :cascade do |t|
    t.integer "resource_id",       limit: 4
    t.integer "resource_group_id", limit: 4
  end

  add_index "resource_groups_resources", ["resource_group_id"], name: "index_resource_groups_resources_on_resource_group_id", using: :btree
  add_index "resource_groups_resources", ["resource_id", "resource_group_id"], name: "index_resource_groups_resources_on_resource_and_resource_group", unique: true, using: :btree
  add_index "resource_groups_resources", ["resource_id"], name: "index_resource_groups_resources_on_resource_id", using: :btree

  create_table "resources", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "facebook_id", limit: 255
    t.datetime "last_synced"
    t.boolean  "active",      limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username",    limit: 255
    t.string   "link",        limit: 255
  end

  add_index "resources", ["facebook_id"], name: "index_resources_on_facebook_id", using: :btree
  add_index "resources", ["username"], name: "index_resources_on_username", unique: true, using: :btree

  create_table "tasks", force: :cascade do |t|
    t.integer  "resource_id",       limit: 4
    t.integer  "resource_group_id", limit: 4
    t.string   "type",              limit: 255
    t.decimal  "progress",                        precision: 3, scale: 2
    t.integer  "duration",          limit: 4
    t.text     "data",              limit: 65535
    t.boolean  "running",           limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "error",             limit: 1,                             default: false
  end

  add_index "tasks", ["resource_group_id"], name: "index_tasks_on_resource_group_id", using: :btree
  add_index "tasks", ["resource_id"], name: "index_tasks_on_resource_id", using: :btree

end
