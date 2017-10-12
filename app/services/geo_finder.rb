class GeoFinder
  def self.kansas2012_geosha
    # load all of Kansas into hash for easy lookup by sha
    @@kansas2012 ||= begin
      buf = {}
      CSV.foreach(File.join(Rails.root, 'db/kansas-2012-vtd-shas.csv'), headers: true) do |row|
        s = row['sha']
        v = row['vtd_2012']
        if buf[s]
          buf[s] = [buf[s]] if buf[s].is_a?(String)
          buf[s] << v
        else
          buf[s] = v
        end
      end
      buf
    end
  end

  def vtd_for(sha)
    self.class.kansas2012_geosha[sha]
  end
end
