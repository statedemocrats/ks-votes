class Voter < VoterFileBase
  def name
    [name_first, name_middle, name_last].compact.join(' ')
  end
end
