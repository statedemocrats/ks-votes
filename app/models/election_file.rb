class ElectionFile < ApplicationRecord
  def year
    return "2020" if file_year == "2018"
    return "2020" if file_year == "2016"
    file_year
  end

  def file_year
    # rely on naming conventions
    name.match(/^(\d\d\d\d)/)[1]
  end
end
