require 'rest-client'
require 'json'

username=0
password=0
project=0
login_ticket=0
project_ticket=0
widgets=['company_0','company_1','company_2','company_3','company_4','company_5','company_6','company_7','company_8','company_9','company_10','company_11']
base_url = "http://bim360field.autodesk.com/"

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0, allow_overlapping: false do |job|
  leaders = Hash.new({value: 0})
  companies = Hash.new({title: 0, open: 0, ready: 0, complete: 0, closed: 0, total: 0})

begin
  File.open(File.expand_path("../login", __FILE__ ), "r") do |rf|
      username = rf.readline.chomp
      password = rf.readline.chomp
      project = rf.readline.chomp
  end
rescue
  send_event('debug', {text: $!})
end

  stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/login", :params => {:username => username, :password => password}))
  login_ticket = stream["ticket"]
  stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/projects", :params => {:ticket => ticket}))
  stream.each do |projects|
    projects["name"] == project ? project_ticket = projects["project_id"] :
  end

  send_event('debug', {text: project_ticket})

  widgets.each do |e|
    o = rand(100)
    r = rand(20)
    c = rand(20)
    f = rand(100)
    companies[e.to_sym] = {title: e, open: o, ready: r, complete: c, closed: f, total: (o + r + c + f) }
    value = (f*100) / (o + r + c + f )
    leaders[e] = {label: e, value: "#{value}%"}
  end

  companies_array = companies.sort_by { |k, v| v[:open] }.reverse!

  12.times do |i|
    send_event(widgets[i], {title: companies_array[i][0], open: companies_array[i][1][:open], ready: companies_array[i][1][:ready], complete: companies_array[i][1][:complete], closed: companies_array[i][1][:closed] })
  end
  send_event('leaderboard', { items: leaders.values })
end
