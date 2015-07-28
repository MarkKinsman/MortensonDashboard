require 'rest-client'
require 'json'
require_relative 'bim360helper'

#Widgets
count_widgets=[['all_total'],['all_company_0','all_company_1','all_company_2','all_company_3','all_company_4','all_company_5','all_company_6','all_company_7','all_company_8','all_company_9','all_company_10','all_company_11']]
debug = ['all_debug', ""]

#Local Variables
login = [0, 0, 0]
tickets = [0,0]
leaders = Hash.new({value: 0})
companies = {total: {:name => 0, :open => 0, :complete => 0, :ready => 0, :closed => 0, :total => 0},companies: Hash.new({name: 0, open: 0, complete: 0, ready: 0, closed: 0, total: 0})}

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10m', :first_in => 0, allow_overlapping: false do |job|

  send_event(debug[0], {text: debug[1] << "StartCycle -> "})
  login = read_login_info(debug)
  tickets = get_tickets(login, debug)
  companies = get_companies(tickets, debug)
  stream = get_issues(tickets, debug)
  companies = issues_company_type_sort(stream, debug)
  leaders = find_leaders(companies, "all_leaderboard", debug)
  send_issues(count_widgets, leaders, debug)
