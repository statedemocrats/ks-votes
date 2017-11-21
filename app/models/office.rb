class Office < ApplicationRecord
  belongs_to :election_file

  NORMS = {
    'president / vice president' => 'President',
    'president' => 'President',
    'kansas house of representatives' => 'Kansas House',
    'kansas senate' => 'Kansas Senate',
    'united states house of representatives' => 'US House',
    'u.s. house' => 'US House',
    'state senate' => 'Kansas Senate',
    'state house' => 'Kansas House',
    'u.s. senate' => 'US Senate',
    'united states senate' => 'US Senate',
    'united state senate' => 'US Senate',
    'comm of ins' => 'Commissioner of Insurance',
    'insurance commissioner' => 'Commissioner of Insurance',
    'state rep 112th dist' => 'Kansas House',
    'state house 005' => 'Kansas House',
    'state house 122' => 'Kansas House',
    '106' => 'Kansas House',
    '109' => 'Kansas House',
    'governor' => 'Governor',
    'u.s. house 1' => 'US House',
    'secretary of  state' => 'Secretary of State',
  }.freeze
end
