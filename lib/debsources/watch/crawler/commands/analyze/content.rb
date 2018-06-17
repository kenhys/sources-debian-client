require_relative '../../command'

module Debsources
  module Watch
    module Crawler
      module Commands
        class Analyze
          class Content < Debsources::Watch::Crawler::Command
            def initialize(options)
              @options = options
            end

            def execute(input: $stdin, output: $stdout)
              GrnMini::create_or_open("data/debian-watch.db")
              @pkgs = GrnMini::Hash.new("Pkgs")
              pkglist = []
              @pkgs.each do |record|
                watch_content = parse_watch_original(record.watch_content)
                if watch_content.empty?
                  record.watch_version = 0
                  record.watch_missing = 1
                else
                  if watch_content =~ /version=(\d)/
                    record.watch_version = $1.to_i
                  else
                    record.watch_version = 1
                  end
                end
                record.watch_content = watch_content
                if watch_content =~ /(ftp|https?):\/\/(.+?)\//
                  matched = $2.strip
                  if matched.end_with?("sf.net") or matched.end_with?("sourceforge.net")
                    #p "sourceforge.net"
                    record.watch_hosting = "sourceforge.net"
                  else
                    record.watch_hosting = $2
                  end
                  #p "#{record._key} #{record.watch_version} #{$1}"
                end
              end
              generate_watch_version_pie_graph
              generate_watch_file_pie_graph
              generate_watch_host_top5_pie_graph
            end

            def parse_watch_original(original_content)
              content = ""
              if original_content
                original_content.split("\n").collect do |line|
                  line = line.strip
                  unless line.start_with?("#")
                    if line.end_with?('\\')
                      content << "#{line}"
                    else
                      content << "#{line}\n"
                    end
                  end
                end
              end
              content
            end

            def generate_watch_version_pie_graph
              @pkgs = GrnMini::Hash.new("Pkgs")
              dataset = @pkgs.select do |record|
                record.watch_missing == 0
              end
              groups = GrnMini::Util::group_with_sort(dataset, "watch_version")
              graph = Gruff::Pie.new(600)
              graph.title = "Grouping by debian/watch version"
              graph.title_font_size = 36

              groups.each do |record|
                unless record._key == 0
                  graph.data("version #{record._key} (#{record['_nsubrecs']})", [record["_nsubrecs"]])
                end
              end
              graph.zero_degree = -90
              graph.sort = false
              graph.show_values_as_labels = false
              graph.write("debian-watch-version-pie-graph.png")
            end

            def generate_watch_file_pie_graph
              @pkgs = GrnMini::Hash.new("Pkgs")
              groups = GrnMini::Util::group_with_sort(@pkgs, "watch_missing")
              graph = Gruff::Pie.new(600)
              graph.title = "How many packages\nsupports debian/watch?"
              graph.title_font_size = 36

              groups.each do |record|
                if record._key == 0
                  graph.data("watch file (#{record["_nsubrecs"]})", record["_nsubrecs"])
                else
                  graph.data("no watch file (#{record["_nsubrecs"]})", record["_nsubrecs"])
                end
              end
              graph.zero_degree = -90
              graph.sort = false
              graph.write("debian-watch-file-pie-graph.png")
            end

            def generate_watch_host_top5_pie_graph
              @pkgs = GrnMini::Hash.new("Pkgs")
              dataset = @pkgs.select do |record|
                record.watch_missing == 0
              end
              groups = GrnMini::Util::group_with_sort(dataset, "watch_hosting")
              graph = Gruff::Pie.new(600)
              graph.title = "upstream hosting graph"
              graph.title_font_size = 36

              other_data = 0
              total = 0
              groups.each_with_index do |record, index|
                total += record["_nsubrecs"]
                if index < 5
                  graph.data("#{record._key} (#{record['_nsubrecs']})", record["_nsubrecs"])
                else
                  other_data += record["_nsubrecs"]
                end
              end
              graph.data("other (#{other_data})", [other_data])
              graph.zero_degree = -90
              graph.sort = false
              graph.write("debian-watch-hosting-top5-pie-graph.png")
              p other_data
              p total
            end
          end
        end
      end
    end
  end
end
