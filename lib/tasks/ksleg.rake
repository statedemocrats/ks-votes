namespace :ksleg do
  desc 'build JSON of districts by party'
  task district_parties: :environment do
    member_api = 'http://www.kslegislature.org/li/api/v7/rev-1/members/'
    r = fetch_uri_content(member_api)
    ksleg = {house: {}, senate: {}}
    r['house_members'].each do |m|
      uri = member_api + m['KPID'] + '/'
      resp = fetch_uri_content(uri)
      party = resp['PARTY']
      district = resp['DISTRICT']
      ksleg[:house][district] = { party: party, uri: uri }
    end
    r['senate_members'].each do |m|
      uri = member_api + m['KPID'] + '/'
      resp = fetch_uri_content(uri)
      party = resp['PARTY']
      district = resp['DISTRICT']
      ksleg[:senate][district] = { party: party, uri: uri }
    end
    File.write('public/ksleg.json', ksleg.to_json)
  end

  def fetch_uri_content(uri)
    sleep(3)
    puts uri
    r = HTTParty.get(uri)
    r['content']
  end
end
