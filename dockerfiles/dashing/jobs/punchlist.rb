require 'rest-client'
require 'json'

username=0
password=0
project=0
debug_console = ""

widgets=['company_0','company_1','company_2','company_3','company_4','company_5','company_6','company_7','company_8','company_9','company_10','company_11']

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0, allow_overlapping: false do |job|
  login_ticket=0
  project_ticket=0
  leaders = Hash.new({value: 0})
  companies = Hash.new({name: 0, open: 0, complete: 0, ready: 0, closed: 0, total: 0})
  total = {:name => 0, :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0}

  send_event('debug', {text: debug_console << "StartCycle -> "})

  begin
    File.open(File.expand_path("../login", __FILE__ ), "r") do |rf|
        username = rf.readline.chomp
        password = rf.readline.chomp
        project = rf.readline.chomp
    end
  rescue Exception => e
    send_event('debug', {text: debug_console << "Open File Error" << e.message << " -> "})
  else
    send_event('debug', {text: debug_console << "Open File Done -> "})
  end

  begin
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/login", :params => {:username => username, :password => password}))
    login_ticket = stream["ticket"]
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/projects", :params => {:ticket => login_ticket}))
    stream.each do |p|
      if p["name"] == project
        project_ticket = p["project_id"]
      end
    end
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/companies/", :params => {:ticket => login_ticket, :project_id => project_ticket}))
    stream.each do |c|
      companies[c["company_id"]] = {name: c["name"], open: 0, ready: 0, complete: 0, closed: 0, total: 0}
    end
  rescue Exception => e
    send_event('debug', {text: debug_console << "Companies Download Error" << e.message << " -> "})
  else
    send_event('debug', {text: debug_console << "Companies Download Done -> "})
  end

  begin
    stream = JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues/", timeout: nil, headers: {:params => {:ticket => login_ticket, :project_id => project_ticket}}))
  rescue Exception => e
    send_event('debug', {text: debug_console << "Issues Download Error" << e.message << " -> "})
  else
    send_event('debug', {text: debug_console << "Issues Download Done -> "})
  end

  begin
    stream.each do |i|
      if i["issue_type"].include? "Punch List"
        case i["status"]
          when "Open"
            companies[i["company_id"]][:open] += 1
            total[:open] += 1
          when "Work Completed"
            companies[i["company_id"]][:complete] += 1
            total[:complete] += 1
          when "Ready to Inspect"
            companies[i["company_id"]][:ready] += 1
            total[:ready] += 1
          when "Closed"
            companies[i["company_id"]][:closed] += 1
            total[:closed] += 1
        end
        companies[i["company_id"]][:total] += 1
        total[:total] += 1
      end
    end
  rescue Exception => e
    send_event('debug', {text: debug_console << "Count Issues Error" << e.message << " -> "})
  else
    send_event('debug', {text: debug_console << "Count Issues Done -> " })
  end

  begin
    companies.each do |k, v|
      if v[:total] != 0
	      send_event('debug', {text: debug_console << (v[:closed]*100/v[:total]).to_s << " "})
        value = (v[:closed] * 100) / v[:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
  rescue Exception => e
    send_event('debug', {text: debug_console << "Find Leaders Error" << e.message <<  " -> "})
  else
    send_event('debug', {text: debug_console << "Find Leaders Done -> " })
  end

  begin
    companies_array = companies.sort_by { |k, v| v[:open] }.reverse!
    12.times do |i|
      send_event(widgets[i], {title: companies_array[i][1][:name], open: companies_array[i][1][:open], ready: companies_array[i][1][:ready], complete: companies_array[i][1][:complete], closed: companies_array[i][1][:closed] })
    end
    send_event('total', {title: "Punchlist Issues Total", open: total[:open], closed: total[:closed], ready: total[:ready], complete: total[:complete]})
    send_event('leaderboard', { items: leaders.values })
  rescue Exception => e
    send_event('debug', {text: debug_console << "Display Error" << e.message << " -> "})
  else
      send_event('debug', {text: debug_console << "Display Done -> " })
  end

end
