require 'rest-client'
require 'json'
require_relative 'bim360helper'

tickets = {:login => 0, :project => 0}

#Widgets
count_widgets=['all_total', 'all_company_0','all_company_1','all_company_2','all_company_3','all_company_4','all_company_5','all_company_6','all_company_7','all_company_8','all_company_9','all_company_10','all_company_11']]
debug = ['all_debug', ""]

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10m', :first_in => 0, allow_overlapping: false do |job|

  send_event(debug[0], {text: debug[1] << "StartCycle -> "})

  begin
    tickets = Field.get_tickets()
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Get Tickets Error" + e.message + " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Get Tickets Done #{tickets.values} -> "}) end
  end

  begin
    companies = Field.get_companies(tickets)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Companies Download Error" + e.message + " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Companies Download Done #{companies.keys}-> "}) end
  end

  begin
    issues_stream = Field.get_issues(tickets)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Issues Download Error" + e.message + " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Issues Download Done -> "}) end
  end

  begin
    companies,total = Field.issues_company_type_count(companies, issues_stream)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Count Issues Error" + e.message + " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Count Issues Done #{companies.keys}-> " }) end
  end

  begin
    Field.send_issue_counts(companies, count_widgets)
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Display Error" + e.message + " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Display Done -> " }) end
  end

  begin
    Field.send_leaders(companies, "all_leaderboard")
  rescue Exception => e
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Find Leaders Error" + e.message +  " -> "}) end
  else
    unless debug.nil? then send_event(debug[0], {text: debug[1] << "Find Leaders Done -> " }) end
  end
end
