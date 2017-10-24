class County < ApplicationRecord
  has_many :precincts
  has_many :census_tracts

  def self.n(name)
    find_by(name: name)
  end

  def self.l(name)
    where('lower(name) = ?', [name.downcase]).first
  end
end
