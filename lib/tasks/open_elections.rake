require 'open_elections'

namespace :openelections do

  desc 'load files for year'
  task load_files: :environment do
    year = ENV['YEAR']
    oe_dir = ENV['OE_DIR'] or raise 'OE_DIR required'

    year.split(/\ *,\ */).each do |y|
      dir = oe_dir + y + '/'
      puts "Loading files for #{y} from #{dir}"
      if !Dir.exists?(dir)
        raise "Can't find dir #{dir}"
      end

      Dir.glob(dir + '*precinct.csv').sort.each do |file|
        next if file.match(/(president|general)__precinct/) # 2012 e.g.
        puts "#{file}"
        if OpenElections.clean?
          OpenElections.clean_csv_file(file)
        else
          OpenElections.load_csv_file(file)
        end
      end
    end
  end

  desc 'load single file'
  task load_file: :environment do
    if OpenElections.clean?
      OpenElections.clean_csv_file(ENV['FILE'])
    else
      OpenElections.load_csv_file(ENV['FILE'])
    end
  end
end
