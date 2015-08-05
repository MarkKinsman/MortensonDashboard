require 'rest-client'
require 'json'
require_relative 'bim360helper'

#Widgets
all_count_widgets=['all_total', 'all_company_0','all_company_1','all_company_2','all_company_3','all_company_4','all_company_5','all_company_6','all_company_7','all_company_8','all_company_9','all_company_10','all_company_11']
punch_count_widgets=['total', 'company_0','company_1','company_2','company_3','company_4','company_5','company_6','company_7','company_8','company_9','company_10','company_11']

debug = ['all_debug', ""]

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10m', :first_in => 0, allow_overlapping: false do |job|

  send_event(debug[0], {text: debug[1] << "StartCycle -> "})

  begin
    tickets = Field.get_tickets()
  rescue Exception => e
    send_event(debug[0], {text: debug[1] << "Get Tickets Error" + e.message + " -> "})
  else
    send_event(debug[0], {text: debug[1] << "Get Tickets Done -> "})
  end

  begin
    all_companies = Field.get_companies(tickets)
    punch_companies = Field.get_companies(tickets)
  rescue Exception => e
    send_event(debug[0], {text: debug[1] << "Companies Download Error" + e.message + " -> "})
  else
    send_event(debug[0], {text: debug[1] << "Companies Download Done -> "})
  end

  begin
    all_total = {:name => "Total Issues Count", :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0}
    punch_total = {:name => "Total Issues Count", :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0}

    send_event(debug[0], {text: debug[1] << " Declared Variable "})

    issues_count = Field.get_issues_count(tickets)
    iterator = 0
    send_event(debug[0], {text: debug[1] << issues_count.inspect})

    (issues_count/20).times do |i|
      stream = Field.get_issues(tickets, 20, i)
      punch_stream = stream.select{ |k| k.has_key?("issue_type") && k["issue_type"].include? "Punch List"}
      all_companies, all_total = Field.company_issue_count(all_companies, stream, all_total)
      punch_companies, punch_total = Field.company_issue_count(punch_companies, punch_stream, punch_total)
      send_event(debug[0], {text: debug[1] << (100*iterator)/(issues_count/20)})
    end
  rescue Exception => e
    send_event(debug[0], {text: debug[1] << "Count Issues Error" + e.message + " -> "})
  else
    send_event(debug[0], {text: debug[1] << "Count Issues Done ->" })
  end

  begin
    Field.send_issue_counts(all_companies, all_count_widgets, all_total)
    Field.send_issue_counts(punch_companies, punch_count_widgets, punch_total)
  rescue Exception => e
    send_event(debug[0], {text: debug[1] << "Display Error" + e.message + " -> "})
  else
    send_event(debug[0], {text: debug[1] << "Display Done -> " })
  end

  begin
    Field.send_leaders(all_companies, "all_leaderboard")
    Field.send_leaders(punch_companies, "leaderboard")
  rescue Exception => e
    send_event(debug[0], {text: debug[1] << "Find Leaders Error" + e.message +  " -> "})
  else
    send_event(debug[0], {text: debug[1] << "Find Leaders Done -> " })
  end
end
