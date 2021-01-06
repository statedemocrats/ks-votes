namespace :shapefiles do
  include TaskHelpers

  # manually downloaded .zip files from https://www.census.gov/geo/partnerships/pvs/partnership19v2/st20_ks.html
  desc 'download 2019 VTD files and create geojson'
  task vtd2019: :environment do
    # iterate over each county and
    #  * unzip
    #  * convert to .geojson
    shp_pattern = "PVS_19_v2"
    Dir.chdir("public/2020-vtd-verification") do
      County.all.each do |county|
        puts "Processing #{county.name}"
        zip_file = "partnership_shapefiles_19v2_20#{county.fips}.zip"
        dirname = county.name.downcase
        system_try("mkdir -p #{dirname}")
        system_try("unzip -o #{zip_file}")
        system_try("mv -f #{shp_pattern}*20#{county.fips}* #{dirname}")
        Dir.chdir(dirname) do
          system_try("shp2geojson #{shp_pattern}_vtd_20#{county.fips}.shp")
          system_try("mv #{shp_pattern}_vtd_20#{county.fips}.geojson ../../#{shp_pattern}/#{county.fips}-#{dirname}-#{shp_pattern}.geojson")
        end
      end
    end
  end
end
