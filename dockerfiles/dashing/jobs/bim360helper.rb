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
      companies[c["company_id"]] = {name: c["name"], status: = {open: 0, complete: 0, ready: 0, closed: 0, total: 0}, locations: = floors}
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
  def self.company_status_count (companies, issues, total=nil)
    issues.each do |i|
      if i["status"] != nil && i["company_id"] != nil then
        case i["status"]
          when "Open"
            companies[i["company_id"]][:status][:open] += 1
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

  #Increments the company issue counts based on type of issues
  #IN: Companies Hash, JSON Stream of issues
  #OUT: Hash of company hashes sorted by company_id with counted issues
  def self.company_location_count (companies, issues, total=nil)
    issues.each do |i|
      if i["status"] != nil && i["company_id"] != nil then
        case i["status"]
          when "Open"
            companies[i["company_id"]][:open] += 1
            if total != nil then total[:open] += 1 end
          when "Work Completed"
            companies[i["company_id"]][:complete] += 1
            if total != nil then total[:complete] += 1 end
          when "Ready to Inspect"
            companies[i["company_id"]][:ready] += 1
            if total != nil then total[:ready] += 1 end
          when "Closed"
            companies[i["company_id"]][:closed] += 1
            if total != nil then total[:closed] += 1 end
        end
        companies[i["company_id"]][:total] += 1
        if total != nil then total[:total] += 1 end
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
      send_event(widgets[i], {title: companies_array[i][1][:name], open: companies_array[i][1][:status][:open], ready: companies_array[i][1][:status][:ready], complete: companies_array[i][1][:status][:complete], closed: companies_array[i][1][:status][:closed] })
    end
  end

  #Calculates the %Complete for companies and displays them in the leaderboard
  #IN: Companies hash, Text name of leaderboard widget
  def self.send_leaders (companies, leaderboard_widget)
    leaders = Hash.new({value: 0})
    companies.each do |k, v|
      if v[:status][:total] != 0
        value = (v[:closed] * 100) / v[:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
    send_event(leaderboard_widget, { items: leaders.values })
  end
end
