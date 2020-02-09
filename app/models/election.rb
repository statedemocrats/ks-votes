class Election < ApplicationRecord
  belongs_to :election_file

  has_many :results

  def offices
    offices = {}
    results.includes(:office).find_each do |result|
      offices[result.office.name] = true
    end
    offices.keys
  end
end
