class Party < ApplicationRecord
  NORMS = {
    'democratic'  => :democratic,
    'wri'         => :write_in,
    '[i]'         => :independent,
    'write - in'  => :write_in,
    'l'           => :libertarian,
    '(ind)'       => :independent,
    'republican'  => :republican,
    'reform'      => :reform,
    'i'           => :independent,
    'lib' => :libertarian,
    'lbt' => :libertarian,
    'd'   => :democratic,
    'r'   => :republican,
    'ind' => :independent,
    'dem' => :democratic,
    'rep' => :republican,
    'independent' => :independent,
    'demorat'     => :democratic,
    'write-ins'   => :write_in,
    'demcorat'    => :democratic,
    'libertarian' => :libertarian,
  }.freeze
end
