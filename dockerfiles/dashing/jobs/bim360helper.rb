module Field
  #Reads the file "Login" and gets the corresponding login and project tickets
  #OUT: login[login_ticket, project_ticket]
  def get_tickets ()
    login = [0, 0, 0]
    tickets = [0,0]
    File.open(File.expand_path("../login", __FILE__ ), "r") do |rf|
        login[0] = rf.readline.chomp
        login[1] = rf.readline.chomp
        login[2] = rf.readline.chomp
    end
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/login", :params => {:username => username, :password => password}))
    tickets[0] = stream["ticket"]
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/projects", :params => {:ticket => login_ticket}))
    stream.each do |p|
      if p["name"] == project
        tickets[1] = p["project_id"]
      end
    end
    return tickets
  end

  #Performs the REST call to the BIM 360 Field Database to recieve companies.
  #IN: Tickets from get_tickets
  #OUT: Hash of company hashes sorted by company_id,
  def get_companies (tickets)
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/companies/", :params => {:ticket => tickets[0], :project_id => tickets[1]}))
    stream.each do |c|
      companies[:companies][c["company_id"]] = {name: c["name"], open: 0, ready: 0, complete: 0, closed: 0, total: 0}
    end
    return companies
  end

  #Performs the REST call to the BIM 360 Field Database to recieve issues.
  #IN: Tickets from get_tickets
  #OUT: Stream of JSON
  def get_issues (tickets)
      stream = JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues/", timeout: nil, headers: {:params => {:ticket => tickets[0], :project_id => tickets[1]}}))
  end

  #Increments the company issue counts base don type of issues
  #IN: Companies Hash, JSON Stream of issues
  #OUT: Hash of company hashes sorted by company_id with counted issues
  def issues_company_type_sort (companies)
    stream.each do |i|
        case i["status"]
          when "Open"
            companies[i[:companies]["company_id"]][:open] += 1
            companies[:total][:open] += 1
          when "Work Completed"
            companies[i[:companies]["company_id"]][:complete] += 1
            companies[:total][:complete] += 1
          when "Ready to Inspect"
            companies[i[:companies]["company_id"]][:ready] += 1
            companies[:total][:ready] += 1
          when "Closed"
            companies[i[:companies]["company_id"]][:closed] += 1
            companies[:total][:closed] += 1
        end
        companies[i[:companies]["company_id"]][:total] += 1
        companies[:total][:total] += 1
    end
    return companies
  end

  #Orders companies based on open issues and dislpays the ones with the most in the widgets
  #IN: Companies hash, Array of text names for widgets
  def send_issue_counts (companies, widgets)
    companies_array = companies[:companies].sort_by { |k, v| v[:open] }.reverse!
    12.times do |i|
      send_event(widgets[1][i], {title: companies_array[i][1][:name], open: companies_array[i][1][:open], ready: companies_array[i][1][:ready], complete: companies_array[i][1][:complete], closed: companies_array[i][1][:closed] })
    end
    send_event(widgets[1][0], {title: "All Issues Total", open: companies[:total][:open], closed: companies[:total][:closed], ready: companies[:total][:ready], complete: companies[:total][:complete]})
  end

  #Calculates the %Complete for companies and displays them in the leaderboard
  #IN: Companies hash, Text name of leaderboard widget
  def send_leaders (companies, leaderboard_widget)
    companies[:companies].each do |k, v|
      if v[:total] != 0
        value = (v[:closed] * 100) / v[:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
    send_event(leaderboard_widget, { items: leaders.values })
  end

end
