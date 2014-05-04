
require "minitest"
require "minitest/autorun"
require "active_record"
require "yaml"

config = YAML.load_file(File.expand_path("../database.yml", __FILE__))

ActiveRecord::Base.establish_connection(config["test"])

