namespace :precincts do
  namespace :report do
    desc 'by year'
    task by_year: :environment do
      rep = PrecinctReporter.all_by_year
      File.write('public/all-precincts-by-year.json', rep.to_json)
    end
  end
end
