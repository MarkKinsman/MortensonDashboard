require 'rest-client'
require 'json'
#require_relative 'bim360helper'

#Methods
#module Field
  #Reads the file "Login" and gets the corresponding login and project tickets
  #OUT: login[login_ticket, project_ticket]
  def get_tickets ()
    login = {:username => 0 , :password => 0, :project => 0 }
    tickets = {:login => 0, :project => 0}
    File.open(File.expand_path("../login", __FILE__ ), "r") do |rf|
        login[:username] = rf.readline.chomp
        login[:password] = rf.readline.chomp
        login[:project] = rf.readline.chomp
    end

    send_event("all_debug", {text: login[:username] << " - " << login[:password] << " - " << login[:project]})

    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/login", :params => {:username => login[:username], :password => login[:password] }))
    tickets[:login] = stream["ticket"]
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/projects", :params => {:ticket => tickets[:project] }))
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
  def get_companies (tickets)
    companies = {total: {:name => 0, :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0}, companies: Hash.new({name: 0, open: 0, complete: 0, ready: 0, closed: 0, total: 0})}
    stream = JSON.parse(RestClient.get("http://bim360field.autodesk.com/api/companies/", :params => {:ticket => tickets[:login], :project_id => tickets[:project]}))
    stream.each do |c|
      companies[:companies][c["company_id"]] = {name: c["name"], open: 0, ready: 0, complete: 0, closed: 0, total: 0}
    end
    return companies
  end

  #Performs the REST call to the BIM 360 Field Database to recieve issues.
  #IN: Tickets from get_tickets
  #OUT: Stream of JSON
  def get_issues (tickets)
      return JSON.parse(RestClient::Request.execute(method: :get, url: "http://bim360field.autodesk.com/api/get_issues/", timeout: nil, headers: {:params => {:ticket => tickets[:login], :project_id => tickets[:project]}}))
  end

  #Increments the company issue counts base don type of issues
  #IN: Companies Hash, JSON Stream of issues
  #OUT: Hash of company hashes sorted by company_id with counted issues
  def issues_company_type_sort (companies, issues)
    issues.each do |i|
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
    leaders = Hash.new({value: 0})
    companies[:companies].each do |k, v|
      if v[:total] != 0
        value = (v[:closed] * 100) / v[:total]
        leaders[v[:name]] = {label: v[:name], value: value}
      end
    end
    send_event(leaderboard_widget, { items: leaders.values })
  end
#end

tickets = {:login => 0, :project => 0}

#Widgets
count_widgets=[['all_total'],['all_company_0','all_company_1','all_company_2','all_company_3','all_company_4','all_company_5','all_company_6','all_company_7','all_company_8','all_company_9','all_company_10','all_company_11']]
debug = ['all_debug', ""]

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10m', :first_in => 0, allow_overlapping: false do |job|

  send_event(debug[0], {text: debug[1] << "StartCycle -> "})

  begin
    tickets = get_tickets()
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Get Tickets Error" << e.message << " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Get Tickets Done -> "}) end
  end

  begin
    companies = get_companies(tickets)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Companies Download Error" << e.message << " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Companies Download Done -> "}) end
  end

  begin
    issues_stream = get_issues(tickets)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Issues Download Error" << e.message << " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Issues Download Done -> "}) end
  end

  begin
    companies = issues_company_type_sort(companies, issues_stream)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Count Issues Error" << e.message << " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Count Issues Done -> " }) end
  end

  begin
    send_issue_counts(companies, count_widgets)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Display Error" << e.message << " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Display Done -> " }) end
  end

  begin
    send_leaders(companies, "all_leaderboard")
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Find Leaders Error" << e.message <<  " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Find Leaders Done -> " }) end
  end
end
