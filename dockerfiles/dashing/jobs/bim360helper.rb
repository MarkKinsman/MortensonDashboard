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
  def self.get_companies (tickets)
    companies = Hash.new({name: 0, open: 0, complete: 0, ready: 0, closed: 0, total: 0})
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/companies/", :params => {:ticket => tickets[:login], :project_id => tickets[:project]}))
    stream.each do |c|
      companies[c["company_id"]] = {name: c["name"], open: 0, ready: 0, complete: 0, closed: 0, total: 0}
    end
    return companies
  end

  #Performs the REST call to the BIM 360 Field Database to recieve issues.
  #IN: Tickets from get_tickets
  #OUT: Stream of JSON
  def self.get_issues (tickets)
      return JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues/", timeout: nil, headers: {:params => {:ticket => tickets[:login], :project_id => tickets[:project]}}))
  end

  #Increments the company issue counts base don type of issues
  #IN: Companies Hash, JSON Stream of issues
  #OUT: Hash of company hashes sorted by company_id with counted issues
  def self.company_issue_count (companies, issues)
    total = {:name => 0, :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0}
    issues.each do |i|
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
    return companies, total
  end

  #Orders companies based on open issues and dislpays the ones with the most in the widgets
  #IN: Companies hash, Array of text names for widgets
  def self.send_issue_counts (companies, widgets, total=nil)
    send_event("all_debug", {text: companies.inspect })
    sleep(10)

    companies_array = companies.sort_by { |k, v| v[:open] }.reverse!

    send_event("all_debug", {text: companies_array.inspect })
    sleep(10)

    unless total == nil
      send_event("all_debug", {text: "Total not nil!: " + total.inspect })
      sleep(10)

      companies_array.unshift(total)
    end

    send_event("all_debug", {text: "Sending Widgets" })
    sleep(10)

    widgets.length.times do |i|
      send_event(widgets[i], {title: companies_array[i][1][:name], open: companies_array[i][1][:open], ready: companies_array[i][1][:ready], complete: companies_array[i][1][:complete], closed: companies_array[i][1][:closed] })
    end
  end

  #Calculates the %Complete for companies and displays them in the leaderboard
  #IN: Companies hash, Text name of leaderboard widget
  def self.send_leaders (companies, leaderboard_widget)
    leaders = Hash.new({value: 0})
    companies.each do |k, v|
      if v[:total] != 0
        value = (v[:closed] * 100) / v[:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
    send_event(leaderboard_widget, { items: leaders.values })
  end
end
