class ElectionCode < VoterFileBase
  has_many :voters

  def year
    name.match(/((19|20)\d\d)$/)[1]
  end
end
