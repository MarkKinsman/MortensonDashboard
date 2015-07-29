require 'rest-client'
require 'json'
require_relative 'bim360helper'

#Widgets
count_widgets=[['all_total'],['all_company_0','all_company_1','all_company_2','all_company_3','all_company_4','all_company_5','all_company_6','all_company_7','all_company_8','all_company_9','all_company_10','all_company_11']]
debug = ['all_debug', ""]

#Local Variables
tickets = [0,0]
leaders = Hash.new({value: 0})
companies = {total: {:name => 0, :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0}, companies: Hash.new({name: 0, open: 0, complete: 0, ready: 0, closed: 0, total: 0})}

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
    companies = issues_company_type_sort(issues_stream)
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
