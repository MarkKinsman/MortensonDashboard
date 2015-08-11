#Methods
module Field
  #Reads the file "Login" and gets the corresponding login and project tickets
  #OUT: login[login_ticket, project_ticket]
  def self.get_tickets ()
    login = {:username => 0 , :password => 0, :project => 0 }
    tickets = {:login => 0, :project => 0}
    File.open(File.expand_path("../login", __FILE__ ), "r") do |rf|
        login[:username] = rf.readline.chomp
        login[:password] = rf.readline.chomp
        login[:project] = rf.readline.chomp
    end

    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/login", :params => {:username => login[:username], :password => login[:password]}))

    tickets[:login] = stream["ticket"]
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/projects", :params => {:ticket => tickets[:login] }))

    stream.each do |p|
      if p["name"] == login[:project]
        tickets[:project] = p["project_id"]
      end
    end
    return tickets
  end

  #Performs the REST call to the BIM 360 Field Database to recieve companies.
  #IN: Tickets from get_tickets
  #OUT: Hash of company hashes sorted by company_id,
  def self.get_companies (tickets, floors=nil)
    companies = Hash.new({name: 0, :status => {open: 0, complete: 0, ready: 0, closed: 0, total: 0}, :locations => floors})
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/companies/", :params => {:ticket => tickets[:login], :project_id => tickets[:project]}))
    stream.each do |c|
      companies[c["company_id"]] = {name: c["name"], :status => {open: 0, complete: 0, ready: 0, closed: 0, total: 0}, :locations => floors}
    end
    return companies
  end

  #Performs the REST call to the BIM 360 Field Database to recieve areas.
  #IN: Tickets from get_tickets
  #OUT: Stream of JSON
  def self.get_areas (tickets, floors)
    areas = Hash.new({floor: 0})
    stream = JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/areas", timeout: nil, headers: {:params => {:ticket => tickets[:login], :project_id => tickets[:project]}}))
    stream.each do |c|
      floors.each do |k, v|
        if c["path"].include?(k) then areas[c["area_id"]] = {floor: k} end
      end
    end
    return areas
  end

  #Performs the REST call to the BIM 360 Field Database to recieve issues.
  #IN: Tickets from get_tickets
  #OUT: Stream of JSON
  def self.get_issues (tickets, limit=-1, offset=0)
      return JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues", timeout: nil, headers: {:params => {:ticket => tickets[:login], :project_id => tickets[:project], :limit => limit, :offset => offset}}))
  end

  #Performs the REST call to the BIM 360 Field Database to recieve number of issues.
  #IN: Tickets from get_tickets
  #OUT: Number of issues
  def self.get_issues_count (tickets)
      return JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues", timeout: nil, headers: {:params => {:ticket => tickets[:login], :project_id => tickets[:project], :count_only => "true"}}))["count"]
  end

  #Increments the company issue counts based on type of issues
  #IN: Companies Hash, JSON Stream of issues
  #OUT: Hash of company hashes sorted by company_id with counted issues
  def self.company_status_count (companies, issues, total=nil, areas = nil)
    issues.each do |i|
      if i["status"] != nil && i["company_id"] != nil then
        case i["status"]
          when "Open"
            companies[i["company_id"]][:status][:open] += 1
            send_event('all_debug', {text: areas[i["area_id"]].inspect << "  -------   " << companies[i][:locations].inspect << "    ---------     " << companies[i][:locations][areas[i["area_id"]][:floor]].inspect })
            sleep(10)
            if i["area_id"] != nil && areas != nil then
              if companies[i][:locations][areas[i["area_id"]][:floor] != nil
                then companies[i][:locations][areas[i["area_id"]][:floor] += 1
                else companies[i][:locations]['No Location'[:floor]
              end
            end
            if total != nil then total[:status][:open] += 1 end
          when "Work Completed"
            companies[i["company_id"]][:status][:complete] += 1
            if total != nil then total[:status][:complete] += 1 end
          when "Ready to Inspect"
            companies[i["company_id"]][:status][:ready] += 1
            if total != nil then total[:status][:ready] += 1 end
          when "Closed"
            companies[i["company_id"]][:status][:closed] += 1
            if total != nil then total[:status][:closed] += 1 end
        end
        companies[i["company_id"]][:status][:total] += 1
        if total != nil then total[:status][:total] += 1 end
      end
    end
    if total != nil then return companies, total else return companies end
  end

  #Orders companies based on open issues and dislpays the ones with the most in the widgets
  #IN: Companies hash, Array of text names for widgets
  def self.send_issue_counts (companies, widgets, total=nil)
    companies_array = companies.sort_by { |k, v| v[:status][:open] }.reverse!
    unless total == nil
      companies_array.unshift([0, total])
    end
    send_event("all_debug", {text: companies_array.inspect })
    widgets.length.times do |i|
      send_event(widgets[i], {title: companies_array[i][1][:name], \
        primary: companies_array[i][1][:status][:open], \
        secondary_top: companies_array[i][1][:status][:ready], \
        secondary_top_text: "Work Complete: ", \
        secondary_middle: companies_array[i][1][:status][:complete], \
        secondary_middle_text: "Ready to Inspect: ", \
        secondary_bottom: companies_array[i][1][:status][:closed], \
        secondary_bottom_text: "Closed: ", })
    end
  end

  #Orders companies based on open issues and dislpays the ones with the most in the widgets
  #IN: Companies hash, Array of text names for widgets
  def self.send_issue_counts (companies, widgets, total=nil)
    companies_array = companies.sort_by { |k, v| v[:status][:open] }.reverse!
    unless total == nil
      companies_array.unshift([0, total])
    end
    widgets.length.times do |i|
      send_event(widgets[i], {title: companies_array[i][1][:name], \
        primary: companies_array[i][1][:status][:open], \
        secondary_top: companies_array[i][1][:locations]["No Location"], \
        secondary_top_text: "No Location: ", \
        secondary_middle: companies_array[i][1][:lcoations]["2SA"], \
        secondary_middle_text: "2SA: ", \
        secondary_bottom: companies_array[i][1][:lcoations]["5SA"], \
        secondary_bottom_text: "5SA: ", })
    end
  end

  #Calculates the %Complete for companies and displays them in the leaderboard
  #IN: Companies hash, Text name of leaderboard widget
  def self.send_leaders (companies, leaderboard_widget)
    leaders = Hash.new({value: 0})
    companies.each do |k, v|
      if v[:status][:total] != 0
        value = (v[:status][:closed] * 100) / v[:status][:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
    send_event(leaderboard_widget, { items: leaders.values })
  end
end
