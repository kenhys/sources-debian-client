# frozen_string_literal: true

require_relative '../../command'
require 'grn_mini'

module Debsources
  module Watch
    module Client
      module Commands
        class Init
          class Database < Debsources::Watch::Client::Command
            def initialize(options)
              @options = options
            end

            def execute(input: $stdin, output: $stdout)
              GrnMini::create_or_open("data/debian-watch.db")
              pkgs = GrnMini::Hash.new("Pkgs")
              pkgs.setup_columns(name: "",
                                 version: "",
                                 watch_missing: 0,
                                 watch_content: "",
                                 watch_version: 0,
                                 watch_hosting: "",
                                 released_at: Time.new,
                                 created_at: Time.new,
                                 updated_at: Time.new
                                )
            end
          end
        end
      end
    end
  end
end