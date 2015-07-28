#Reads the file "Login" and gets the corresponding login and project tickets
#OUT: login[login_ticket, project_ticket]
#Adds debug code to a debug console textbox
def get_tickets (debug = "nil")
  begin
    File.open(File.expand_path("../login", __FILE__ ), "r") do |rf|
        login[0] = rf.readline.chomp
        login[1] = rf.readline.chomp
        login[2] = rf.readline.chomp
    end
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Open File Error" << e.message << " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Open File Done -> "})
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
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Unable to get Tickets" << e.message << " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Got Tickets ->"})
end

#Performs the REST call to the BIM 360 Field Database to recieve companies.
#IN: Tickets from get_tickets
#OUT: Hash of company hashes sorted by company_id,
#Adds debug code to a debug console textbox
def get_companies (tickets, debug = "nil")
  begin
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/companies/", :params => {:ticket => tickets[0], :project_id => tickets[1]}))
    stream.each do |c|
      companies[:companies][c["company_id"]] = {name: c["name"], open: 0, ready: 0, complete: 0, closed: 0, total: 0}
    end
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Companies Download Error" << e.message << " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Companies Download Done -> "})
  end
end

def get_issues (tickets, debug = "nil")
  begin
    stream = JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues/", timeout: nil, headers: {:params => {:ticket => tickets[0], :project_id => tickets[1]}}))
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Issues Download Error" << e.message << " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Issues Download Done -> "})
  end
end

def issues_company_type_sort (companies, stream, debug = "nil")
  begin
    stream.each do |i|
#      if i["issue_type"].include? "Punch List"
        case i["status"]
          when "Open"
            companies[i[1]["company_id"]][:open] += 1
            companies[0][:open] += 1
          when "Work Completed"
            companies[i[1]["company_id"]][:complete] += 1
            companies[0][:complete] += 1
          when "Ready to Inspect"
            companies[i[1]["company_id"]][:ready] += 1
            companies[0][:ready] += 1
          when "Closed"
            companies[i[1]["company_id"]][:closed] += 1
            companies[0][:closed] += 1
        end
        companies[i[1]["company_id"]][:total] += 1
        companies[0][:total] += 1
#      end
    end
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Count Issues Error" << e.message << " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Count Issues Done -> " })
  end
end

def find_leaders (companies, leaderboard_widget, debug = "nil")
  begin
    companies.each do |k, v|
      if v[:total] != 0
        value = (v[:closed] * 100) / v[:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
    send_event(leaderboard_widget, { items: leaders.values })
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Find Leaders Error" << e.message <<  " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Find Leaders Done -> " })
  end
end

def send_issues (companies, debug = "nil")
  begin
    companies_array = companies.sort_by { |k, v| v[:open] }.reverse!
    12.times do |i|
      send_event(widgets[i], {title: companies_array[i][1][:name], open: companies_array[i][1][:open], ready: companies_array[i][1][:ready], complete: companies_array[i][1][:complete], closed: companies_array[i][1][:closed] })
    end
    send_event(total_widget, {title: "All Issues Total", open: total[:open], closed: total[:closed], ready: total[:ready], complete: total[:complete]})
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Display Error" << e.message << " -> "})
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Display Done -> " })
  end
end
